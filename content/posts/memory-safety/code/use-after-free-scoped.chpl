class C { var x: int; }

proc main() {
  // create a reference to a 'C' instance on the heap
  var b: borrowed C? = nil;

  {
    var instance = new owned C(0);
    b = instance.borrow();
  }

  b!.x = 42;

  // do other heap operations to make heap corruption more visible
  {
    var x = new owned C(2);
    var y = new owned C(3);
  }

  writeln(b);
}
