use IO, Time, Map, Sort;

config const filename = "measurements.txt";

var mins, maxes, sums, counts: map(bytes, real);
var watch: stopwatch;

watch.start();

var reader = open(filename, ioMode.r).reader(locking=false);
var ct: cityTemp;
while reader.read(ct) {
  const (city, temp) = (ct.city, ct.temp);
  if !mins.contains(city) {
    mins[city]   = max(real);
    maxes[city]  = min(real);
    sums[city]   = 0;
    counts[city] = 0;
  }
  mins[city]   =  min(temp, mins[city]);
  maxes[city]  =  max(temp, maxes[city]);
  sums[city]   += temp;
  counts[city] += 1;
}

watch.stop();

// Report results
var cities = mins.keys();
sort(cities);
for city in cities {
  writef("%20s: %7.1dr %7.1dr %7.1dr\n",
         city.decode(), mins[city], sums[city] / counts[city],  maxes[city]);
}
writeln("elapsed time: ", watch.elapsed());

record cityTemp: readDeserializable {
  var city: bytes;
  var temp: real;

  proc ref deserialize(reader: fileReader(?), ref deserializer) throws {
    this.city = reader.readThrough(b";", stripSeparator=true);
    this.temp = reader.read(real);
    reader.readNewline();
  }
}
