#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <shmem.h>

int main(int argc, char** argv) {
  int idx = atoi(argv[1]); // convert the first argument into an int

  int myRank = 0;
  int numRanks = 0;

  shmem_init();

  myRank = shmem_my_pe();
  numRanks = shmem_n_pes();

  size_t nPerRank = 1000;

  int* array = (int*) shmem_malloc(nPerRank*sizeof(int));
  memset(array, 1, nPerRank*sizeof(int));

  if (myRank == numRanks-1) {
    int val = 42;
    shmem_int_put(array + idx, &val, 1, 0); // OOPS: idx might be out-of-bounds
    shmem_int_get(&val, array + idx, 1, 1); // OOPS: idx might be out-of-bounds
    printf("Got value %#x\n", val);
  }

  return 0;
}
