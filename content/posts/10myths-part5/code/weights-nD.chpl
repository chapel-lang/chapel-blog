// the number of dimensions; compile with -srank=n to override
//
config param rank = 3;

// a rank-neutral declaration of the weight indices and values
//
const weightInds = genNdimDom(-1..1, n=rank),
      weight = [idx in weightInds]
                 0.5 / (2**(+ reduce [i in idx] (i!=0)));

// a helper procedure to create an n-dimensional domain where each
// dimension's indices are defined by 'rng'
//
proc genNdimDom(rng, param n: int) {
  var tup: n*rng.type;
  for i in 0..<n do
    tup(i) = rng;
  const Dom: domain(n) = tup;
  return Dom;
}

writeln(weight);
