#include <string>
#include <iostream>

int main(int argc, char** argv) {
  std::string greeting = "Hello ";
  greeting += argv[1];                // append the passed name to the greeting
  std::cout << greeting << std::endl; // print the greeting
  
  return 0;
}
