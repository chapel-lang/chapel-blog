proc foo(x: int) {
  return x + 1;
}

proc bar(x) {
  return x:int;
}
bar(x = "42");
bar(x = 42.0);

proc baz(x) do return x;
baz(x = "lol");
