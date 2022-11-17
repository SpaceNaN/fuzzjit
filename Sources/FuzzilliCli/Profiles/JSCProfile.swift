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

fileprivate let ForceDFGCompilationGenerator = CodeGenerator("ForceDFGCompilationGenerator", input: .function()) { b, f in
   guard let arguments = b.randCallArguments(for: f) else { return }

    b.buildForLoop(b.loadInt(0), .lessThan, b.loadInt(10), .Add, b.loadInt(1)) { _ in
        b.callFunction(f, withArgs: arguments)
    }
}

fileprivate let ForceFTLCompilationGenerator = CodeGenerator("ForceFTLCompilationGenerator", input: .function()) { b, f in
   guard let arguments = b.randCallArguments(for: f) else { return }

    b.buildForLoop(b.loadInt(0), .lessThan, b.loadInt(100), .Add, b.loadInt(1)) { _ in
        b.callFunction(f, withArgs: arguments)
    }
}

let jscProfile = Profile(
    getProcessArguments: { (randomizingArguments: Bool) -> [String] in
        var args = [
            "--validateOptions=true",
            // No need to call functions thousands of times before they are JIT compiled
            "--thresholdForJITSoon=10",
            "--thresholdForJITAfterWarmUp=10",
            "--thresholdForOptimizeAfterWarmUp=50",
            "--thresholdForOptimizeAfterLongWarmUp=50",
            "--thresholdForOptimizeSoon=50",
            "--thresholdForFTLOptimizeAfterWarmUp=100",
            "--thresholdForFTLOptimizeSoon=100",
            // Enable bounds check elimination validation
            "--validateBCE=true",
            "--reprl"]

        guard randomizingArguments else { return args }

        args.append("--useBaselineJIT=\(probability(0.9) ? "true" : "false")")
        args.append("--useDFGJIT=\(probability(0.9) ? "true" : "false")")
        args.append("--useFTLJIT=\(probability(0.9) ? "true" : "false")")
        args.append("--useRegExpJIT=\(probability(0.9) ? "true" : "false")")
        args.append("--useTailCalls=\(probability(0.9) ? "true" : "false")")
        args.append("--optimizeRecursiveTailCalls=\(probability(0.9) ? "true" : "false")")
        args.append("--useObjectAllocationSinking=\(probability(0.9) ? "true" : "false")")
        args.append("--useArityFixupInlining=\(probability(0.9) ? "true" : "false")")
        args.append("--useValueRepElimination=\(probability(0.9) ? "true" : "false")")
        args.append("--useArchitectureSpecificOptimizations=\(probability(0.9) ? "true" : "false")")
        args.append("--useAccessInlining=\(probability(0.9) ? "true" : "false")")

        return args
    },

    processEnv: ["UBSAN_OPTIONS":"handle_segv=0"],

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
                let gflag = true;
                let jit_a0 = opt(true);
                let jit_a0_0 = opt(false);
                for(let i=0;i<0x10;i++){opt(false);}
                let jit_a2 = opt(true);
                if (jit_a0 === undefined && jit_a2 === undefined) {
                    opt(true);
                } else {
                    if (jit_a0_0===jit_a0 && !deepEquals(jit_a0, jit_a2)) {
                        gflag = false;
                    }
                }
                for(let i=0;i<0x200;i++){opt(false);}
                let jit_a4 = opt(true);
                if (jit_a0 === undefined && jit_a4 === undefined) {
                    opt(true);
                } else {
                    if (gflag && jit_a0_0===jit_a0 && !deepEquals(jit_a0, jit_a4)) {
                        fuzzilli('FUZZILLI_CRASH', 0);
                    }
                }
                """,

    ecmaVersion: ECMAScriptVersion.es6,

    crashTests: ["fuzzilli('FUZZILLI_CRASH', 0)", "fuzzilli('FUZZILLI_CRASH', 1)", "fuzzilli('FUZZILLI_CRASH', 2)"],

    additionalCodeGenerators: [
        //(ForceDFGCompilationGenerator, 5),
        //(ForceFTLCompilationGenerator, 5),
    ],

    additionalProgramTemplates: WeightedList<ProgramTemplate>([]),

    disabledCodeGenerators: [],

    additionalBuiltins: [
      :
        //"gc"                  : .function([] => .undefined),
        //"transferArrayBuffer" : .function([.object(ofGroup: "ArrayBuffer")] => .undefined),
        //"noInline"            : .function([.function()] => .undefined),
        //"noFTL"               : .function([.function()] => .undefined),
        //"createGlobalObject"  : .function([] => .object()),
        //"OSRExit"             : .function([] => .unknown),
        //"drainMicrotasks"     : .function([] => .unknown),
        //"runString"           : .function([.string] => .unknown),
        //"makeMasquerader"     : .function([] => .unknown),
        //"fullGC"              : .function([] => .undefined),
        //"edenGC"              : .function([] => .undefined),
        //"fiatInt52"           : .function([.number] => .number),
        //"forceGCSlowPaths"    : .function([] => .unknown),
        //"ensureArrayStorage"  : .function([] => .unknown),
    ]
)
