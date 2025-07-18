use CTypes;

extern {
  #include <stdint.h>
  #include <inttypes.h>
  #include <stdio.h>

  static void println(int64_t x) {
    printf("%" PRId64 "\n", x);
  }
}

extern proc println(x: int(64));

proc main() {
  // Simply prints '42' to the console.
  var x : int = 42;
  var y = c_ptrTo(x);
  println(y.deref());
}

