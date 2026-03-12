use IO;

record R {
  var x : int;
}

proc main() {
  var s = new file(chpl_cstdout());
  var w = s.writer(locking=false);

  w.writeLiteral("Hello, World!\n");
  w.writeLiteral("-----\n");

  w.writeln("proper writeln!");
  w.writeln("multi ", "arg ", "writeln!");
  w.writeln(1, " ", 2, " ", 3);

  // invokes serialization framework
  var r = new R(5);
  w.writeln(r);
}
