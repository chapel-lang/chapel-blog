#include <string>
#include <iostream>

int main(int argc, char** argv) {
  std::string s = "s";
  // all of these are out-of-bounds accesses
  s[5] = 'x';
  s[6] = 'x';
  char x = s[10];

  std::cout << s << std::endl;
  std::cout << x << std::endl;

  return 0;
}
