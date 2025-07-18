proc foo() ref {
  var x: int;
  ref y = x;
  return y;
}
foo();
