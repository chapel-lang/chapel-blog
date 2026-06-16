proc foo(x: int): int (64) {
  return x + 1;
}

proc bar(x): int(64) {
  return 42;
}
bar (x = "hello");
bar (x = 42.0);

proc baz(x: string): string do return x;
baz(x = "lol");
