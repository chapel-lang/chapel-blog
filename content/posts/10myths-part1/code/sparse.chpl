config const numRows = 10,       // the logical number of rows in the matrix
             numCols = 10,       // the logical number of columns
             numNonzeroes = 28;  // the total number of non-zero entries

config type eltType = real;       // the type of the non-zero entries

// the dense and sparse indices representing the matrix
const Dom = {1..numRows, 1..numCols},
      SpsDom: sparse subdomain(Dom) = [i in 1..28] ((1,1), (1,2),
                                       (2,1), (2,2), (2,3),
                                       (3,2), (3,3), (3,4),
                                       (4,3), (4,4), (4,5),
                                       (5,4), (5,5), (5,6),
                                       (6,5), (6,6), (6,7),
                                       (7,6), (7,7), (7,8),
                                       (8,7), (8,8), (8,9),
                                       (9,8), (9,9), (9,10),
                                                       (10,9), (10,10))[i-1];

var SpsMat: [SpsDom] eltType;  // the sparse matrix itself

for (r,c) in SpsDom do
  SpsMat[r,c] = r*1000 + c;

for r in 1..numRows {
  for c in 1..numCols {
    if SpsDom.contains(r,c) {
      write(SpsMat[r,c], " ");
    } else {
      write("0.0 ");
    }
  }
  writeln();
}

forall (r,c) in SpsDom do
  SpsMat[r,c] = r*1000 + c;

for r in 1..numRows {
  for c in 1..numCols {
    if SpsDom.contains(r,c) {
      write(SpsMat[r,c], " ");
    } else {
      write("0.0 ");
    }
  }
  writeln();
}

