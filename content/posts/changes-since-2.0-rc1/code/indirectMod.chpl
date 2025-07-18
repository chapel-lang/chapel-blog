record rec {
  var x: int;
}

var globalRec = new rec(15);

proc takeRec(const r: rec) {
  writeln(r);
  globalRec.x = 3;
  writeln(r);  // By modifying globalRec, the argument r has been changed!
}

takeRec(globalRec);
