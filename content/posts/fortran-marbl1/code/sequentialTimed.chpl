use CTypes, Time;
require "temperatures.h";

extern proc FtoC(arr: c_ptr(c_double), const ref len: c_int);
extern proc CtoF(arr: c_ptr(c_double), const ref len: c_int);

config const n = 5;
var temps: [1..n, 1..n] real;
forall (i,j) in temps.domain do
  temps[i,j] = 32.0 + (i-1)*5 + (j-1)*5;

var s: stopwatch;

s.start();
FtoC(c_ptrTo(temps), temps.size: c_int);
CtoF(c_ptrTo(temps), temps.size: c_int);
s.stop();

writeln("Sequential,", n, ",", s.elapsed());
