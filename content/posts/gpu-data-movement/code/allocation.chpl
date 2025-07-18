var HostArr: [1..5] int;   // allocates 'HostArr' on the host
HostArr = 1;               // executes on the (multicore) CPU

on here.gpus[0] {
  var DevArr: [1..5] int;  // allocates 'DevArr' on the device
  DevArr += 1;             // executes on the device as a kernel
  writeln(DevArr);         // prints "1 1 1 1 1"
}

writeln(HostArr);          // prints "1 1 1 1 1"
