use Time, Sort, Random;

config const n = 100_000_000;

// Declare a person record, which is a bit like a 'struct' in C
record person {
  var userId: int;  // note: 'int' in Chapel is the same as 'int(64)'
  var groupId: int;
}

// Declare a comparator which we'll use to tell the sort how to
// order the person records
record peopleComparator : keyComparator {
  proc key(a: person) {
    return a.userId;
  }
}

// Create a random number generator that we'll use to fill in the records
var rng = new randomStream(eltType=int(64));

// Declare an array storing n person records and initialize it with records
var A: [0..<n] person =
  [x in rng.next({0..<n})] new person(userId=x, groupId=x*x);

// set up timing for the sort
var timer: stopwatch;
timer.start();

// run the sort itself and provide a custom comparator
sort(A, comparator=new peopleComparator());

// finish timing the sort and print the result
timer.stop();
writeln("Sorted ", n, " elements in ", timer.elapsed(), " seconds");
writeln(n/timer.elapsed()/1_000_000, " million elements sorted per second");

/*
{{< changetable >}}
| Date         | Change                                                      |
|:-------------|:------------------------------------------------------------|
| Sep 27, 2024 | Updated to reflect custom `comparator`-related changes in Chapel 2.2 |
*/
