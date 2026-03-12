use Map;

proc getIt(m) {
  var val = m["it"];  // this is an error since 'it' wasn't stored in map 'm'
  return val;
}

proc main() {
  var m: map(string, int);
  m["this"] = 22;
  m["or"] = 33;
  m["that"] = 44;
  var val = getIt(m);
  writeln('m["it"] is ', val);
}
