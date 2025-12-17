proc main() {
  var arr = [i in -9..9] i,
      s1 = sliceToString(arr, -5..#6),
      s2 = sliceToString(arr, 0.. by 2 # 6),
      s3 = sliceToString(arr, 5..#5 by -1);
  writeln("Slice 1: ", s1);
  writeln("Slice 2: ", s2);
  writeln("Slice 3: ", s3);
}

proc sliceToString(arr, slice) {
  var s: string;
  for i in slice {
    s += arr[i]:string + " ";
  }
  return s.strip();
}
