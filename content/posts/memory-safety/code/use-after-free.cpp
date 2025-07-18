// compile with
//   g++ use-after-free.cpp --std=c++14       

#include <iostream>
#include <memory>

int main(int argc, char** argv) {
  // allocate an integer on the heap
  auto buf = std::make_unique<int>(0);

  // create a reference that refers to the value on the heap
  int& ref_to_val = *buf;

  {
    // Replace the buffer with something else.
    // This causes the old buffer to be freed.
    buf = std::make_unique<int>(1);
  }

  ref_to_val = 42; // OOPS: uses 'buf' after the memory is freed

  // do other heap operations to make heap corruption more visible
  {
    buf = std::make_unique<int>(2);
    buf = std::make_unique<int>(3);
  }

  printf("buf[0] is %i\n", ref_to_val);
  return 0;
}
