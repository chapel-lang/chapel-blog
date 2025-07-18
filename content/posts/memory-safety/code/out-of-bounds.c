#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) {
  int idx = atoi(argv[1]); // convert the first argument into an int


  int array[1] = {0};      // allocate an array with space for 1 element
  int x = array[idx];      // access the array at 'idx'
                           // OOPS! no bounds checking

  printf("array at index %i is %i\n", idx, x);

  return 0;
}
