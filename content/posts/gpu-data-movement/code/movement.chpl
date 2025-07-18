var HostArr: [1..5] int;   // allocates 'HostArr' on the host
HostArr = 1;               // executes on the (multicore) CPU

on here.gpus[0] {
  var DevArr: [1..5] int;  // allocates 'DevArr' on the device

  DevArr = HostArr;        // copies values from host to device
  DevArr += 1;             // executes on the device as a kernel
  HostArr = DevArr;        // copies values from device to host
}

writeln(HostArr);          // prints "2 2 2 2 2"
