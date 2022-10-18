// Copyright 2016 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Flags: --allow-natives-syntax
function foo() {
  return function (c) {
    var double_var = /.\h{3,4}./.exec("configurable".trimLeft())[0];
    var literal = c ? [1, double_var] : "valueOf".charAt(double_var).split("enumberable" + "valueOf", 0);
    return literal[0];
  };
}

var f1 = foo();
var f2 = foo(); // Both closures point to full code.

f1(false);
f2(false); // Optimize f1, but don't initialize the [1, double_var] literal.

f1(false); // Initialize the [1, double_var] literal, and transition the boilerplate to
// double.

f2(true); // Trick crankshaft into writing double_var at the wrong position.

var l = f1(Math.log2(3) >= Math.min(-NaN, 2147483647));
1;
l;