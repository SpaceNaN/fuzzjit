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

import XCTest
@testable import Fuzzilli


class ExecuteTests: XCTestCase {
    func testBasicExecute() {
        let script:String = """
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
                        const v1 = "tKUctTM6rZ";
                        const v3 = [-2.0,1,-2.0];
                        let v4 = v3.shift();
                        const v6 = [2.0];
                        const v7 = [];
                        const v12 = [-1.0,-1.0,-1.0,-1.0,-1.0];
                        const v14 = [4294967297,4294967297];
                        const v15 = ["caller",v14,0,WeakMap,"caller",4294967297,v12,v12,WeakMap];
                        let v16 = Int32Array;
                        if (opt_param) {
                            v16 = -9007199254740991;
                        }
                        function v21(v22,v23,v24,v25,v26) {
                            function v27(v28,v29) {
                                const v31 = ++v4;
                                const v32 = new ArrayBuffer(v16);
                                const v33 = v21(v32);
                            }
                            const v35 = new Promise(v27);
                        }
                        const v37 = new ArrayBuffer();
                        const v38 = v21(DataView,-2147483648,0);
                        //  v4 : 0
                        //  v16 : 4
                        //  v38 : 0
                        return v4;

                     }
                     let jit_a0 = opt(false);
                     opt(true);
                     let jit_a0_0 = opt(false);
                     %PrepareFunctionForOptimization(opt);
                     let jit_a1 = opt(true);
                     %OptimizeFunctionOnNextCall(opt);
                     let jit_a2 = opt(false);
                     if (jit_a0 === undefined && jit_a1 === undefined) {
                         opt(true);
                     } else {
                         if (jit_a0_0===jit_a0 && !deepEquals(jit_a0, jit_a2)) {
                             fuzzilli('FUZZILLI_CRASH', 0);
                         }
                     }
                     // STDERR:

                     """;
        let jsShellPath = "/mnt/b/Projects/FuzzBoom/V8/v8/d8";
        let processArguments = ["--expose-gc",
                           "--single-threaded",
                           "--predictable",
                           "--allow-natives-syntax",
                           "--interrupt-budget=1024",
                           //"--assert-types",
                           "--fuzzing"],
//        let runner: ScriptRunner
        runner = REPRL(executable: jsShellPath, processArguments: processArguments, processEnvironment: [:])
        let execution = runner.run(script, withTimeout: 800)
        print(2333)
        XCTAssertEqual(.succeeded, execution.outcome)
    }
}

extension ExecuteTests {
    static var allTests : [(String, (ExecuteTests) -> () throws -> Void)] {
        return [
            ("testBasicExecute", testBasicExecute),
        ]
    }
}

