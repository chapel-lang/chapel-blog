use IO except ioMode as iomode;
import IO.string;
proc foo(x: int, y: int, z: int) {}
foo(1, 1.0, 1);
var tup = (1, 1, 1);
foo (x = (... tup));
var nontup = 1;
foo((...nontup));
