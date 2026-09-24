  use Parser;

  var p = new parser("input.txt");
  while p.hasMore() {
    try! {
      var o = p.next();
      writeln(o);
    } catch pe: ParseError {
      writeln("Parse error: ", pe.message());
      writeln("Stacktrace");
      for (file, linenum) in pe.stacktrace() {
        writeln("  ", file, ":", linenum);
      }
    }
    writeln("====");
  }
