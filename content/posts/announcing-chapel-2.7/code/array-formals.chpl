proc foo(A: [?D] ?t) param {
  param isRect =
    if A.isDefaultRectangular() then "rectangular" else "not rectangular";
  param eltType = A.eltType:string;
  param dim = D.rank:string;
  return isRect + " " + dim + "-dimensional array of " + eltType;
}

use BlockDist;
var A: [1..10] int;
var B = blockDist.createArray(1..10, 1..10, real);

param infoA = foo(A);
param infoB = foo(B);
