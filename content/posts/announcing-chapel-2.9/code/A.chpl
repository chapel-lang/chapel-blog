module A {
  record R { type t = int; }

  proc foo(type t, param p = 1) param do
    return t == int && p == 2;
}
