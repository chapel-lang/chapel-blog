use IO except ioMode as iomode;                   // can't rename 'except's
import IO.string;
proc foo(x: int, y: int, z: int) {}
foo(1, 1.0, 1);                                   // can't pass '1.0' to 'y: int'
var tup = (1, 1, 1);
foo (x = (...tup));                               // can't pass a de-tuple to 'x'
var nontup = 1;
foo((...nontup));                                 // can't de-tuple a non-tuple
