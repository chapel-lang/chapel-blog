import RangeChunk.chunks;

config const n = 32;                // the problem size (use `--n` to specify!)
config const sliceSize = 4;         // the number of elements per slice

var HostArr: [1..n] int;            // allocates on the host
HostArr = 1;                        // executes on the (multicore) CPU

coforall (loc, locChunk) in zip(Locales, chunks(1..n, numLocales)) {
  on loc {
    const numGpus = here.gpus.size;
    coforall (gpu, gpuChunk) in zip(here.gpus, chunks(locChunk, numGpus)) {
      on gpu {
        const numSlices = gpuChunk.size/sliceSize+1;  // (+1 is to round up)

        coforall chunk in chunks(gpuChunk, numSlices) {
          var DevArr: [chunk] int;  // allocates on the device

          DevArr = HostArr[chunk];  // copies a slice from host to device
          DevArr += 1;              // executes on the device as a kernel
          HostArr[chunk] = DevArr;  // copies from device to a slice on host
        }
      }
    }
  }
}

writeln(HostArr);  // prints "2 2 2 2 2 ..."
