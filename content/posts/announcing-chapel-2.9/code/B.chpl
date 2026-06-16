module B {
  use A;

  foo(R(real), p = false);
  foo(R);
  foo(R(?));
  foo(int, p=3);
}

