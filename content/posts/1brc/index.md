---
title: "Parallel Processing of a Billion Rows of Data in Chapel"
tags: [Benchmarks, I/O, Parallel I/O, Performance, Language Comparison]
summary: "A Chapel Implementation of the One Billion Row Challenge"
date: 2024-07-12
authors: ["Andy Stone"]
weight: 80
---

The need to analyze large datasets shows up everywhere: from scientific
research to insurance risk analysis to modeling in healthcare, market research,
economics, finance, and elsewhere.  Regardless of the field, a common task is
to scan through a large dataset, often stored in something like a CSV file, and
process it — for example, by finding averages, running sums, etc.  This type of
computation has shown up recently in a viral coding competition called the
"[One Billion Row Challenge](https://github.com/gunnarmorling/1brc)" (1BRC).
In this blog post, we focus on creating a straightforward, yet parallel,
implementation of the 1BRC in Chapel to execute on a multicore machine.

The goal of the 1BRC is to read data from a file that (aptly enough) contains
one billion rows of temperature data, consisting of pairs of weather station
names and temperature values. As the data is read in, it is aggregated to find
the min, max, and average temperatures for each weather station.

On the [official GitHub page](https://github.com/gunnarmorling/1brc), the
challenge has contestants submit Java-based implementations.  These
implementations are evaluated in terms of their execution times, but to remove the cost
of I/O overhead, the data file is first loaded onto a RAM disk before starting
the timer.  Competitive implementations are able to complete the task in less
than 2 seconds, and do so by pulling every trick in the book: memory-mapping data,
avoiding all unnecessary string copies, writing custom hashmaps, writing custom
number parser functions with built-in assumptions that values have no more
than three digits, using Java's "Unsafe" API, etc.  These implementations are
clever and fascinating from a competitive-programming perspective. They
demonstrate that it is possible to write low-level "bare-metal" style code in
Java. That said, they're less interesting from a more practical perspective;
namely, they're difficult to read and don't demonstrate how easy and performant
it would be to use a given language to conduct this sort of analysis in
general.

So, rather than approaching this strictly from the competitive-programming
perspective, this blog post tries to stay practical. I/O overhead is, of
course, a big concern in the "real world," so we'll consider it.  Let's start by
looking at a straightforward Python implementation of the 1BRC: a version that
is simple to implement and easy to understand.  Following that, we give a
simple Chapel version, and then adapt it using Chapel's parallel programming
features to eliminate overhead and improve performance.

But before we get into code, let's first discuss a bit more about the input
format. The challenge's input file consists of a billion rows of data, where
each row is in the format:

```
<string: station name>;<double: measurement>
```

For example, the first few lines of the file might look like this:

```
Tel Aviv;15.6
Hong Kong;51.4
Dikson;-15.4
London;-4.0
Entebbe;7.6
Hong Kong;51.4
Port Moresby;16.2
Assab;35.6
Lusaka;26.6
```

Station names may repeat. The task is to calculate the minimum, maximum, and
average temperature value for each weather station.  The output should sort the
station names and report these values, looking something like this (where
for each station, the first number is the minimum temperature, the second the
average, and the third the maximum):

```
       Abha:   -22.1    18.0    56.3
    Abidjan:   -17.3    26.0    67.8
     Abéché:    -7.9    29.4    71.9
      Accra:   -18.5    26.4    63.0
Addis Ababa:   -23.2    16.1    58.4
```

### Writing a straightforward Python version

If someone were given this task for a work or school assignment, they might
start by writing a non-performant, albeit simple serial version of the 1BRC.
Many programmers are familiar with Python, so let's start there.  In Python, you
might write this:

{{< file_download fname="1brc.py" lang="python" >}}

This program is simple and easy-to-read. It uses Python's CSV parser to read
the data, changing the separator from a comma to a semi-colon.  We store
running results into dictionaries with the keys being the names of temperature
stations and the values the current value.  The first time we encounter a city
we populate the dictionary with "identity" values that will be replaced when we
process the city's temperature.  To calculate averages, we need to keep a
running sum of temperatures as well as a count of how many entries exist for a
given weather station.  At the end, we sort and print out our results with a
calculated average.

### Writing a serial Chapel version

Now, let's try doing the same in Chapel:

{{< file_download fname="1brc_serial.chpl" lang="chapel" >}}

The Chapel implementation isn't quite as compact as the Python version,
though it is still fairly straightforward.

One notable difference is that in the Chapel version, we represent the data
read in from the file in a special `cityTemp` record.  We supply this record
with a `deserialize` method that specifies how to read the value from a file.
For more information about deserializers see this [technical
note](https://chapel-lang.org/docs/technotes/ioSerializers.html).

When running the Python and Chapel versions, we can already see a difference in
terms of performance. On a 64-core (AMD EPYC 7513) machine, the Python version
takes 1312 seconds (21&nbsp;minutes, 52 seconds) while the serial Chapel version
takes 908 seconds (15 minutes, 8&nbsp;seconds).  Both versions are running in serial,
though, so despite running this on a beefy 64-core machine, we're only using one
of its cores.

{{< figure src="./python-v-serial.png" >}}

### Writing a parallel Chapel version

Now let's try and make better use of our hardware and make the Chapel version
faster by introducing parallelism. 

Given the large size of the input file, it makes sense to read and process its data
in parallel.  We would like each task to process whole, unsplit, lines of
data, but figuring out the exact byte-offset to split the file up can be
difficult.  Thankfully, Chapel has a
[`ParallelIO`](https://chapel-lang.org/docs/main/modules/packages/ParallelIO.html)
module that can handle these details for you.

Using the `ParallelIO` module, one simple approach would be to read all the rows of
the file in as an array, and then use a `forall` loop to iterate through that
array in parallel.  This can be quite easily expressed as:

```chpl
var cityTemps = readItemsAsArray(filePath=filename, delim="\n", t=cityTemp);
forall ct in cityTemps do ...
```

An even better approach would be to avoid loading the entire file into memory
by processing it a line at a time, and this is possible using the `ParallelIO`
module's
[readDelimited](https://chapel-lang.org/docs/main/modules/packages/ParallelIO.html#ParallelIO.readDelimited)
iterator.

So, we could replace our original loop:

```chpl
while reader.read(ct) {
```

with:

```chpl
forall ct in readDelimited(filename, t=cityTemp) {
```

where the `t` argument specifies the type of data to load.  Note we're not
just changing from using the serial `read` method to the parallel
`readDelimited`, we're also changing from using a serial `while` loop to the
parallel `forall` loop. This approach will keep all our cores busy reading and
processing the file.

By itself, this is a pretty trivial change; but alas, if you try and compile it,
you'll soon run into an error:

```console
error: const actual is passed to 'ref' formal 'this' of addOrReplace()
note: to formal of type map(bytes,real(64),false)
note: The shadow variable 'mins' is constant due to task intents in this loop
```

The final note on the error is telling you that the `mins` map is constant within
the loop due to task intents.  In parallel loops (like `forall`), variables used
in the loop that come from outside the loop (like `mins` in this case) are
given a "task intent", which defines how the variable enters and can be used in
the loop.  For example, variables with `ref` intent can be modified in the loop
while variables with `const` intent cannot.  By default, objects like maps are
given `const` intent, since modifying the map in a parallel loop can lead to
bugs.

You might find this error annoying, but by defaulting to `const` intent, Chapel
saved us from accidentally introducing a potential bug, and not only that,
one of the worst kinds of bugs: a race condition.  Race conditions can be
particularly difficult to debug since, by definition, their behavior might not
be consistent from run to run.  We could silence the error message by giving
the map a `ref` intent using a `with` clause like this:

```chpl
forall ct in readDelimited(filename, t=cityTemp) with (ref mins)
```

But, unfortunately, silencing the error message doesn't remove that nasty race
condition. So what to do?  Well, Chapel has another map datatype that's meant
for concurrent updates like this: the `ConcurrentMap` type, so let's use that!

The way to do a parallel-safe update with `ConcurrentMap` is to use its
[update](https://chapel-lang.org/docs/modules/packages/ConcurrentMap.html#ConcurrentMap.ConcurrentMap.update)
method.  In our implementation, we'll call `update` like this:

```chpl
cityTempStats.update(ct.city, new updater(ct.temp), token);
```

In this case, `ct.city` is the key to update in the `cityTempStats` map.  But,
you may be asking, what's up with the `updater` and `token` arguments?

The `updater` argument takes an object that indicates how to update the key.
This object defines an updater method named `this` that takes a single argument of the element
type to update with.  We can create a simple updater to do our aggregation like
this:

```chpl
record updater {
  var temp: real;
  proc this(ref td: tempData) {
    td.min = Math.min(td.min, temp);
    td.max = Math.max(td.max, temp);
    td.total += temp;
    td.count += 1;
  }
}
```

And since our updater is a function that can update multiple values, for this
version, rather than have four separate maps for `min`, `max`, `total`, and
`count`, we'll instead store these values together in a single `tempData`
record and use a single `ConcurrentMap` object.

The `update` method also takes a token, which is a special value used to
coordinate between tasks.  We can get the task-specific instance of this token
by calling the `getToken()` method on `ConcurrentMap` and assigning it to a
task-specific variable in the `with` clause of our `forall` loop. Putting 
it all together looks like this:

```chpl
forall ct in readDelimited(fileName, t=cityTemp, delim="\n", nTasks=nTasks)
    with (var token = cityTempStats.getToken())
        do cityTempStats.update(ct.city, new updater(ct.temp), token);
```

And in its entirety, the program is:

{{< file_download fname="1brc.chpl" lang="chapel" >}}

And sure enough, this version blows all our previous results out of the water.
While the Python version took 1312 seconds (21 minutes, 52 seconds), and the
serial Chapel version took 908&nbsp;seconds (15 minutes, 8 seconds), when running
the parallel Chapel version on all 64 cores of this machine, it took only 24
seconds!

{{< figure src="./final-results.png" >}}

### Summary

In this post, we used the billion-row challenge to demonstrate Chapel's ability
to process a massive amount of data on a multicore machine in parallel.

Some key points to take away include:

* Chapel makes it easy to write a program to do parallel processing of a
  massive datafile.
* Chapel's `ParallelIO` module can be used to process the contents of a file in
  parallel.
  * To read in all the data in the file into an array, use
`readItemsAsArray`.
  * To iterate through the file in parallel, use a `forall` loop
and the `readDelimited` iterator.
* To aggregate data into a map, use Chapel's `ConcurrentMap` module.
  * Aggregation
logic is encapsulated in a special function object that has a `this` method
that takes a `ref` to the element of the map to update.

Given that Chapel supports distributed-memory parallelism in addition to the
shared-memory, multicore parallelism that we used here, it'd be interesting to
consider what a distributed version of this code would look like; but we'll
leave that question for another day.

Altogether, in this post, we focused on creating a straightforward, yet
parallel, implementation of the one billion row challenge in
Chapel. The resulting code executes in 24&nbsp;seconds on a multicore CPU, which is
orders of magnitude faster than a similarly straightforward Python
implementation.
