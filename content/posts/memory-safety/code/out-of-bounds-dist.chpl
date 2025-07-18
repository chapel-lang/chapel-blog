use BlockDist;

config const idx = 1;    // enable command-line options like --idx=2

// create a distributed array storing 100 elements
var array = blockDist.createArray(0..#100, int);

var x = array[idx];

writeln("array at index ", idx, " is ", x);
