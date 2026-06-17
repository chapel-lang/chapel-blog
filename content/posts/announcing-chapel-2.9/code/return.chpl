proc foo(x: int) {
  return x + 1;
}

proc bar(x) {
  return 42;
}
bar (x = "hello");
bar (x = 42.0);

proc baz(x: string) do return x;
baz(x = "lol");
