// the problem size, overridable by running the executable with `--n=...`
config const n = 10;

// a record that wraps a 1D dense array
record array {
  var inds: range;
  type eltType;
  forwarding var B: [inds] eltType;
}

// a triangular array declaration
var A = [i in 1..n] new array(1..i, real);
//
// alternatively, this could have been declared using an explicit type as:
//   var A: [1..n] array(real) = [i in 1..n] new array(1..i, real);

// initialize the triangular array
forall i in 1..n do
  forall j in 1..i do
    A[i][j] = i + (j-1)/10.0;

// print it out
for i in 1..n do
  writeln(A[i]);
