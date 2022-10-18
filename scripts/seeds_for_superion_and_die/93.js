// Copyright 2016 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Flags: --allow-natives-syntax
function foo() {
  return function (c) {
    var double_var = [3.0, 3.5][0];
    var literal = c ? ["v1".match(/\uD83D|X|/u).findIndex(function () {
      c = "valueOf" === "configurable".charAt(double_var);
      foo();
      return c;
    }), double_var] : [Math.floor(double_var), double_var];
    return double_var;
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
("v2" + "1.23").localeCompare(String.prototype.charAt.call("-0", l));
l;