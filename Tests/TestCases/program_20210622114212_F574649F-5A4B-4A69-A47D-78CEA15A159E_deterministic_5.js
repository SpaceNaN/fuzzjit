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
  if (typeof a == 'string') return a.length == 55 && a.toString().search(" GMT") !== -1;
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
const v2 = 0;
const v3 = JSON.stringify(JSON);
const v5 = [0,9007199254740991,0,9007199254740991,0];
const v6 = {length:v5,valueOf:v5};
JSON.a = v6;
//  v3 : 0
return v3;
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
