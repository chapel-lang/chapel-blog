import RangeChunk.chunks;

config const n = 32,              // the problem size (use `--n` to specify!)
             sliceSize = 4;       // the number of elements per slice

const numSlices = n/sliceSize+1;  // (+1 is to round up)

var HostArr: [1..n] int;          // allocates 'HostArr' on the host
HostArr = 1;                      // executes on the (multicore) CPU

on here.gpus[0] {
  for chunk in chunks(1..n, numSlices) {
    var DevArr: [chunk] int;      // allocates 'DevArr' on the device

    DevArr = HostArr[chunk];      // copies a slice from host to device
    DevArr += 1;                  // executes on the device as a kernel
    HostArr[chunk] = DevArr;      // copies from device to a slice on host
  }
}

writeln(HostArr);                 // prints "2 2 2 2 2 ..."
