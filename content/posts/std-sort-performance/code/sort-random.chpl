use Time, Sort, Random;

// This 'config const' makes it easy to change the number of elements when
// running the program! For example:
//   ./sort-random --n 500_000
config const n = 128*1024*1024;

// Declare an array storing n elements, starting from 0
var A: [0..<n] uint; // note: uint in Chapel defaults to 64 bits

// Set the elements to random values
fillRandom(A);

// set up timing for the sort
var timer: stopwatch;
timer.start();

// run the sort itself
sort(A);

// finish timing the sort and print the result
var elapsed = timer.elapsed();
writeln("Sorted ", n, " elements in ", elapsed, " seconds");
writeln(n/elapsed/1_000_000, " million elements sorted per second");
