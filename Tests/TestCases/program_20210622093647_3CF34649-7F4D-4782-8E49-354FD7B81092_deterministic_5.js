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
  if (typeof a == 'number') return isNaN(a) && isNaN(b);
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
const v3 = Date.now();
const v7 = [1000000000000.0,1000000000000.0,1000000000000.0];
const v8 = [9007199254740992,"BoYX1LFmPd","hd3loo4HKe",-1000000000000.0,Date,v3,v7,"BoYX1LFmPd"];
//  v8 : 0
return v8;
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
