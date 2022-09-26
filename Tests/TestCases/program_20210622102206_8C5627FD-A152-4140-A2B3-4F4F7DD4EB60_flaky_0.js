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
  if (typeof a == 'number') return (isNaN(a) && isNaN(b)) || (a!=b);
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
const v1 = "hd3loo4HKe";
const v4 = [-1000000000000.0,-1000000000000.0,-1000000000000.0,-1000000000000.0];
const v6 = [-2,-2,-2,-2];
const v7 = [v4,0,-2,-1000000000000.0];
let v8 = {a:v7,b:-1000000000000.0,d:v7};
const v9 = -2;
if (opt_param) {
    v8 = -2;
}
const v10 = Date.now();
const v15 = [-1000000000.0,-1000000000.0,-1000000000.0,-1000000000.0,-1000000000.0];
let v16 = -4294967296;
const v17 = [v16,v16,v16,v16,v16];
const v18 = [v16,Function,9007199254740992,-1000000000.0,v16,v16];
const v19 = {__proto__:v16,a:Function,c:v15,e:v16,toString:"MIN_VALUE",valueOf:Function};
const v20 = 9007199254740992;
if (opt_param) {
    v16 = v16;
}
const v21 = v17.push(Function,v16,v19,Function,v18);
const v23 = 0;
if (opt_param) {
}
const v27 = [Function,0];
const v28 = ["BoYX1LFmPd",4294967295];
const v29 = {constructor:v27};
if (opt_param) {
}
const v31 = 9007199254740992;
const v33 = [-1000000000.0,-1000000000.0,-1000000000.0,-1000000000.0,-1000000000.0];
const v35 = [2,2,2,2,2];
const v38 = "localeCompare";
let v39 = Infinity;
const v40 = [v39,v39,v39,v39,v39];
const v42 = [-1,4294967295];
function* v43(v44,...v45) {
    const v46 = [v35,v40,v43];
    return v46;
    return v35;
    return v46;
}
if (opt_param) {
    v39 = 0;
}
const v47 = ~v39;
const v49 = [0.0];
for (const v50 in v49) {
}
const v51 = gc();
let v52 = 0;
do {
    const v55 = "BoYX1LFmPd".padStart(65536);
    const v56 = v52++;
} while (v52 < 65537);
const v57 = gc();
let v58 = "IgVAiMC9CA";
v58 = v29;
const v59 = v58[1];
const v60 = Date();
//  v7 : 0
//  v8 : 4
//  v10 : 0
//  v17 : 0
//  v18 : 0
//  v16 : 4
//  v21 : 0
//  v28 : 0
//  v40 : 0
//  v39 : 4
//  v47 : 0
//  v50 : 0
//  v51 : 0
//  v57 : 0
//  v58 : 0
//  v59 : 0
//  v60 : 0
return v60;
}
let jit_a0 = opt(false);
%PrepareFunctionForOptimization(opt);
let jit_a1 = opt(true);
%OptimizeFunctionOnNextCall(opt);
let jit_a2 = opt(false);
if (jit_a0 === undefined && jit_a1 === undefined) {
    opt(true);
} else {
    if (!deepObjectEquals(jit_a0, jit_a2)) {
        fuzzilli('FUZZILLI_CRASH', 0);
    }
}
// STDERR:
