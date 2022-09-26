// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import JS

/// Supported versions of the ECMA standard.
public enum ECMAScriptVersion {
    case es5
    case es6
}


/// Lifts a FuzzIL program to JavaScript.
public class JavaScriptLifter: Lifter {
    /// Prefix and suffix to surround the emitted code in
    private let prefix: String
    private let suffix: String

    /// The inlining policy to follow. This influences the look of the emitted code.
    let policy: InliningPolicy

    /// The inlining policy used for code emmited for type collection.
    /// It should inline as little expressions as possible to capture as many variable types as possible.
    /// But simple literal types can infer AbstractInterpreter as well.
    let typeCollectionPolicy = InlineOnlyLiterals()

    /// The version of the ECMAScript standard that this lifter generates code for.
    let version: ECMAScriptVersion

    /// Counter to assist the lifter in detecting nested CodeStrings
    private var codeStringNestingLevel = 0

    public init(prefix: String = "",
                suffix: String = "",
                inliningPolicy: InliningPolicy,
                ecmaVersion: ECMAScriptVersion) {
        self.prefix = prefix
        self.suffix = suffix
        self.policy = inliningPolicy
        self.version = ecmaVersion
    }

    public func lift(_ program: Program, withOptions options: LiftingOptions) -> String {
        if options.contains(.collectTypes) {
            return lift(program, withOptions: options, withPolicy: self.typeCollectionPolicy)
        } else {
            return lift(program, withOptions: options, withPolicy: self.policy)
        }
    }

    private func lift(_ program: Program, withOptions options: LiftingOptions, withPolicy policy: InliningPolicy) -> String {
        var w = ScriptWriter(minifyOutput: options.contains(.minify))

        if options.contains(.includeComments), let header = program.comments.at(.header) {
            w.emitComment(header)
        }

        var typeUpdates: [[(Variable, Type)]] = []
        if options.contains(.dumpTypes) {
            typeUpdates = program.types.indexedByInstruction(for: program)
        }

        // Keeps track of which variables have been inlined
        var inlinedVars = VariableSet()

        // Analyze the program to determine the uses of a variable
        let analyzer = VariableAnalyzer(for: program)

        let typeCollectionAnalyzer = TypeCollectionAnalyzer()

        // Associates variables with the expressions that produce them
        var expressions = VariableMap<Expression>()
        func expr(for v: Variable) -> Expression {
            return expressions[v] ?? Identifier.new(v.identifier)
        }

        if options.contains(.collectTypes) {
            // Wrap type collection to its own main function to avoid using global variables
            w.emit("function typeCollectionMain() {")
            w.increaseIndentionLevel()
            w.emitBlock(helpersScript)
            w.emitBlock(initTypeCollectionScript)
        }

        w.emitBlock(prefix)
        var returnArr = [(Int,Int)]()
        var returnFlag = true
        let varDecl = version == .es6 ? "let" : "var"
        let constDecl = version == .es6 ? "const" : "var"
        func decl(_ v: Variable) -> String {
            if returnFlag && (w.getCurrentIndention() == 0){
                returnArr.append((Int,Int)(v.number,w.getCurrentIndention()))
            }
            returnFlag = true
            if analyzer.numAssignments(of: v) == 1 {
                return "\(constDecl) \(v)"
            } else {
                return "\(varDecl) \(v)"
            }
        }

        // Need to track class definitions to propertly lift class method definitions.
        var classDefinitions = ClassDefinitionStack()

        for instr in program.code {
            // Convenience access to inputs
            func input(_ idx: Int) -> Expression {
                return expr(for: instr.input(idx))
            }

            // Helper functions to lift a function definition
            func liftFunctionDefinitionParameters(_ op: BeginAnyFunctionDefinition) -> String {
                assert(instr.op === op)
                var identifiers = instr.innerOutputs.map({ $0.identifier })
                if op.hasRestParam, let last = instr.innerOutputs.last {
                    identifiers[identifiers.endIndex - 1] = "..." + last.identifier
                }
                return identifiers.joined(separator: ",")
            }
            // TODO remove copy+paste
            func liftMethodDefinitionParameters(_ signature: FunctionSignature) -> String {
                var identifiers = instr.innerOutputs(1...).map({ $0.identifier })
                if signature.hasVarargsParameter(), let last = instr.innerOutputs.last {
                    identifiers[identifiers.endIndex - 1] = "..." + last.identifier
                }
                return identifiers.joined(separator: ",")
            }
            func liftFunctionDefinitionBegin(_ op: BeginAnyFunctionDefinition, _ keyword: String) {
                assert(instr.op === op)
                let params = liftFunctionDefinitionParameters(op)
                w.emit("\(keyword) \(instr.output)(\(params)) {")
                w.increaseIndentionLevel()
            }

            if options.contains(.includeComments), let comment = program.comments.at(.instruction(instr.index)) {
                w.emitComment(comment)
            }

            var output: Expression? = nil

            switch instr.op {
            case let op as LoadInteger:
                returnFlag = false;
                output = NumberLiteral.new(String(op.value))

            case let op as LoadBigInt:
                returnFlag = false;
                output = NumberLiteral.new(String(op.value) + "n")

            case let op as LoadFloat:
                returnFlag = false;
                if op.value.isNaN {
                    output = Identifier.new("NaN")
                } else if op.value.isEqual(to: -Double.infinity) {
                    output = UnaryExpression.new("-Infinity")
                } else if op.value.isEqual(to: Double.infinity) {
                    output = Identifier.new("Infinity")
                } else {
                    output = NumberLiteral.new(String(op.value))
                }

            case let op as LoadString:
                returnFlag = false;
                output = Literal.new() <> "\"" <> op.value <> "\""

            case let op as LoadRegExp:
                returnFlag = false;
                let flags = op.flags.asString()
                output = Literal.new() <> "/" <> op.value <> "/" <> flags

            case let op as LoadBoolean:
                returnFlag = false;
                output = Literal.new(op.value ? "true" : "false")

            case is LoadUndefined:
                returnFlag = false;
                output = Identifier.new("undefined")

            case is LoadNull:
                returnFlag = false;
                output = Literal.new("null")

            case let op as CreateObject:
                returnFlag = false;
                var properties = [String]()
                for (index, propertyName) in op.propertyNames.enumerated() {
                    properties.append(propertyName + ":" + input(index))
                }
                output = ObjectLiteral.new("{" + properties.joined(separator: ",") + "}")

            case is CreateArray:
                // When creating arrays, treat undefined elements as holes. This also relies on literals always being inlined.
                returnFlag = false;
                let elems = instr.inputs.map({ let text = expr(for: $0).text; return text == "undefined" ? "" : text }).joined(separator: ",")
                output = ArrayLiteral.new("[" + elems + "]")

            case let op as CreateObjectWithSpread:
                returnFlag = true;
                var properties = [String]()
                for (index, propertyName) in op.propertyNames.enumerated() {
                    properties.append(propertyName + ":" + input(index))
                }
                // Remaining ones are spread.
                for v in instr.inputs.dropFirst(properties.count) {
                    properties.append("..." + expr(for: v).text)
                }
                output = ObjectLiteral.new("{" + properties.joined(separator: ",") + "}")

            case let op as CreateArrayWithSpread:
                returnFlag = true;
                var elems = [String]()
                for (i, v) in instr.inputs.enumerated() {
                    if op.spreads[i] {
                        elems.append("..." + expr(for: v).text)
                    } else {
                        elems.append(expr(for: v).text)
                    }
                }
                output = ArrayLiteral.new("[" + elems.joined(separator: ",") + "]")

            case let op as LoadBuiltin:
                returnFlag = false;
                output = Identifier.new(op.builtinName)

            case let op as LoadProperty:
                returnFlag = true;
                output = MemberExpression.new() <> input(0) <> "." <> op.propertyName

            case let op as StoreProperty:
                returnFlag = true;
                returnArr.append((instr.input(0).number,w.getCurrentIndention()))
                let dest = MemberExpression.new() <> input(0) <> "." <> op.propertyName
                let expr = AssignmentExpression.new() <> dest <> " = " <> input(1)
                w.emit(expr)

            case let op as DeleteProperty:
                returnFlag = true;
                returnArr.append((instr.input(0).number,w.getCurrentIndention()))
                let target = MemberExpression.new() <> input(0) <> "." <> op.propertyName
                let expr = UnaryExpression.new() <> "delete " <> target
                w.emit(expr)

            case let op as LoadElement:
                returnFlag = true;
                output = MemberExpression.new() <> input(0) <> "[" <> op.index <> "]"

            case let op as StoreElement:
                returnFlag = true;
                returnArr.append((instr.input(0).number,w.getCurrentIndention()))
                let dest = MemberExpression.new() <> input(0) <> "[" <> op.index <> "]"
                let expr = AssignmentExpression.new() <> dest <> " = " <> input(1)
                w.emit(expr)

            case let op as DeleteElement:
                returnFlag = true;
                returnArr.append((instr.input(0).number,w.getCurrentIndention()))
                let target = MemberExpression.new() <> input(0) <> "[" <> op.index <> "]"
                let expr = UnaryExpression.new() <> "delete " <> target
                w.emit(expr)

            case is LoadComputedProperty:
                returnFlag = true;
                output = MemberExpression.new() <> input(0) <> "[" <> input(1).text <> "]"

            case is StoreComputedProperty:
                returnFlag = true;
                returnArr.append((instr.input(0).number,w.getCurrentIndention()))
                let dest = MemberExpression.new() <> input(0) <> "[" <> input(1).text <> "]"
                let expr = AssignmentExpression.new() <> dest <> " = " <> input(2)
                w.emit(expr)

            case is DeleteComputedProperty:
                returnFlag = true;
                returnArr.append((instr.input(0).number,w.getCurrentIndention()))
                let target = MemberExpression.new() <> input(0) <> "[" <> input(1).text <> "]"
                let expr = UnaryExpression.new() <> "delete " <> target
                w.emit(expr)

            case is TypeOf:
                returnFlag = false;
                output = UnaryExpression.new() <> "typeof " <> input(0)

            case is InstanceOf:
                returnFlag = true;
                output = BinaryExpression.new() <> input(0) <> " instanceof " <> input(1)

            case is In:
                returnFlag = true;
                output = BinaryExpression.new() <> input(0) <> " in " <> input(1)

            case let op as BeginPlainFunctionDefinition:
                returnFlag = false;
                liftFunctionDefinitionBegin(op, "function")

            case let op as BeginStrictFunctionDefinition:
                returnFlag = false;
                liftFunctionDefinitionBegin(op, "function")
                w.emit("'use strict';")

            case let op as BeginArrowFunctionDefinition:
                returnFlag = false;
                let params = liftFunctionDefinitionParameters(op)
                w.emit("\(decl(instr.output)) = (\(params)) => {")
                w.increaseIndentionLevel()

            case let op as BeginGeneratorFunctionDefinition:
                returnFlag = false;
                liftFunctionDefinitionBegin(op, "function*")

            case let op as BeginAsyncFunctionDefinition:
                returnFlag = false;
                liftFunctionDefinitionBegin(op, "async function")

            case let op as BeginAsyncArrowFunctionDefinition:
                returnFlag = false;
                let params = liftFunctionDefinitionParameters(op)
                w.emit("\(decl(instr.output)) = async (\(params)) => {")
                w.increaseIndentionLevel()

            case let op as BeginAsyncGeneratorFunctionDefinition:
                returnFlag = false;
                liftFunctionDefinitionBegin(op, "async function*")

            case is EndArrowFunctionDefinition, is EndAsyncArrowFunctionDefinition:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("};")

            case is EndAnyFunctionDefinition:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("}")

            case is Return:
                returnFlag = false;
                w.emit("return \(input(0));")

            case is Yield:
                returnFlag = false;
                w.emit("yield \(input(0));")

            case is YieldEach:
                returnFlag = false;
                w.emit("yield* \(input(0));")

            case is Await:
                returnFlag = false;
                output = UnaryExpression.new() <> "await " <> input(0)

            case is ConditionalOperation:
                output = TernaryExpression.new() <> input(0) <> " ? " <> input(1) <> " : " <> input(2)

            case is CallFunction:
                returnFlag = true;
                let arguments = instr.inputs.dropFirst().map({ expr(for: $0).text })
                output = CallExpression.new() <> input(0) <> "(" <> arguments.joined(separator: ",") <> ")"

            case let op as CallMethod:
                returnFlag = true;
                let arguments = instr.inputs.dropFirst().map({ expr(for: $0).text })
                let method = MemberExpression.new() <> input(0) <> "." <> op.methodName
                output = CallExpression.new() <> method <> "(" <> arguments.joined(separator: ",") <> ")"

            case is CallComputedMethod:
                returnFlag = true;
                let arguments = instr.inputs.dropFirst(2).map({ expr(for: $0).text })
                let method = MemberExpression.new() <> input(0) <> "[" <> input(1) <> "]"
                output = CallExpression.new() <> method <> "(" <> arguments.joined(separator: ",") <> ")"

            case is Construct:
                returnFlag = false;
                let arguments = instr.inputs.dropFirst().map({ expr(for: $0).text })
                output = NewExpression.new() <> "new " <> input(0) <> "(" <> arguments.joined(separator: ",") <> ")"

            case let op as CallFunctionWithSpread:
                returnFlag = true;
                var arguments = [String]()
                for (i, v) in instr.inputs.dropFirst().enumerated() {
                    if op.spreads[i] {
                        arguments.append("..." + expr(for: v).text)
                    } else {
                        arguments.append(expr(for: v).text)
                    }
                }
                output = CallExpression.new() <> input(0) <> "(" <> arguments.joined(separator: ",") <> ")"

            case let op as UnaryOperation:
                returnFlag = true;
                if op.op.isPostfix {
                    output = UnaryExpression.new() <> input(0) <> op.op.token
                } else {
                    output = UnaryExpression.new() <> op.op.token <> input(0)
                }

            case let op as BinaryOperation:
                returnFlag = true;
                output = BinaryExpression.new() <> input(0) <> " " <> op.op.token <> " " <> input(1)

            case is Dup:
                returnFlag = true;
                w.emit("\(decl(instr.output)) = \(input(0));")

            case is Reassign:
                returnFlag = true;
//                reassign based on assigned var
                returnArr.append((instr.input(0).number,w.getCurrentIndention()))
                w.emit("\(instr.input(0)) = \(input(1));")

            case let op as Compare:
                returnFlag = true;
                output = BinaryExpression.new() <> input(0) <> " " <> op.op.token <> " " <> input(1)

            case let op as Eval:
                returnFlag = false;
                // Woraround until Strings implement the CVarArg protocol in the linux Foundation library...
                // TODO can make this permanent, but then use different placeholder pattern
                var string = op.code
                for v in instr.inputs {
                    let range = string.range(of: "%@")!
                    string.replaceSubrange(range, with: expr(for: v).text)
                }
                w.emit(string + ";")

            case is BeginWith:
                returnFlag = false;
                w.emit("with (\(input(0))) {")
                w.increaseIndentionLevel()

            case is EndWith:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("}")

            case let op as LoadFromScope:
                returnFlag = true;
                output = Identifier.new(op.id)

            case let op as StoreToScope:
                returnFlag = true;
                w.emit("\(op.id) = \(input(0));")

            case is Nop:
                returnFlag = false;
                break

            case let op as BeginClassDefinition:
                returnFlag = false;
                var declaration = "\(decl(instr.output)) = class \(instr.output.identifier.uppercased())"
                if op.hasSuperclass {
                    declaration += " extends \(input(0))"
                }
                declaration += " {"
                w.emit(declaration)
                w.increaseIndentionLevel()

                classDefinitions.push(ClassDefinition(from: op))

                // The following code is the body of the constructor, so emit the declaration
                // First inner output is implicit |this| parameter
                expressions[instr.innerOutput(0)] = Identifier.new("this")
                let params = liftMethodDefinitionParameters(classDefinitions.current.constructorSignature)
                w.emit("constructor(\(params)) {")
                w.increaseIndentionLevel()

            case is BeginMethodDefinition:
                returnFlag = false;
                // End the previous body (constructor or method)
                w.decreaseIndentionLevel()
                w.emit("}")

                // First inner output is implicit |this| parameter
                expressions[instr.innerOutput(0)] = Identifier.new("this")
                let method = classDefinitions.current.nextMethod()
                let params = liftMethodDefinitionParameters(method.signature)
                w.emit("\(method.name)(\(params)) {")
                w.increaseIndentionLevel()

            case is EndClassDefinition:
                returnFlag = false;
                // End the previous body (constructor or method)
                w.decreaseIndentionLevel()
                w.emit("}")

                classDefinitions.pop()

                // End the class definition
                w.decreaseIndentionLevel()
                w.emit("};")

            case is CallSuperConstructor:
                returnFlag = false;
                let arguments = instr.inputs.map({ expr(for: $0).text })
                w.emit(CallExpression.new() <> "super(" <> arguments.joined(separator: ",") <> ")")

            case let op as CallSuperMethod:
                returnFlag = true;
                let arguments = instr.inputs.map({ expr(for: $0).text })
                output = CallExpression.new() <> "super.\(op.methodName)(" <> arguments.joined(separator: ",") <> ")"

            case let op as LoadSuperProperty:
                returnFlag = true;
                output = MemberExpression.new() <> "super.\(op.propertyName)"

            case let op as StoreSuperProperty:
                returnFlag = true;
                let expr = AssignmentExpression.new() <> "super.\(op.propertyName) = " <> input(0)
                w.emit(expr)

            case is BeginIf:
                returnFlag = false;
                w.emit("if (opt_param) {")
                w.increaseIndentionLevel()

            case is BeginElse:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("} else {")
                w.increaseIndentionLevel()

            case is EndIf:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("}")

            case let op as BeginWhile:
                returnFlag = false;
                let cond = BinaryExpression.new() <> input(0) <> " " <> op.comparator.token <> " " <> input(1)
                w.emit("while (\(cond)) {")
                w.increaseIndentionLevel()

            case is EndWhile:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("}")

            case is BeginDoWhile:
                returnFlag = false;
                w.emit("do {")
                w.increaseIndentionLevel()

            case is EndDoWhile:
                returnFlag = false;
                w.decreaseIndentionLevel()
                let begin = Block(endedBy: instr, in: program.code).begin
                let comparator = (begin.op as! BeginDoWhile).comparator
                let cond = BinaryExpression.new() <> expr(for: begin.input(0)) <> " " <> comparator.token <> " " <> expr(for: begin.input(1))
                w.emit("} while (\(cond));")

            case let op as BeginFor:
                returnFlag = false;
                let loopVar = Identifier.new(instr.innerOutput.identifier)
                let cond = BinaryExpression.new() <> loopVar <> " " <> op.comparator.token <> " " <> input(1)
                var expr: Expression
                // This is a bit of a hack. Instead, maybe we should have a way of simplifying expressions through some pattern matching code?
                if input(2).text == "1" && op.op == .Add {
                    expr = PostfixExpression.new() <> loopVar <> "++"
                } else if input(2).text == "1" && op.op == .Sub {
                    expr = PostfixExpression.new() <> loopVar <> "--"
                } else {
                    let newValue = BinaryExpression.new() <> loopVar <> " " <> op.op.token <> " " <> input(2)
                    expr = AssignmentExpression.new() <> loopVar <> " = " <> newValue
                }
                w.emit("for (\(varDecl) \(loopVar) = \(input(0)); \(cond); \(expr)) {")
                w.increaseIndentionLevel()

            case is EndFor:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("}")

            case is BeginForIn:
                returnFlag = false;
                w.emit("for (\(decl(instr.innerOutput)) in \(input(0))) {")
                w.increaseIndentionLevel()

            case is EndForIn:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("}")

            case is BeginForOf:
                returnFlag = false;
                w.emit("for (\(decl(instr.innerOutput)) of \(input(0))) {")
                w.increaseIndentionLevel()

            case is EndForOf:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("}")

            case is Break:
                returnFlag = false;
                w.emit("break;")

            case is Continue:
                returnFlag = false;
                w.emit("continue;")

            case is BeginTry:
                returnFlag = false;
                w.emit("try {")
                w.increaseIndentionLevel()

            case is BeginCatch:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("} catch(\(instr.innerOutput)) {")
                w.increaseIndentionLevel()

            case is BeginFinally:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("} finally {")
                w.increaseIndentionLevel()

            case is EndTryCatch:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("}")

            case is ThrowException:
                returnFlag = false;
                w.emit("throw \(input(0));")

            case is BeginCodeString:
                returnFlag = false;
                // This power series (2**n -1) is used to generate a valid escape sequence for nested template literals.
                // Here n represents the nesting level.
                let count = Int(pow(2, Double(codeStringNestingLevel)))-1
                let escapeSequence = String(repeating: "\\", count: count)
                w.emit("\(decl(instr.output)) = \(escapeSequence)`")
                w.increaseIndentionLevel()
                codeStringNestingLevel += 1

            case is EndCodeString:
                returnFlag = false;
                w.emit("\(input(0));")
                codeStringNestingLevel -= 1
                w.decreaseIndentionLevel()
                let count = Int(pow(2, Double(codeStringNestingLevel)))-1
                let escapeSequence = String(repeating: "\\", count: count)
                w.emit("\(escapeSequence)`;")

            case is BeginBlockStatement:
                returnFlag = false;
                w.emit("{")
                w.increaseIndentionLevel()

            case is EndBlockStatement:
                returnFlag = false;
                w.decreaseIndentionLevel()
                w.emit("}")

            case is Print:
                returnFlag = false;
                w.emit("fuzzilli('FUZZILLI_PRINT', \(input(0)));")

            default:
                fatalError("Unhandled Operation: \(type(of: instr.op))")
            }

            if let expression = output {
                let v = instr.output
                if policy.shouldInline(expression) && analyzer.numAssignments(of: v) == 1 && expression.canInline(instr, analyzer.usesIndices(of: v)) {
                    expressions[v] = expression
                    inlinedVars.insert(v)
                } else {
                    w.emit("\(decl(v)) = \(expression);")
                }
            }

            if options.contains(.dumpTypes) {
                for (v, t) in typeUpdates[instr.index] where !inlinedVars.contains(v) {
                    w.emitComment("\(v) = \(t.abbreviated)")
                }
            }

            if options.contains(.collectTypes) {
                // Update type of every variable returned by analyzer
                for v in typeCollectionAnalyzer.analyze(instr) where !inlinedVars.contains(v) {
                    w.emit("updateType(\(v.number), \(instr.index), \(expr(for: v)));")
                }
            }
        }

        if returnArr.count != 0 && (w.getCurrentIndention() == 0) {
            // for item in returnArr{
            //    w.emitComment(" v\(item.0) : \(item.1)")
            // }
            w.emit("return v\(returnArr[returnArr.count-1].0);")
        }
        w.emitBlock(suffix)

        if options.contains(.collectTypes) {
            w.emitBlock(printTypesScript)
            w.decreaseIndentionLevel()
            w.emit("}")
            w.emit("typeCollectionMain()")
        }

        if options.contains(.includeComments), let footer = program.comments.at(.footer) {
            w.emitComment(footer)
        }

        return w.code
    }
}
