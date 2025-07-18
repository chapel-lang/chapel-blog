#include <stdio.h>
#include <string.h>

#define MAX_GREETING 16

int main(int argc, char** argv) {
  char greeting[MAX_GREETING]; // C doesn't really have string support;
                               // here we allocate an array to store the
                               // greeting

                               // OOPS! allocated array might not be big enough

  strcpy(greeting, "Hello ");  // copy "Hello " into 'greeting'
  strcat(greeting, argv[1]);   // append the passed name to the greeting
  printf("%s\n", greeting);
  return 0;
}
