// stopgap helper module until 'writeln' is available with --dyno. See below.
use Print;

record R {
  var x : int;

  proc print() {
    print("x = ");
    println(x);
  }
}

class C {
  var x : int;
  var y : real;

  proc print() {
    print("x = ");
    print(x);
    print(", y = ");
    println(y);
  }
}

proc main() {
  var r = new R(42);
  r.print();

  var c = new unmanaged C(10, 42.0);
  c.print();
}
