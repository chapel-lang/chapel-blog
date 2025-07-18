class C { var x: int; }

{
  var x = new C(42);
  var b = x.borrow();  // b refers to the same class instance as x
  {
    x = new C(41);     // now x refers to a new class instance
                       // the old class instance is deleted
  }
  writeln(b);          // use-after-free, b refers to a deleted instance
}
