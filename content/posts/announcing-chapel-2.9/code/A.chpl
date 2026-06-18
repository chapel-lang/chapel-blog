module A {
  record R { type t = int; }

  proc foo(type t, param p = 1) {
    var lhs = t == int;
    var rhs = p == 2;
    return lhs && rhs;
  }
}
