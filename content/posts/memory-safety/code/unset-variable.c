#include <stdio.h>
int main() {
  int x;                  // OOPS! x is not initialized
  
  printf("x is %i\n", x);
  return 0;
}
