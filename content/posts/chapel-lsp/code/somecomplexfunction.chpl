// Somewhere in library code, perhaps:
proc someComplexFunction(x, y, z, a, b, c) do return (b,c);

// Now, in your editor:
someComplexFunction(z="Hello", b=42.0, 1, 2, 3, 4);

var result =
    someComplexFunction(z="Hello", b=42.0, 1, 2, 3, 4);

var (first, second) =
    someComplexFunction(z="Hello", b=42.0, 1, 2, 3, 4);


operator +(param left: int, param right: int) param do return __primitive("+", left, right);

param firstParam = 1;
param secondParam = firstParam + 42;

param thirdParam;
if firstParam == 1 {
  thirdParam = "hello";
} else {
  thirdParam = "goodbye";
}

proc assignOneToAnother(ref changeMe, changeTo: changeMe.type) {
  changeMe = changeTo;
}
var myIntVar = 41;
assignOneToAnother(myIntVar, 42);
var myStringVar = "hello";
assignOneToAnother(myStringVar, "world");

proc typeSupportsEfficientOperation(type t) param do return t == int;

proc doEfficientOperation(x: int) do return 3.14;
proc doSlowOperation(x) do return 3.0 + 0.14;

proc genericFunction(x) {
  if typeSupportsEfficientOperation(x.type) {
    return doEfficientOperation(x);
  } else {
    return doSlowOperation(x);
  }
}

genericFunction(42);
genericFunction("hello");
