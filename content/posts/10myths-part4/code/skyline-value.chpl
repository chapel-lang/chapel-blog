// the problem size, overridable by running the executable with `--n=...`
config const n = 10;

// a way of creating a triangular array value that works today
var A = for i in 1..n do [1..i] 0.0;

// initialize the triangular array
forall i in 1..n do
  forall j in 1..i do
    A[i][j] = i + (j-1)/10.0;

// print it out
for i in 1..n do
  writeln(A[i]);
