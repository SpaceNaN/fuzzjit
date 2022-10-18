// Copyright 2016 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Flags: --allow-natives-syntax
function foo() {
  return function (c) {
    var double_var = [3.0, 3.5][0];
    var literal = c ? [1, double_var] : [double_var, 3.5];
    return literal[0];
  };
}

var __es_v2 = String.prototype.match.call(String.prototype.padStart.call("__proto__", 3.5), /(?:(?:a*)*)b/);

var f1 = foo();

var __es_v1 = new Uint8ClampedArray(5);

var f2 = foo(); // Both closures point to full code.

f1(false);
foo();
f2(false); // Optimize f1, but don't initialize the [1, double_var] literal.

f1(false); // Initialize the [1, double_var] literal, and transition the boilerplate to
// double.

f2(true); // Trick crankshaft into writing double_var at the wrong position.

var l = f1(true);

var __es_v0 = new Array(10);

1;
l;
foo();