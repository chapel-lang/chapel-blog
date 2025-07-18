import RangeChunk.chunks;

config const n = 32,              // the problem size (use `--n` to specify!)
             sliceSize = 4;       // the number of elements per slice

var HostArr: [1..n] int;          // allocates 'HostArr' on the host
HostArr = 1;                      // executes on the (multicore) CPU

const numGpus = here.gpus.size;   // number of GPUs on the locale
coforall (gpu, gpuChunk) in zip(here.gpus, chunks(1..n, numGpus)) {
  on gpu {
    const numSlices = gpuChunk.size/sliceSize+1;  // (+1 is to round up)

    coforall chunk in chunks(gpuChunk, numSlices) {
      var DevArr: [chunk] int;    // allocates 'DevArr' on the device

      DevArr = HostArr[chunk];    // copies a slice from host to device
      DevArr += 1;                // executes on the device as a kernel
      HostArr[chunk] = DevArr;    // copies from device to a slice on host
    }
  }
}

writeln(HostArr);  // prints "2 2 2 2 2 ..."
