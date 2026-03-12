use List;
use Random;

var rs = new randomStream(real, 123456);

record point {
  var x, y: real;
}

proc point.distanceTo(other: point) do
  return sqrt((other.x - this.x)**2 + (other.y - this.y)**2);

proc main() {
  var points: list(point);
  for 1..10 do
    points.pushBack(new point(rs.next(-10.0, 10.0),
                              rs.next(-10.0, 10.0)));
  writeln("points: ", points);
  for i in 0..<points.size {
    for j in 0..<points.size {
      if i == j then continue;
      var d = points[i].distanceTo(points[j]);
      writef("distance between %? and %? is %n\n",
              points[i], points[j], d);
    }
  }
}
