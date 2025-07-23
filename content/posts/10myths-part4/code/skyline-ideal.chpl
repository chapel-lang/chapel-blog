// the problem size, overridable by running the executable with `--n=...`
config const n = 10;

// a triangular array declaration
var A: [i in 1..n] [1..i] real;

// initialize the triangular array
forall i in 1..n do
  forall j in 1..i do
    A[i][j] = i + (j-1)/10.0;

// print it out
writeln(A);
