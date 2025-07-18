//
// Use standard modules for timing routines and type utility functions
//
use Time, Types;

//
// Use a common HPCC user module containing helper routines
//
use HPCCProblemSize;

//
// Whether to use SI units (true == GB, false == GiB)
//
config const SI = true;

//
// Capture an alias for the host CPU where we start execution
//
const host = here;

//
// The number of vectors and element type of those vectors
//
const numVectors = 3;
type elemType = real(64);

//
// Configuration constants to set the problem size (m) and the scalar
// multiplier (alpha)
//
config const m = 1<<26,
             alpha = 3.0;

//
// Configuration constants to set the number of trials to run and the
// amount of error to permit in the verification
//
config const numTrials = 10,
             epsilon = 0.0;

//
// Configuration constants to control what's printed -- benchmark
// parameters, input and output arrays, and/or statistics
//
config const printParams = true,
             printArrays = false,
             printStats = true;

//
// The program entry point
//
proc main() {
  printConfiguration();  // print the problem size, number of trials, etc.

  //
  // Move execution from the host CPU to the initial GPU
  //
  on here.gpus[0] {
    //
    // ProblemSpace describes the index set for the three vectors.  It
    // is a 1D domain that has indices 1 through m.
    //
    const ProblemSpace = {1..m};

    //
    // A, B, and C are the three vectors, declared to store a variable of type
    // elemType for each index in ProblemSpace. As they are local to the `on`
    // statement that executes on the GPU, the memory for these arrays will be
    // allocated in GPU-accessible memory.
    //
    var A, B, C: [ProblemSpace] elemType;

    initVectors(B, C);  // Initialize the input vectors, B and C

    var execTime: [1..numTrials] real;  // an array of timings

    for trial in 1..numTrials {  // loop over the trials
      //
      // Capture the start time
      //
      const startTime = timeSinceEpoch().totalSeconds();

      //
      // The main loop: Iterate over the vectors A, B, and C in a
      // parallel, zippered manner referring to the elements as a, b, and c.
      // Compute the multiply-add on b and c, storing the result to a.
      // This forall loop will be offloaded onto the GPU.
      //
      forall (a, b, c) in zip(A, B, C) do
        a = b + alpha * c;

      //
      // Store the elapsed time
      //
      execTime(trial) = timeSinceEpoch().totalSeconds() - startTime;
    }

    on host {
      printResults(execTime);      // ...and print the results
    }
  }
}

//
// Print the problem size and number of trials
//
proc printConfiguration() {
  if printParams {
    printProblemSize(elemType, numVectors, m);
    writeln("Number of trials = ", numTrials, "\n");
  }
}

//
// Initialize vectors B and C using arbitrary values, and
// optionally print them to the console
//
proc initVectors(ref B, ref C) {
  forall b in B do b = 0.5;
  forall c in C do c = 0.5;

  if printArrays {
    writeln("B is: ", B, "\n");
    writeln("C is: ", C, "\n");
  }
}

//
// Print out the timings and the throughput
//
proc printResults(execTimes) {
  if printStats {
    var totalTime = 0.0;
    var minTime = max(real);
    var maxTime = min(real);
    for t in execTimes[2..] { // note: skip the first iteration
      totalTime += t;
      minTime = min(minTime, t);
      maxTime = max(maxTime, t);
    }
    var avgTime = totalTime/(numTrials-1);

    writeln("Execution time:");
    writeln("  avg = ", avgTime);
    writeln("  min = ", minTime);
    writeln("  max = ", maxTime);

    if SI {
      const GBPerSec =
        numVectors * numBytes(elemType) * (m / minTime) * 1e-9;
      writeln("Performance (GB/s) = ", GBPerSec);
    } else {
      const GiBPerSec =
        numVectors * numBytes(elemType) * (m / minTime) / (1<<30):real;
      writeln("Performance (GiB/s) = ", GiBPerSec);
    }
  }
}
