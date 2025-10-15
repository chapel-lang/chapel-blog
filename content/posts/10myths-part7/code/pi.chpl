// use standard modules for block-distributed arrays and random numbers
use BlockDist, Random;

// the number of random samples to compute (run with '--n=...' to change)
config const n = 1_000_000;

// create block-distributed coordinate arrays over the indices 1 thru n
var X, Y = blockDist.createArray(1..n, real);

// fill the arrays with random (x,y) values
fillRandom(X);
fillRandom(Y);

// compute how many (x,y) points lie within a quadrant of the unit circle
const withinCircle = + reduce (X**2 + Y**2 < 1.0);

// print the result
writeln("pi is approximately ", 4.0*withinCircle/n);
