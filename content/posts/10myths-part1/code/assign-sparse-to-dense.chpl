use Time;

config param optimizeAssign = false;  // use the optimized form?

config const n = 10;                  // the matrix problem size

config const printArrays = true,      // whether to print the arrays or timings
             printTiming = true;

//
// a dense and sparse n x n domain (index set)
//
const D = {1..n, 1..n},
      SD: sparse subdomain(D) = genTridiagInds(n);

//
// a dense and sparse n x n array, initialized to 1.0 and 2.0, respectively
//
var AD: [D] real = 1.0,
    AS: [SD] real = 2.0;

if printArrays {
  writeln(AD);
  writeln(AS);
}

//
// time the assignment between the arrays
//
var s: stopwatch;

s.start();
assign(AD, AS);
s.stop();

//
// print the resulting array and timing information
//
if printArrays then
  writeln(AD);

if printTiming then
  writeln("Assignment time = ", s.elapsed());

//
// validate that the assignment was correct
//
forall (i,j) in D do
  if j >= i-1 && j <= i+1 then
    assert(AD[i,j] == 2.0);
  else
    assert(AD[i,j] == 0.0);
writeln("Verification passed");

//
// Assign from a sparse to a dense array.  Note that this should
// really be an 'operator =' definition, but the compiler currently
// prevents users from defining these in their modules; it works if
// added to one of Chapel's internal or standard modules.
//
proc assign(ref a: [], b: []) where !a.isSparse() && b.isSparse() {
  if !optimizeAssign {
    forall idx in a.domain do
      a[idx] = b[idx];
  } else {
    a = b.IRV;                 // assign B's "zero" value to all of A,
    forall idx in b.domain do  // then copy over the non-zero elements
      a[idx] = b[idx];
  }
}

//
// generate the indices for a tridiagonal matrix of size n
//
iter genTridiagInds(n) {
  for i in 1..n {
    if i > 1 then
      yield (i,i-1);
    yield (i,i);
    if i < n then
      yield (i,i+1);
  }
}

