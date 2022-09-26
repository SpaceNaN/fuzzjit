// Copyright 2020 Google LLC
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


/// Builtin program templates to target specific types of bugs.
public let ProgramTemplates = [
    ProgramTemplate("jit_p_001") { b in
        // This is mostly the template built by Javier Jimenez
        // https://bugs.chromium.org/p/chromium/issues/detail?id=1199345
//        function foo(a) {
//            var x = -0;
//            if (a) {
//                x = 0;
//            }
//            return x + (x - 0);
//        }

        b.generate(n: 5)
        var t_000,t_001:Variable
        t_000 = b.binary(b.randVar(), b.randVar(), with: chooseUniform(from: allBinaryOperators))
        let int_001: Variable = b.loadInt(b.genInt())
        let float_001: Variable = b.loadFloat(b.genFloat())
        t_001 = b.binary(b.randVar(), b.randVar(), with: chooseUniform(from: allBinaryOperators))
        b.beginIf(b.loadInt(0)) {
            if probability(0.5) {
                b.reassign(b.randVar(ofType: .integer) ?? int_001, to: chooseUniform(from: [b.loadInt(b.genInt()), b.randVar()]))
            } else {
                b.reassign(b.randVar(ofType: .float) ?? float_001, to: chooseUniform(from: [b.loadFloat(b.genFloat()), b.randVar()]))
            }
            if probability(0.2){
                b.unary(chooseUniform(from: allUnaryOperators), b.randVar())
                if probability(0.4) {
                    b.binary(b.randVar(), b.randVar(), with: chooseUniform(from: allBinaryOperators))
                }
                if probability(0.6) {
                    b.unary(chooseUniform(from: allUnaryOperators), b.randVar())
                }
                if probability(0.4) {
                    b.compare(b.randVar(), b.randVar(), with: chooseUniform(from: allComparators))
                }
            }
        }
        b.endIf()
        b.binary(b.randVar(), b.randVar(), with: chooseUniform(from: allBinaryOperators))
        if probability(0.4) {
            b.binary(b.randVar(), b.randVar(), with: chooseUniform(from: allBinaryOperators))
        }
        if probability(0.6) {
            b.unary(chooseUniform(from: allUnaryOperators), b.randVar())
        }
        if probability(0.4) {
            b.compare(b.randVar(), b.randVar(), with: chooseUniform(from: allComparators))
        }

        let object = b.loadBuiltin("Math")
        b.compare(b.loadInt(0),b.callMethod(chooseUniform(from: ["max","min"]), on: object, withArgs: [b.loadInt(-1),b.randVar(ofType: .unknown) ?? b.randVar(),b.loadInt(0)]),with: chooseUniform(from: allComparators))
//        b.doReturn(value: b.randVar(ofType: .unknown) ?? b.randVar())
    },

//    ProgramTemplate("JIT1Function") { b in
//        let genSize = 3
//
//        // Generate random function signatures as our helpers
//        var functionSignatures = ProgramTemplate.generateRandomFunctionSignatures(forFuzzer: b.fuzzer, n: 2)
//
//        // Generate random property types
//        ProgramTemplate.generateRandomPropertyTypes(forBuilder: b)
//
//        // Generate random method types
//        ProgramTemplate.generateRandomMethodTypes(forBuilder: b, n: 2)
//
//        b.generate(n: genSize)
//
//        // Generate some small functions
//        for signature in functionSignatures {
//            // Here generate a random function type, e.g. arrow/generator etc
//            b.definePlainFunction(withSignature: signature) { args in
//                b.generate(n: genSize)
//            }
//        }
//
//        // Generate a larger function
//        let signature = ProgramTemplate.generateSignature(forFuzzer: b.fuzzer, n: 4)
//        let f = b.definePlainFunction(withSignature: signature) { args in
//            // Generate (larger) function body
//            b.generate(n: 30)
//        }
//
//        // Generate some random instructions now
//        b.generate(n: genSize)
//
//        // trigger JIT
//        b.forLoop(b.loadInt(0), .lessThan, b.loadInt(100), .Add, b.loadInt(1)) { args in
//            b.callFunction(f, withArgs: b.generateCallArguments(for: signature))
//        }
//
//        // more random instructions
//        b.generate(n: genSize)
//        b.callFunction(f, withArgs: b.generateCallArguments(for: signature))
//
//        // maybe trigger recompilation
//        b.forLoop(b.loadInt(0), .lessThan, b.loadInt(100), .Add, b.loadInt(1)) { args in
//            b.callFunction(f, withArgs: b.generateCallArguments(for: signature))
//        }
//
//        // more random instructions
//        b.generate(n: genSize)
//
//        b.callFunction(f, withArgs: b.generateCallArguments(for: signature))
//    },
//
//    ProgramTemplate("JIT2Functions") { b in
//        let genSize = 3
//
//        // Generate random function signatures as our helpers
//        var functionSignatures = ProgramTemplate.generateRandomFunctionSignatures(forFuzzer: b.fuzzer, n: 2)
//
//        // Generate random property types
//        ProgramTemplate.generateRandomPropertyTypes(forBuilder: b)
//
//        // Generate random method types
//        ProgramTemplate.generateRandomMethodTypes(forBuilder: b, n: 2)
//
//        b.generate(n: genSize)
//
//        // Generate some small functions
//        for signature in functionSignatures {
//            // Here generate a random function type, e.g. arrow/generator etc
//            b.definePlainFunction(withSignature: signature) { args in
//                b.generate(n: genSize)
//            }
//        }
//
//        // Generate a larger function
//        let signature1 = ProgramTemplate.generateSignature(forFuzzer: b.fuzzer, n: 4)
//        let f1 = b.definePlainFunction(withSignature: signature1) { args in
//            // Generate (larger) function body
//            b.generate(n: 15)
//        }
//
//        // Generate a second larger function
//        let signature2 = ProgramTemplate.generateSignature(forFuzzer: b.fuzzer, n: 4)
//        let f2 = b.definePlainFunction(withSignature: signature2) { args in
//            // Generate (larger) function body
//            b.generate(n: 15)
//        }
//
//        // Generate some random instructions now
//        b.generate(n: genSize)
//
//        // trigger JIT for first function
//        b.forLoop(b.loadInt(0), .lessThan, b.loadInt(100), .Add, b.loadInt(1)) { args in
//            b.callFunction(f1, withArgs: b.generateCallArguments(for: signature1))
//        }
//
//        // trigger JIT for second function
//        b.forLoop(b.loadInt(0), .lessThan, b.loadInt(100), .Add, b.loadInt(1)) { args in
//            b.callFunction(f2, withArgs: b.generateCallArguments(for: signature2))
//        }
//
//        // more random instructions
//        b.generate(n: genSize)
//
//        b.callFunction(f2, withArgs: b.generateCallArguments(for: signature2))
//        b.callFunction(f1, withArgs: b.generateCallArguments(for: signature1))
//
//        // maybe trigger recompilation
//        b.forLoop(b.loadInt(0), .lessThan, b.loadInt(100), .Add, b.loadInt(1)) { args in
//            b.callFunction(f1, withArgs: b.generateCallArguments(for: signature1))
//        }
//
//        // maybe trigger recompilation
//        b.forLoop(b.loadInt(0), .lessThan, b.loadInt(100), .Add, b.loadInt(1)) { args in
//            b.callFunction(f2, withArgs: b.generateCallArguments(for: signature2))
//        }
//
//        // more random instructions
//        b.generate(n: genSize)
//
//        b.callFunction(f1, withArgs: b.generateCallArguments(for: signature1))
//        b.callFunction(f2, withArgs: b.generateCallArguments(for: signature2))
//    },
//
//    ProgramTemplate("TypeConfusionTemplate") { b in
//        // This is mostly the template built by Javier Jimenez
//        // (https://sensepost.com/blog/2020/the-hunt-for-chromium-issue-1072171/).
//        let signature = ProgramTemplate.generateSignature(forFuzzer: b.fuzzer, n: Int.random(in: 2...5))
//
//        let f = b.definePlainFunction(withSignature: signature) { _ in
//            b.generate(n: 5)
//            let array = b.generateVariable(ofType: .object(ofGroup: "Array"))
//
//            let index = b.genIndex()
//            b.loadElement(index, of: array)
//            b.doReturn(value: b.randVar())
//        }
//
//        // TODO: check if these are actually different, or if
//        // generateCallArguments generates the argument once and the others
//        // just use them.
//        let initialArgs = b.generateCallArguments(for: signature)
//        let optimizationArgs = b.generateCallArguments(for: signature)
//        let triggeredArgs = b.generateCallArguments(for: signature)
//
//        b.callFunction(f, withArgs: initialArgs)
//
//        b.forLoop(b.loadInt(0), .lessThan, b.loadInt(100), .Add, b.loadInt(1)) { _ in
//            b.callFunction(f, withArgs: optimizationArgs)
//        }
//
//        b.callFunction(f, withArgs: triggeredArgs)
//    },
]
