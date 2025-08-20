const Dom = {1..5, 1..5, 1..5},
      BigDom = {0..6, 0..6, 0..6},
      R = [(i,j,k) in BigDom] i*100 + j + k / 100.0;

var S: [Dom] real;

// Create the 3x3x3 array of weights using a closed-form expression
//
const weightInds = {-1..1, -1..1, -1..1},
      weight = [(i,j,k) in weightInds] 0.5 / 2**((i!=0) + (j!=0) + (k!=0));

// Assign each element of S the weighted sum of its neighboring corresponding
// elements in R
//
forall xyz in S.domain do
  S[xyz] = + reduce [off in weightInds] weight[off] * R[xyz+off];

writeln(S);
