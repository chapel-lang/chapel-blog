use CTypes, Time, BlockDist;
require "temperatures.h";

extern proc FtoC(arr: c_ptr(c_double), const ref len: c_int);
extern proc CtoF(arr: c_ptr(c_double), const ref len: c_int);

config const n = 5;

const distDomain = blockDist.createDomain({1..n, 1..n, 1..n});
var temps: [distDomain] real;

forall (i,j,k) in distDomain do
  temps[i,j,k] = 32 + (i-1)*5 + (j-1)*5 + (k-1)*5;

var s: stopwatch;

s.start();
coforall loc in Locales do on loc {
  const localIndices = distDomain.localSubdomain();
  ref localTemps = temps.localSlice(localIndices);
  forall i in localIndices.dim(0) do
    FtoC(c_ptrTo(localTemps[i,..,..]), localTemps[i,..,..].size: c_int);
}

coforall loc in Locales do on loc {
  const localIndices = distDomain.localSubdomain();
  ref localTemps = temps.localSlice(localIndices);
  forall i in localIndices.dim(0) do
    CtoF(c_ptrTo(localTemps[i,..,..]), localTemps[i,..,..].size: c_int);
}
s.stop();

var version: string;
if numLocales == 1 && dataParTasksPerLocale == 1 {
  version = "Sequential";
} else if numLocales == 1 {
  version = "Threaded";
} else {
  version = "Distributed " + numLocales:string + " Nodes";
}
writeln(version,",", n,",", s.elapsed());
