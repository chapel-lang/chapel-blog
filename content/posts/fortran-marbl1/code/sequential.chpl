use CTypes;
require "temperatures.h";

extern proc FtoC(arr: c_ptr(c_double), const ref len: c_int);
extern proc CtoF(arr: c_ptr(c_double), const ref len: c_int);

var arr = [32.0, 212.0, 98.6, 0.0, 100.0];

writeln("Original Array: ", arr);
FtoC(c_ptrTo(arr), arr.size: c_int);
writeln("After FtoC:     ", arr);
CtoF(c_ptrTo(arr), arr.size: c_int);
writeln("After CtoF:     ", arr);
