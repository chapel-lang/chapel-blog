use Math;

config const numRows = 10,       // the logical number of rows in the matrix
             numCols = 10,       // the logical number of columns
             numNonzeroes = 28;  // the total number of non-zero entries

config type eltType = real;       // the type of the non-zero entries

// a dense vector storing the non-zero matrix elements
var nonzeroes: [1..numNonzeroes] eltType;

const rowStart: [1..numRows+1] int = [1, 3, 6, 9, 12, 15, 18, 21, 24, 27, 29],  // the index where each row starts
      colIdx: [1..numNonzeroes] int = [1, 2, 1, 2, 3, 2, 3, 4, 3, 4, 5, 4, 5, 6, 5, 6, 7, 6, 7, 8, 7, 8, 9, 8, 9, 10, 9, 10]; // the column index of each nonzero

for r in 1..numRows do
  for i in rowStart[r]..<rowStart[r+1] do
    nonzeroes[i] = r*1000 + colIdx[i];


for r in 1..numRows {
  for c in 1..numCols {
    var found = false;
    for i in rowStart[r]..<rowStart[r+1] {
      if colIdx[i] == c {
        write(nonzeroes[i], " ");
        found = true;
      }
    }
    if !found then
      write("0.0 ");
  }
  writeln();
}

forall r in 1..numRows do
  forall i in rowStart[r]..<rowStart[r+1] do
    nonzeroes[i] = r*1000 + colIdx[i];

for r in 1..numRows {
  for c in 1..numCols {
    var found = false;
    for i in rowStart[r]..<rowStart[r+1] {
      if colIdx[i] == c {
        write(nonzeroes[i], " ");
        found = true;
      }
    }
    if !found then
      write("0.0 ");
  }
  writeln();
}
