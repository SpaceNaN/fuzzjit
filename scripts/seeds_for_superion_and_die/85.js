// Copyright 2016 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Flags: --allow-natives-syntax
function foo() {
  return function (c) {
    var double_var = [3.0, 3.5][0];
    var literal = c ? /[a-z\u{10400}\u{10401}\u{10402}\u{10403}\u{10404}\u{10405}\u{10406}\u{10407}\u{10408}\u{10409}\u{1040A}\u{1040B}\u{1040C}\u{1040D}\u{1040E}\u{1040F}]/iu.exec("0").slice() : [double_var, 3.5];
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

var l = f1(true);
1;
l;