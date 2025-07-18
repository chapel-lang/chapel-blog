config const idx = 1;    // enable command-line options like --idx=2

var array:[0..#10] int;  // allocate an array with space for 10 elements

var x = array[idx];

writeln("array at index ", idx, " is ", x);
