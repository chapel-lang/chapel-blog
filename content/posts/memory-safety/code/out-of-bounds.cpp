#include <vector>
#include <iostream>

int main(int argc, char** argv) {
  int idx = atoi(argv[1]);   // convert the first argument into an int

  std::vector<int> array(1); // create a vector with space for one element

  int x = array[idx];
  std::cout << "array at index " << idx << " is " << x << std::endl;

  return 0;
}
