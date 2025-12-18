use IO;
use Print; // helper module while we work toward resolving more of IO

// utilize generic varargs and param for-loops to mimic 'writeln' behavior
proc myWriteln(const args...?n) {
  for param i in 0..<n {
    print(args(i));
  }
  println("");
}

// return a tuple from a procedure
proc double(arg: int) {
  return (arg, arg*2);
}

proc main() {
  // uses generic varargs and a param for-loop to mimic 'writeln' behavior
  myWriteln(1, " != ", 2.0);

  // grouped variable initialization, unpacking the result of 'double'
  var (a, b) = double(5);
  myWriteln("a = ", a, ", b = ", b);

  // Open 'stdout' and use the IO module to write a string!
  //
  // Utilizes shared objects, ranges, generic types, enums, interoperability,
  // and a great deal of string manipulating-module code.
  var s = new file(chpl_cstdout());
  var w = s.writer();
  w.writeLiteral("Hello, World!\n");
}
