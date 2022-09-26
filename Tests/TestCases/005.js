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
 function opt(){
//  const v0 = "2147483648";
 const v3 = JSON["0"];
//  const v4 = -1000000000.0;
//  const v6 = -2.220446049250313e-16;
 JSON[0] = 0;
 delete JSON[v3];
 //  v3 : 0
 //  v2 : 0
 //  v2 : 0
 return v3;
 }
 let jit_a0 = opt(true);
 print(jit_a0);
 let jit_a0_0 = opt(false);
 let jit_a0_1 = opt(true);
//  for(let i=0;i<0x10;i++){opt(false);}
 let jit_a2 = opt(true);
 print(jit_a2);
 if (jit_a0 === undefined && jit_a2 === undefined) {
     opt(true);
 } else {
     if (jit_a0_1===jit_a0 && !deepEquals(jit_a0, jit_a2)) {
         fuzzilli('FUZZILLI_CRASH', 0);
     }
 }
//  for(let i=0;i<0x500;i++){opt(false);}
//  let jit_a3 = opt(true);
//  if (jit_a0 === undefined && jit_a3 === undefined) {
//      opt(true);
//  } else {
//      if (jit_a0_1===jit_a0 && !deepEquals(jit_a0, jit_a3)) {
//          fuzzilli('FUZZILLI_CRASH', 0);
//      }
//  }
//  for(let i=0;i<0x1000;i++){opt(false);}
//  let jit_a4 = opt(true);
//  if (jit_a0 === undefined && jit_a4 === undefined) {
//      opt(true);
//  } else {
//      if (jit_a0_1===jit_a0 && !deepEquals(jit_a0, jit_a4)) {
//          fuzzilli('FUZZILLI_CRASH', 0);
//      }
//  }
 // STDERR:
 