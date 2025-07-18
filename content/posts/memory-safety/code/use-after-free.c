#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) {

  int* buf = malloc(sizeof(int));
  free(buf);

  buf[0] = 42; // OOPS: uses 'buf' after the memory is freed

  // do other heap operations to make heap corruption more visible
  {
    int* other_buf = malloc(sizeof(int));
    other_buf[0] = 120;
    free(other_buf);
  }

  printf("buf[0] is %i\n", buf[0]);
  return 0;
}
