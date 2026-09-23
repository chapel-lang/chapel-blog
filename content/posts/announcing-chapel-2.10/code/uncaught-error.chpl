  use Parser;

  var p = new parser("input.txt");
  while p.hasMore() {
    var o = p.next();
    writeln(o);
    writeln("====");
  }
