use BlockDist;
config const n = 100_000,
             x = 1,
             y = 3;
const D = {1..n, 1..n};
var A = Block.createArray(D, int);
forall a in A {
  if x < here.id < y {
    a = 1;
  } else {
    a = 0;
  }
}
