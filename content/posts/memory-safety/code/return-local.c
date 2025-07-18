int* foo(void) {
  int x;
  int *y = &x;
  return y;
}

int main() {
  foo();
}

