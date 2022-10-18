// Copyright 2016 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Flags: --allow-natives-syntax
function foo() {
  return function (c) {
    var double_var = 759250124;
    var literal = c ? [1, double_var] : [RegExp.prototype.exec.call(/\uab84/i, "1024").findIndex(function () {
      foo();
      foo();
    }), 3.5];
    return literal[double_var];
  };
}

var f1 = foo();
var f2 = foo(); // Both closures point to full code.

f1(false);
f2(false); // Optimize f1, but don't initialize the [1, double_var] literal.

f1(true); // Initialize the [1, double_var] literal, and transition the boilerplate to
// double.

f2(true); // Trick crankshaft into writing double_var at the wrong position.

var l = f1(true);
l;
(l ** l) ** (l - l);