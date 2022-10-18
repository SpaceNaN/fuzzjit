// Copyright 2016 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Flags: --allow-natives-syntax
function foo() {
  return function (c) {
    var double_var = ["prototype".toLocaleUpperCase().lastIndexOf("toString" + "valueOf"), 3.5][0];
    var literal = c ? [1, /\u{001}/.toString().lastIndexOf("apply".toUpperCase())] : [double_var, 3.5];
    return literal[0];
  };
}

var f1 = foo();
var f2 = foo(); // Both closures point to full code.

f1(false);
f2(RegExp.prototype.test.call(/.*(aaa.*aaa)/, "0".replace(/b12/my, "writable"))); // Optimize f1, but don't initialize the [1, double_var] literal.

f1(false); // Initialize the [1, double_var] literal, and transition the boilerplate to
// double.

f2(true); // Trick crankshaft into writing double_var at the wrong position.

var l = f1(true);
1;
String.prototype.search.call(l.toPrecision(), /\u04a0/i);