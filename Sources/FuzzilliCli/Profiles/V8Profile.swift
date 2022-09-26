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

import Fuzzilli

fileprivate let ForceV8TurbofanGenerator = CodeGenerator("ForceV8TurbofanGenerator", input: .function()) { b, f in
    guard let arguments = b.randCallArguments(for: f) else { return }
    
    let start = b.loadInt(0)
    let end = b.loadInt(100)
    let step = b.loadInt(1)
    b.forLoop(start, .lessThan, end, .Add, step) { _ in
        b.callFunction(f, withArgs: arguments)
    }
}

fileprivate let MapTransitionsTemplate = ProgramTemplate("MapTransitionsTemplate", requiresPrefix: false) { b in
    // This template is meant to stress the v8 Map transition mechanisms.
    // Basically, it generates a bunch of CreateObject, LoadProperty, StoreProperty, FunctionDefinition,
    // and CallFunction operations operating on a small set of objects and property names.

    let propertyNames = ["a", "b", "c", "d", "e", "f", "g"]
    assert(Set(propertyNames).isDisjoint(with: b.fuzzer.environment.customMethodNames))

    // Use this as base object type. For one, this ensures that the initial map is stable.
    // Moreover, this guarantees that when querying for this type, we will receive one of
    // the objects we created and not e.g. a function (which is also an object).
    let objType = Type.object(withProperties: ["a"])

    // Signature of functions generated in this template
    let sig = [objType, objType] => objType

    // Create property values: integers, doubles, and heap objects.
    // These should correspond to the supported property representations of the engine.
    let intVal = b.loadInt(42)
    let floatVal = b.loadFloat(13.37)
    let objVal = b.createObject(with: [:])
    let propertyValues = [intVal, floatVal, objVal]

    // Now create a bunch of objects to operate on.
    // Keep track of all objects created in this template so that they can be verified at the end.
    var objects = [objVal]
    for _ in 0..<5 {
        objects.append(b.createObject(with: ["a": intVal]))
    }

    // Next, temporarily overwrite the active code generators with the following generators...
    let createObjectGenerator = CodeGenerator("CreateObject") { b in
        let obj = b.createObject(with: ["a": intVal])
        objects.append(obj)
    }
    let propertyLoadGenerator = CodeGenerator("PropertyLoad", input: objType) { b, obj in
        assert(objects.contains(obj))
        b.loadProperty(chooseUniform(from: propertyNames), of: obj)
    }
    let propertyStoreGenerator = CodeGenerator("PropertyStore", input: objType) { b, obj in
        assert(objects.contains(obj))
        let numProperties = Int.random(in: 1...4)
        for _ in 0..<numProperties {
            b.storeProperty(chooseUniform(from: propertyValues), as: chooseUniform(from: propertyNames), on: obj)
        }
    }
    let functionDefinitionGenerator = CodeGenerator("FunctionDefinition") { b in
        let prevSize = objects.count
        b.definePlainFunction(withSignature: sig) { params in
            objects += params
            b.generateRecursive()
            b.doReturn(value: b.randVar(ofType: objType)!)
        }
        objects.removeLast(objects.count - prevSize)
    }
    let functionCallGenerator = CodeGenerator("FunctionCall", input: .function()) { b, f in
        let args = b.randCallArguments(for: sig)!
        assert(objects.contains(args[0]) && objects.contains(args[1]))
        let rval = b.callFunction(f, withArgs: args)
        assert(b.type(of: rval).Is(objType))
        objects.append(rval)
    }
    let functionJitCallGenerator = CodeGenerator("FunctionJitCall", input: .function()) { b, f in
        let args = b.randCallArguments(for: sig)!
        assert(objects.contains(args[0]) && objects.contains(args[1]))
        b.forLoop(b.loadInt(0), .lessThan, b.loadInt(100), .Add, b.loadInt(1)) { _ in
            b.callFunction(f, withArgs: args)       // Rval goes out-of-scope immediately, so no need to track it
        }
    }

    let prevCodeGenerators = b.fuzzer.codeGenerators
    b.fuzzer.codeGenerators = WeightedList<CodeGenerator>([
        (createObjectGenerator,       1),
        (propertyLoadGenerator,       2),
        (propertyStoreGenerator,      5),
        (functionDefinitionGenerator, 1),
        (functionCallGenerator,       2),
        (functionJitCallGenerator,    1)
    ])

    // Disable splicing, as we only want the above code generators to run
    b.performSplicingDuringCodeGeneration = false

    // ... and generate a bunch of code, starting with a function so that
    // there is always at least one available for the call generators.
    b.run(functionDefinitionGenerator, recursiveCodegenBudget: 10)
    b.generate(n: 100)

    // Now, restore the previous code generators, re-enable splicing, and generate some more code
    b.fuzzer.codeGenerators = prevCodeGenerators
    b.performSplicingDuringCodeGeneration = true
    b.generate(n: 10)

    // Finally, run HeapObjectVerify on all our generated objects (that are still in scope)
    for obj in objects {
        b.eval("%HeapObjectVerify(%@)", with: [obj])
    }
}

let v8Profile = Profile(
    processArguments: [
//        "--expose-gc",
                       "--single-threaded",
                       "--predictable",
                       "--allow-natives-syntax",
                       "--interrupt-budget=1024",
                       //"--assert-types",
                       "--fuzzing"],

    processEnv: [:],

    codePrefix: """
                function classOf(object) {
                   var string = Object.prototype.toString.call(object);
                   return string.substring(8, string.length - 1);
                }

                function deepObjectEquals(a, b) {
                  var aProps = Object.keys(a);
                  aProps.sort();
                  var bProps = Object.keys(b);
                  bProps.sort();
                  if (!deepEquals(aProps, bProps)) {
                    return false;
                  }
                  for (var i = 0; i < aProps.length; i++) {
                    if (!deepEquals(a[aProps[i]], b[aProps[i]])) {
                      return false;
                    }
                  }
                  return true;
                }

                function deepEquals(a, b) {
                  if (a === b) {
                    if (a === 0) return (1 / a) === (1 / b);
                    return true;
                  }
                  if (typeof a != typeof b) return false;
                  if (typeof a == 'number') return (isNaN(a) && isNaN(b)) || (a===b);
                  if (typeof a !== 'object' && typeof a !== 'function' && typeof a !== 'symbol') return false;
                  var objectClass = classOf(a);
                  if (objectClass === 'Array') {
                    if (a.length != b.length) {
                      return false;
                    }
                    for (var i = 0; i < a.length; i++) {
                      if (!deepEquals(a[i], b[i])) return false;
                    }
                    return true;
                  }                
                  if (objectClass !== classOf(b)) return false;
                  if (objectClass === 'RegExp') {
                    return (a.toString() === b.toString());
                  }
                  if (objectClass === 'Function') return true;
                  
                  if (objectClass == 'String' || objectClass == 'Number' ||
                      objectClass == 'Boolean' || objectClass == 'Date') {
                    if (a.valueOf() !== b.valueOf()) return false;
                  }
                  return deepObjectEquals(a, b);
                }

                function opt(opt_param){
                """,

    codeSuffix: """
                }
                let jit_a0 = opt(false);
                opt(true);
                let jit_a0_0 = opt(false);
                %PrepareFunctionForOptimization(opt);
                let jit_a1 = opt(true);
                %OptimizeFunctionOnNextCall(opt);
                let jit_a2 = opt(false);
                if (jit_a0 === undefined && jit_a2 === undefined) {
                    opt(true);
                } else {
                    if (jit_a0_0===jit_a0 && !deepEquals(jit_a0, jit_a2)) {
                        fuzzilli('FUZZILLI_CRASH', 0);
                    }
                }
                """,

    ecmaVersion: ECMAScriptVersion.es6,

    crashTests: ["fuzzilli('FUZZILLI_CRASH', 0)", "fuzzilli('FUZZILLI_CRASH', 1)", "fuzzilli('FUZZILLI_CRASH', 2)"],

    additionalCodeGenerators: WeightedList<CodeGenerator>([
//        (ForceV8TurbofanGenerator, 10),
    ]),

    additionalProgramTemplates: WeightedList<ProgramTemplate>([
//        (MapTransitionsTemplate, 1)
    ]),

    disabledCodeGenerators: [],

    additionalBuiltins: [
        :
//        "gc"                                            : .function([] => .undefined),
//        "PrepareFunctionForOptimization"                : .function([.function()] => .undefined),
//        "OptimizeFunctionOnNextCall"                    : .function([.function()] => .undefined),
//        "NeverOptimizeFunction"                         : .function([.function()] => .undefined),
//        "DeoptimizeFunction"                            : .function([.function()] => .undefined),
//        "DeoptimizeNow"                                 : .function([] => .undefined),
//        "OptimizeOsr"                                   : .function([] => .undefined),
//        "placeholder"                                   : .function([] => .object()),
//        "print"                : .function([] => .undefined),
    ]
)
