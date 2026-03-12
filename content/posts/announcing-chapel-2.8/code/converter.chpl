use IO;

var s = new file(chpl_cstdout());
var w = s.writer();

w.writeln("Hello, world!");
w.writeln(1, " ", 2.0, " three");

record R {
  var x : int;
}

// invokes Chapel's serialization framework
var r = new R(5);
w.writeln(r);
