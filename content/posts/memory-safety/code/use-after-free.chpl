// compile with
//   chpl use-after-free.chpl

class C { var x: int; }

proc main() {
  // allocate a class instance on the heap containing an integer field
  var instance = new owned C(0);

  // create a reference the field 'x' on the heap
  ref refToVal = instance.x;

  {
    // Replace the instance with something else.
    // This causes the old instance to be deleted.
    instance = new owned C(1);
  }

  refToVal = 42;

  // do other heap operations to make heap corruption more visible
  {
    instance = new owned C(2);
    instance = new owned C(3);
  }

  writeln(refToVal);
}
