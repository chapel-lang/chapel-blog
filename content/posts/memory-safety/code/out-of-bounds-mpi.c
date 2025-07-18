#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <mpi.h>

int main(int argc, char** argv) {
  MPI_Init(&argc, &argv);
  int count = atoi(argv[1]); // convert the first argument into an int

  int myRank = 0;
  int numRanks = 0;
  MPI_Comm_rank (MPI_COMM_WORLD, &myRank);
  MPI_Comm_size (MPI_COMM_WORLD, &numRanks);

  size_t nPerRank = 1000;
  
  int* array = malloc(nPerRank*sizeof(int));
  int* gathered = malloc(numRanks*nPerRank*numRanks*sizeof(int));

  for (int i = 0; i < nPerRank; i++) {
    array[i] = myRank;
  }

  // Gather the first value from each array onto rank 0
  MPI_Gather(/* sendbuf */ array,
             /* sendcount */ 1,
             /* sendtype */ MPI_INT,
             /* recvbuf */ gathered,
             /* recvcount */ 1,
             /* recvtype */ MPI_INT,
             /* root */ 0,
             /* comm */ MPI_COMM_WORLD);

  if (myRank == 0) {
    printf("Correct gather:\n");
    for (int i = 0; i < numRanks; i++) {
      printf("  %i\n", gathered[i]);
    }
  }

  // What if there is an error in MPI_Gather?
  // If 'count' is larger than nPerRank, this version
  // will gather too much data and refer to invalid memory.
  MPI_Gather(/* sendbuf */ array,
             /* sendcount */ count,
             /* sendtype */ MPI_INT,
             /* recvbuf */ gathered,
             /* recvcount */ count,
             /* recvtype */ MPI_INT,
             /* root */ 0,
             /* comm */ MPI_COMM_WORLD);

  if (myRank == 0) {
    printf("Potentially bad gather:\n");
    for (int i = 0; i < count*numRanks; i++) {
      printf("  %i\n", gathered[i]);
    }
  }

  MPI_Finalize();
  return 0;
}
