// Advent of Code 2022, Day 12: On the Summit
// authors: ["Jeremiah Corrado"]
// summary: "A solution to day twelve of AoC 2022, covering atomic variables and recursive task parallelism"
// tags: ["Advent of Code", "How-To"]
// series: ["Advent of Code 2022"]
// date: 2022-12-19


/*

  Welcome to the final day of our 'Twelve Days of Chapel AoC' series! For some
  background on this series, check out the [introductory article]({{< relref aoc2022-day00-intro >}}).
  You can also click the `Advent of Code 2022` tag above to see all the other
  articles from this series.

*/

/*

  ### The Task at Hand and My Approach

  In [today's challenge](https://adventofcode.com/2022/day/12),
  our protagonist is about to embark on a hiking journey through the jungle
  to rendezvous with the elves, but first we need to plan an efficient route!

  The trusty handheld device given to us on [day 6](https://adventofcode.com/2022/day/6)
  provides a topographic map of the surrounding landscape in the form of a grid
  of lowercase letters. In this map, `a` represents the lowest elevation, and `z`
  represents the highest. From the starting position, marked by an `S`, we are
  tasked with finding the length of the shortest path to the top of a nearby
  hill — marked with an `E`. Additionally, the possible paths through the terrain
  are limited by our character's climbing abilities. We can only follow paths
  where the elevation increases by one step, or decreases by any number of steps,
  between adjacent grid points.

  To solve this problem, I split it into two major parts:

  1. reading the height-map into a numerical 2D array where each letter is
    mapped to an integer (`a`->`0` and `z`->`25`) that represents the
    elevation at that point
  2. applying a recursive task-parallel search algorithm to the map to find the
    shortest path from `S` to `E`

  The following sections will cover the implementation of both parts in detail.
  If you've been following this series so far, you've probably seen ample
  discussion of the concepts shown in the IO section. If that's the case,
  please feel free to skim or skip ahead.

  In the second step, I'll first describe a serial implementation of the
  search algorithm to give a clear sense of how it works. I'll then explain
  how we can use Chapel's *task-parallel* features and *atomic variables*
  to easily create a parallel implementation of the same algorithm.

  **For those who like to watch the movie before reading the book, here is the
  full code:**
  {{< whole_file_min >}}

*/

/*

  ### Reading the Elevation Map

  To handle the IO portion of the puzzle, I write a procedure called
  `readElevations` that parses the raw-text input, as in the following sample
  case:
  ```bash
  Sabqponm
  abcryxxl
  accszExk
  acctuvwj
  abdefghi
  ```

  It returns a three-tuple containing the following items:

  1. a 2D array with the elevation of each grid point represented as a
      numerical value from 0–25
  2. a two-tuple with the coordinates of the starting position
  3. a two-tuple with the coordinates of the ending position

  To start out, I define the header of the procedure and `use` the `IO` module
  just inside:

*/

proc readElevations() {
  use IO;

/*

  As a reminder from the [8th day]({{< relref "aoc2022-day08-treehouse#reading-the-forest-input" >}})
  in this series, placing a `use` statement inside the body of a procedure
  like this will make the symbols from that module available within the
  procedure's scope only. The same is true for some other scopes, such as
  iterators or plain old curly-braces (i.e., `{ use IO; ... }`).

  For this program, I've confined all the IO operations to the
  `readElevations` procedure, so it makes sense that `IO`'s symbols
  only be accessible from within it.

  Next, I define some `param`s to represent the numerical ASCII values
  of a few important characters. See [day 3's article]({{< relref "aoc2022-day03-rucksacks#chapel-params" >}})
  for more on `param`s.

*/
  param a = "a".toByte(),
        S = "S".toByte(),
        E = "E".toByte();

/*

  The value of lowercase `a` will be used to map the input characters to
  their numerical representations. Uppercase `S` and `E` will be used to
  locate the starting and ending positions in the 2D array.

  Note that I also could have looked at an [ASCII table](https://en.wikipedia.org/wiki/ASCII#Printable_characters),
  and hard-coded the values instead:
  ```chapel
  param a: uint(8) = 97,
        S: uint(8) = 83,
        E: uint(8) = 69;
  ```
  However, the original approach tends to be less error-prone and more
  self-documenting.

  With those `param`s set up, I'll read the lines of the input into an
  array of strings, and then compute the size of the grid:

*/

  const elevLines = stdin.lines().strip(),
        grid = {0..<elevLines.size, 0..<elevLines.first.size};

/*

  This code makes use of the `lines` iterator, which yields one
  line of text from the input at a time in the form of a `string`. I then call
  the `strip` method on each of those strings to remove their trailing
  newline characters. Because I've assigned the iterator call directly to
  a variable, Chapel will implicitly create a 0-indexed array with one entry
  for each iteration. As such, `elevLines` will contain an array of strings;
  one for each line of the input.

  This is very similar to the approach taken to parse the input in
  [day 10's article]({{< relref "aoc2022-day10-crt#an-iterator-to-represent-operations" >}}).

  On the second line, I query the size of the array to get the height of the map
  and the size of the first line to get the width. Both values are then used
  to define a 2D `domain` called `grid`. This domain represents all the
  pairs of indices that comprise the elevation map (for more information
  about `domain`s, check out the article from [day 8]({{< relref "aoc2022-day08-treehouse#domains-first-class-index-sets" >}})
  of this series).

  And now I use `grid` to define a numerical elevation array called `elevs`
  (not to be confused with *elves*):

*/

  var elevs = [(i, j) in grid] elevLines[i][j].toByte() - a;

/*

  This array initialization syntax is composed of two major parts:

  The leftmost portion, `var elevs = `, tells Chapel that I want to
  store the result of the expression on the right in a variable named
  `elevs`.

  In the middle of this line, `[(i, j) in grid]` indicates that I want to
  initialize an array whose elements are defined by the indices in `grid`.
  In other words, the array will use `grid` as its domain, and each of its
  elements will be defined in terms of some expression (to the right) that
  can use the values `i` and `j`.

  To the right, I use these indices to pull out individual characters
  from `elevLines`. Specifically, this code takes the `j`th character of
  the `i`th line, converts it to a byte, and then subtracts the special
  `a` value from that byte.

  This has the effect of mapping `a = 0`, `b = 1`, and so on, up to
  `z = 25` (note that the ASCII values of the lowercase letters are
  all consecutive integers). The only characters that won't be represented
  correctly in `elevs` are the `S` and `E`.

  Those values are located using the following *maximum-location ('maxloc')
  reductions* :
*/

  const (_, start) = maxloc reduce zip((elevs == (S - a)), grid),
        (_, end)   = maxloc reduce zip((elevs == (E - a)), grid);

/*

  The `maxloc` reduction takes a zippered pair of iterable expressions with
  compatible size and shape. Here, the first argument to `zip` is the set
  of values over which we want to find a maximum, and the second argument
  is the set of indices we'll use to define the location of that maximum value.

  Both the maximum value and its location are returned in a two-tuple. Here,
  I don't actually need the value itself, only its location in `grid`, so I
  choose not to store it in a variable by putting an underscore (`_`) in its
  place.

  More on `maxloc` can be found in [day 6's post]({{< relref "aoc2022-day06-packets#putting-it-all-together" >}})
  or in the [documentation](https://chapel-lang.org/docs/primers/reductions.html#maxloc-and-minloc-reductions)

  In both of these lines, I am applying the reduction to a promoted array
  expression. The first expression: `elevs == (S - a)` {{< sidenote "right" "creates" >}}
    Chapel is smart enough to avoid actually creating this array. Instead
    it will provide it to the reduction as an iterator in order to save
    memory.
  {{< /sidenote >}} an array of boolean values where the only `true` entry
  should be the location of `S`. Note that we are checking against `S - a`,
  rather than `S`, because we already subtracted the ASCII value of `a`
  from all entries in the elevation array.

  Chapel defines `true` to be greater than `false`, so `maxloc` will find
  the location of `S`, storing it in `start` as a two-tuple of coordinates. The
  reduction to find the ending position works in a similar manner. With these
  locations, I can set the proper elevations for the starting and ending
  positions, as defined by the problem:

*/

  elevs[start] = 0;
  elevs[end] = 25;

/*

  And now we have everything we need from the input text, so the relevant values
  are returned from the procedure in a three-tuple:

*/

  return (elevs: int(8), start, end);
}

/*

  In the process we cast `elevs` to a *signed* array of 8-bit integers using a
  promoted cast operation (`: int(8)`). When initialized, `elevs` was assigned
  with the type: `[grid] uint(8)`, meaning that it contained *unsigned* 8-bit
  integers (this is because `toByte()` returns a `uint(8)`); however, signed
  integers will be more convenient for subtractions later on, so I apply a cast
  here (note that this involves an extra array allocation, so defining `elevs`
  as an array of `int(8)` to begin with may be a more efficient strategy for
  larger problems).

  Next, I'll discuss how to use the data extracted from the input text to find
  the shortest path from start to end!

*/

/*

  ### Searching for the Shortest Path

  As a reminder, the goal of this step is to find the length of the shortest
  possible path from `S` to `E`, where the set of possible paths is
  constrained by the elevation changes in the landscape. A path can only go
  from one space to another if the elevation of the destination is at most
  one step higher than the elevation of the current space.

  To facilitate a search over the possible paths, I'll define an `explore`
  procedure which starts at one space in the map, and attempts to explore the
  four surrounding spaces. If an adjacent space is too high (or sits outside
  the bounds of the map), it will be ignored. Otherwise, `explore` will be
  called on that neighboring space, and the search will continue
  until `explore` is called on the `end` space.

  This approach falls under the category of a *recursive tree search
  algorithm*. It's [*recursive*](https://en.wikipedia.org/wiki/Recursion_(computer_science))
  because the principal function repeatedly calls itself until some terminating
  condition is met (in this case, `explore` stops calling itself when the search
  reaches the `end` space). It's a *tree search*, because at each node (or grid
  space) there are multiple "branches" that the path could take next (here:
  *up*, *down*, *left*, and *right* are the possible options).

  Very roughly, `explore` will look something like this (many details are
  omitted here):

  ```chapel
  proc explore(pos, end, elevations, pathLength): int {
    if pos == end then return pathLength;

    var shortest = max(int);
    for nextPos in nextPositions(pos, elevations) do
      shortest = min(shortest, explore(nextPos, end, elevations, pathLength + 1));
    return shortest;
  }
  ```
  where `nextPositions` is an iterator I'll define later that provides all the
  possible next steps taking into account the elevation constraint and the
  borders of the map.

  At a high level, this simplified version of `explore` does two things:

  1. If `pos` is at the `end`, it returns the total length of the path that got
    us here. Notice that each call to `explore` increments `pathLength`
    by `1`, so by this point its value will be the total number of
    explorations required to traverse the path.
  2. Otherwise, starting from `pos`, it explores all the neighboring spaces
    that can be explored, and returns the shortest resulting path.

  The net result is that calling `explore` with `start` as the first argument
  should eventually return the shortest path to `end`.

  However, there are a few challenges with this approach that are not addressed
  in the dummy implementation above:

  1. We need some mechanism to keep track of paths that have already been tried
    so that our search doesn't end up going in circles. For example, starting
    from some space $x$, `explore` could be called on the space to its *right*,
    which could then immediately call `explore` to its *left* — bringing the
    search back to $x$ without making any progress towards the `end`.
  2. The number of possible paths is huge, so we'll want to terminate
    branches of the search early whenever we know that they aren't going
    to beat the record for the shortest path — a technique called [pruning](https://en.wikipedia.org/wiki/Decision_tree_pruning).
  3. We should be able to process search paths in parallel across multiple
    threads to speed up the search process — this is a good opportunity to
    make use of some of Chapel's parallel features that have not been
    explored in this series so far.

  In the following section, I'll describe how the first two challenges are
  addressed in a complete serial implementation. After that, I'll show a
  parallel code that addresses all three.

  #### The Serial Search Algorithm

  I use a single mechanism to solve the first two problems described above:
  instead of directly returning the minimum of the search branches, I'll
  allocate a 2D array that keeps track of the shortest known path-length to
  each location in the map.

  This array will be queried and updated over the course of the search. For
  convenience, I create the following `findShortestPath` procedure that sets
  this up:

  ```chapel
  proc findShortestPath(const ref elevs: [?d] int(8), start, end) {
      var minDistanceTo: [d] int = max(int);
      explore(start, end, elevs, minDistanceTo, 0);
      return minDistanceTo[end];
  }
  ```

  {{< details summary="**(what does `const ref` mean?)**" >}}

  This is an example of an [argument intent](https://chapel-lang.org/docs/language/spec/procedures.html#argument-intents).

  It indicates that the formal `elevs` must be taken by reference (hence
  `ref`) — meaning that the variable won't be copied or moved into the
  procedure when `findShortestPath` is called — and that it cannot be
  modified by `findShortestPath` (hence `const`). Since `elevs` is an array,
  the default argument intent is `ref`, meaning that I also could have simply
  written `const` instead; however, I decided to write the full `const ref`
  for documentation purposes.

  {{< /details >}}

  {{< details summary="**(what does `: [?d] int(8)` mean?)**" >}}

  This is a type specifier — and a fairly advanced one at that.

  It indicates to the compiler (and to anyone reading the code), that
  this procedure will only accept an array of `int(8)` as its first
  argument. That's the `: [] int(8)` portion.

  The `?d` is called a type-query. In this case, it queries the
  array's `domain` and stores its value in a symbol called `d`. This
  makes it easy to reuse `d` in the body of the procedure to define
  `minDistancesTo` over the same set of indices as the `elevs` argument.

  An alternative would have been to omit the `?d` and query the `domain`
  directly in the procedure's body:
  ```chapel
  proc findShortestPath(const ref elevs: [] int(8), start, end) {
    var minDistanceTo: [elevs.domain] int = max(int);
    // ...
  ```

  {{< /details >}}

  The array `minDistanceTo` is initialized to have the maximum integer value
  for all elements. The rationale behind this is the same as in the dummy
  implementation of `explore` above: the starting minimum value is initialized
  to `max(int)` so that essentially any value we compare with it becomes
  the new working minimum.

  After exploration is complete, the `minDistanceTo` array will be populated
  with the shortest path from `start` to each location in the map (more on
  how I accomplish this shortly). The value of this array at the `end`
  location is the solution to our problem, so the procedure returns that
  value.

  As you might have noticed, we are now passing five arguments to `explore`,
  whereas the dummy version I defined above only took four arguments. Here is
  the actual implementation of `explore` that makes use of `minDistanceTo`
  (shortened to `minTo` within the procedure's scope):

  ```chapel
  proc explore(
      pos: 2*int,
      end: 2*int,
      const ref elevs: [?d] int(8),
      ref minTo: [d] int,
      pathLen: int
  ) {
      // stop searching if we've reached 'end'
      if pos == end then return;

      // stop searching if another path has reached 'end' in fewer steps
      //  than we've taken so far
      if pathLen >= minTo[end] then return;

      // otherwise, explore the next positions
      for nextPos in nextPositions(pos, elevs, minTo, pathLen + 1) do
          explore(nextPos, end, elevs, minTo, pathLen + 1);
  }
  ```

  Like the simplified implementation above, the terminating condition:
  `if pos == end then return` is used to stop searching when a path has
  reached the `end`; however, the path length is not returned directly.
  Instead, `minTo[end]` will be modified by reference in the `nextPositions`
  iterator — more on this momentarily.

  The next conditional: `if pathLen >= minTo[end] then return;`, takes
  care of the pruning concern mentioned above. The logic behind this check is
  as follows: suppose that this particular branch of the search has made `40`
  steps so far (i.e., `pathLen=40`); however, some other branch has already
  reached `end` in `35` steps (i.e., `minTo[end]=35`). In this case, we know
  that it's impossible for the current path to be the shortest, thus `explore`
  returns early so that the computer can use its resources for other paths.

  Additionally, notice that the `nextPositions` iterator is used in a similar
  manner as before, except I am not using a temporary variable to keep track
  of the shortest path. Again, this is because `minTo` will be updated with
  the shortest paths to each location as exploration progresses.

  Let's take a look at how `nextPositions` is implemented to see how that
  works:

  ```chapel
  iter nextPositions(pos, const ref elevs, ref minTo, nextPathLen) {
      // try moving in each direction
      for move in ((-1, 0), (1, 0), (0, -1), (0, 1)) {
          const next = pos + move;

          // is this move on the map and valid?
          if elevs.domain.contains(next) &&
              elevs[next] - elevs[pos] <= 1 {

              // does this path beat the shortest record to 'next'?
              if nextPathLen < minTo[next] {
                  minTo[next] = nextPathLen;
                  yield next;
              }
          }
      }
  }
  ```

  I start out by iterating over the possible moves: *up*, *down*, *left*,
  and *right* — each represented as a two-tuple. The next position will be
  the sum of the two-tuple and the current position. I store this value
  in `next`. Notice that I also passed `pathLen + 1` to the `nextPathLen`
  argument, meaning that `nextPathLen` represents the path length to `next`,
  not to `pos`.

  To check if the path to `next` will exceed the boundaries of the map, I
  simply query `elev`'s `domain` and use the `contains` procedure. This
  will return `true` if `next` is in the domain and `false` if it isn't.
  I also check if the elevation constraint is met by subtracting the
  elevation at `next` from the elevation at `pos`. If the difference is small
  enough, then we know that our protagonist can make the climb. If either of
  these conditions is not met, the iterator will continue on to the next
  `move` without yielding anything.

  Lastly, I check whether the path to `next` is shorter than the shortest known
  path to that location (i.e., if `nextPathLen < minTo[next]`). If it is,
  I update `minTo` with the new shortest path length and then yield `next`.
  Then, going forward, when other branches of the search read `minTo[next]`,
  they'll get the new shortest path length: `nextPathLen`.

  Notice that `next` is only yielded if this path beats the shortest-known
  path length. This solves the first challenge with my naive solution from
  the previous section because it prevents `explore` from starting searches
  down paths that are not an improvement on previous paths that have explored
  the same spaces.

  To summarize, this iterator does a few things: it yields the coordinates of
  the next locations that are valid moves—only if they result in an
  improvement on the best-known path lengths to those positions—and updates
  the best-known path lengths in the process. When called by the recursive
  `explore` procedure, it will eventually set the value of `minTo[end]` to
  the length of the shortest path.

  With the above procedures and iterator defined, we could solve the problem
  in serial as follows:

  ```chapel
  const (elevations, start, end) = readElevations();
  writeln(findShortestPath(elevations, start, end));
  ```

  #### Parallelizing the Search Algorithm

  As the problem size grows, the serial solution above will continue to work;
  however, the time it takes to find the shortest path will grow rapidly. Thus,
  in practice, problems like this are often solved in parallel by spawning a new
  task to handle each branch of the search tree. As tasks are created, different
  threads can take responsibility for each task, and work on separate portions
  of the search concurrently.

  Correctly implementing this form of concurrency will motivate the
  introduction of a new concept, namely *atomic variables*; however, to
  show why they are needed, let's first discuss what would happen if we
  altered the `explore` procedure to spawn new tasks for each branch without
  making any other changes to the code.

  Specifically, what would happen if we changed `explore`'s for-loop to spawn
  a new task for each of the next positions?

  #### Task Concurrency

  In Chapel, this is as simple as replacing `for` with `coforall`:
  ```chapel
  // explore the next positions in parallel
  coforall nextPos in nextPositions(pos, elevs, minTo, pathLen + 1) do
      explore(nextPos, end, elevs, minTo, pathLen + 1);
  ```

  A `coforall` loop is a task-parallel loop construct that spawns precisely
  one new task for each iteration of the loop. This is distinct from
  Chapel's `forall` loop which typically spawns one task per physical
  hardware thread and then breaks the loop's work up across each task.

  A much more detailed description of the `coforall` loop can be found in
  [yesterday's AoC article]({{< relref "aoc2022-day11-monkeys#chapels-coforall-loops" >}});
  however, the important point for our purposes is that the above code will
  execute each call to `explore` on its own task, allowing multiple threads
  to work on the search simultaneously.

  Due to the recursive nature of our approach, the number of spawned tasks
  will rapidly exceed the number of physical threads needed to execute them
  concurrently. As such, Chapel's runtime will manage the execution of those
  tasks in the background. Whenever a thread finishes executing a task, it
  will be provided with the next available task in the queue.

  Although this parallel code would execute faster than the serial version,
  it would not actually produce the correct answer (or would at least be
  very unlikely to do so). This is because we've failed to introduce any
  coordination between threads. Each will behave as if it has exclusive
  access to the `minTo` array even though this isn't actually true. This
  will cause threads to overwrite each other's work in a very haphazard
  manner, likely resulting in an incorrect solution.

  {{< details summary="**(an example of why coordination is necessary...)**" >}}

  Simply invoking a `coforall` in this situation will result in incorrect results
  because each thread will have the ability to read and modify the
  `minTo` array without coordinating with other threads. This problem comes
  up in a few places, but let's look at one in particular to understand what's
  going on.

  Consider the following code from the `nextPositions` iterator:

  ```chapel
  if nextPathLen < minTo[next] {
      minTo[next] = nextPathLen;
      yield next;
  }
  ```
  Imagine that there are two threads that arrive at this conditional at
  roughly the same time. Thread 1 has taken `31` steps to get here, thread
  2 has taken `33` steps, and `minTo[next] = 37`. Now, the following events
  transpire in order:

  1. thread 1 reads the value of `minTo[next]` and compares it with its local
      copy of `nextPathLen` (the result is `true`)
  2. thread 2 does the same, and the result is also `true`
  3. thread 1 writes the value `32` to `minTo[next]` (notice `nextPathLen = pathLen + 1`).
  4. thread 2 then **overwrites** `minTo[next]` with the value `34`

  This is a problem because the correct minimum path length at `next` is the
  smaller of the two values: `32`. However, because the two threads did not
  coordinate with each other, the value is now `34`. The correctness of the
  algorithm relies on `minTo` always holding the best-known minimum at each
  location, so now we can't trust the results going forward.

  {{< /details >}}

  As such, we'll need to introduce a mechanism to prevent separate tasks from
  interfering with each other when they are reading and writing to the same
  locations in memory (in this case, the `minTo` array).

  #### Atomic Variables

  This class of coordination problem is so fundamental in parallel computing
  that essentially all modern hardware exposes a set of mechanisms that
  allow threads to safely read and write to the same locations in memory at
  roughly the same time.

  One such class of mechanisms are referred to as *atomic operations*, or just
  *atomics*. The idea behind the name being that the operation is not divisible
  into its sub-components and thus, the memory that they operate on cannot be
  manipulated by another thread during the operation.

  In Chapel specifically, atomic operations are exposed in a nice abstract
  manner. Any variable of a primitive type can be declared as an
  [atomic variable](https://chapel-lang.org/docs/language/spec/task-parallelism-and-synchronization.html#functions-on-atomic-variables)
  by prepending the keyword `atomic` to its type declaration. For example,
  we can create an `atomic int` as follows:
  ```chapel
  var x: atomic int = 1;
  ```
  And now, the variable `x` will have access to a wide range of atomic operations.
  The important ones for our purposes are: [`read`](https://chapel-lang.org/docs/language/spec/task-parallelism-and-synchronization.html#Atomics.read)
  and [`compareExchange`](https://chapel-lang.org/docs/language/spec/task-parallelism-and-synchronization.html#Atomics.compareExchange).
  I'll provide a more detailed explanation of each as they come up.

  The essential takeaway for this program is that replacing some of our
  variables with their `atomic` counterparts will allow us to safely keep
  track of minimum path lengths across multiple threads simultaneously.

  I'll also note that Chapel provides another primitive to facilitate
  coordination across tasks. [*Synchronization variables*](https://chapel-lang.org/docs/language/spec/task-parallelism-and-synchronization.html#synchronization-variables)
  or *sync variables* expose a similar interface that could have also
  been used to solve todays challenge with task-parallelism.

  {{< details summary="**(Some notes on when to use `atomic`s vs. `sync`s...)**">}}

  In our solution to [day 11]({{< relref "aoc2022-day11-monkeys" >}}), we used Chapel’s
  synchronization variables where today we used its atomic variables. You
  might be wondering how to decide between these options when writing your
  own task-parallel programs given that, in most cases, either variable type
  can be used with just a bit of effort.

  In practice, we tend to think of `atomic`s as being best-suited for what we
  might call “optimistic” synchronization situations: cases where the chances
  of interference with other tasks are low; or where, even if there is
  interference, it will be brief and generally not block a task’s ability
  to proceed. This is a good characterization of today's problem, because
  as we'll see in the coming sections, two or more threads might attempt
  to update `minTo[next]` simultaneously; however, this interference is
  somewhat unlikely to begin with, and when it does occur, the conflict can
  be resolved rapidly.

  By contrast, `sync` can be thought of as more of a “pessimistic”
  synchronization concept since it can result in tasks blocking (if a
  variable's full/empty state is not as expected) or yielding to other
  tasks to permit forward progress and avoid deadlock or livelock.

  In yesterday’s simulation of monkeys, only one of the troop of monkeys
  was going to be able to proceed based on the given synchronization
  variable’s value, so — on average across the group of monkeys — there
  was no expectation that reading the synchronized value would return the
  current monkey’s ID.  As a result, it would make sense for the current
  monkey to yield and let other monkeys process their items. Yielding in
  this scenario was especially important when running a simulation with
  more monkeys than processor cores.

  One other difference between the two is that atomics are implemented
  using hardware, which generally comes with a performance advantage over
  syncs, which are typically not.

  Alternatively, the hardware implementation of atomics means that they
  are limited to working with a fixed number of simple scalar types, whereas
  syncs are supported for most types including user-defined `records` and
  `classes`.

  All that said, either atomics or syncs can both be made to work in most
  situations, sometimes using methods or routines that we haven’t covered
  in this series. We tend to reach for atomics in most cases where they
  apply due to their implementation in hardware and consequent performance
  advantages; but syncs provide a reasonable solution when needing to
  synchronize on non-scalar types, or in producer-consumer patterns where
  it may be best for tasks to block in order for the program to make forward
  progress.

  {{< /details >}}

  #### Parallelizing Search with `atomic`s

  Now I'll briefly go over the code used in my parallel solution to today's
  puzzle. Most of this code will be the same as the serial solution in the
  previous section, so I'll focus my explanation primarily on the differences
  between the two.

  First, I update the `minDistancesTo` array in the `findShortestPath` procedure
  to store `atomic int`s rather than traditional `int`s. This is as simple as
  changing the type in the array's declaration and returning the value we read
  from the atomic:

*/

proc findShortestPath(const ref elevs: [?d] int(8), start, end) {
  var minDistanceTo: [d] atomic int = max(int);
  explore(start, end, elevs, minDistanceTo, 0);
  return minDistanceTo[end].read();
}

/*

  Now, values in this array have access to the `read` and `compareExchange`
  methods which will be used later on. Note that the return type of this
  procedure has implicitly changed from `int` to `atomic int` because
  the last line is now accessing an `atomic` variable.

  Next, the `explore` method is also updated slightly. First, its header is
  changed to accept `minTo` as an array of `atomic int`s rather than `int`s:

*/

proc explore(
  pos: 2*int,
  end: 2*int,
  const ref elevs: [?d] int(8),
  ref minTo: [d] atomic int,
  pathLen: int
) {

/*

  Note that I didn't alter `elevs` to be an `atomic` array because it is
  never modified after it's created. The concurrent tasks spawned for the
  search will only ever read values from `elevs`, so we don't have to worry
  about one thread modifying its state while another is reading it.
  This fact is further denoted by the `const ref` intent which indicates
  that `explore` cannot modify `elevs`.

  The end condition is left unchanged; however, I do update the
  early-termination condition to call the `read` method on the minimum path length
  at `end`:

*/

  // stop searching if we've reached 'end'
  if pos == end then return;

  // stop searching if another path has reached 'end' in fewer steps
  if pathLen >= minTo[end].read() then return;

/*

  This is necessary because numerical comparison operators like `>=` are
  not available on `atomic int`s; therefore I first need to create a new `int`
  with the same value as `minTo[end]` by calling `read` on it.

  You may be wondering whether this check is valid since some other thread
  could come along and update `minTo[end]` between the time that this thread
  `read`s the value and compares it with `pathLen`. Such a concern is not
  invalid; however, we know that the values in `minTo` only ever get smaller.
  As such, the worst-case scenario here is that this early-termination
  condition is not met, but would have been met only an instant later. In
  such a case, some time is wasted on spawning more tasks that will
  ultimately be unfruitful; however, the correctness of the algorithm is
  not compromised. In other words, we can't be certain that some other task
  won't find and register a shorter path after our check, but we also can't
  spend all our time waiting to see whether another task will do so because
  if all of the tasks are waiting for each other, none of them will make
  progress on the actual search.

  Next, I spawn new tasks for each subsequent call to `explore`, using the
  `coforall` loop discussed earlier:

*/

  // explore the next positions in parallel
  coforall nextPos in nextPositions(pos, elevs, minTo, pathLen + 1) do
      explore(nextPos, end, elevs, minTo, pathLen + 1);
}

/*

  And finally, I'll make some changes to the `nextPositions` iterator to
  properly handle coordination between tasks. Its header remains the same as
  the sequential implementation; however, I do change the for-loop over the
  four directions. Here, I add a `label` called `checkingMoves` to the loop:

*/

iter nextPositions(pos, elevs, minTo, nextPathLen) {
  // try moving in each direction
  label checkingMoves for move in ((1, 0), (-1, 0), (0, 1), (0, -1)) {
    const next = pos + move;

/*

  A `label` is a special annotation that allows control-flow operations
  like `break` and `continue` to refer to a specific loop rather than
  the nearest surrounding loop. More details about `label`s can be found
  in the [documentation](https://chapel-lang.org/docs/language/spec/statements.html#the-break-continue-and-label-statements),
  and the reason for this particular addition will be discussed below.

  The validity bounds and elevation checks remain unchanged:

*/
    // is this move on the map and valid?
    if elevs.domain.contains(next) &&
      elevs[next] - elevs[pos] <= 1 {

/*

  This last section of code is modified pretty significantly. At first
  glance, it looks like it could be doing something completely different than
  the simple `if nextPathLen < minTo[next]` check from the serial version:

*/

      // check if another path made it to 'next' in fewer steps
      //  if so, try the next direction
      //  otherwise, set minTo[next] = nextPathLen and then yield
      var minToNext = minTo[next].read();
      do {
          if nextPathLen >= minToNext then continue checkingMoves;
      } while !minTo[next].compareExchange(minToNext, nextPathLen);

      yield next;
    }
  }
}

/*
  However, this code has exactly the same effect, only it's safe for
  concurrent use. Let's break it down:

  * First, I define a temporary variable, `minToNext`, with the current
      value of `minTo[next]` by calling `read`. This value has type
      `int`, which allows us to compare it with other `int`s.

  * Next I'll use `minToNext` to check if this path length beats the
      record. I can't simply check whether `nextPathLen` is smaller than
      `minToNext` because its value could be changed by another thread
      while I'm checking. So, I'll have to do something a little fancier.

      Initially, I'd like to rule out the case where `nextPathLen` is
      actually larger than the minimum path length at `next`. In that
      case, I just want to continue on to the next `move` instead of yielding
      `next`. This is what the body of the do-while loop is designed to do.

      If the value is too large, then I `continue checkingMoves`.  I can't
      just say `continue` here because that would only continue to the next
      iteration of the do-while loop—having no effect. Thus, I use the
      aforementioned `label` on the outer for-loop to explicitly `continue`
      there.

  * Now, looking at the terminating condition for the while loop itself:
      I use a [compare and exchange](https://en.wikipedia.org/wiki/Compare-and-swap)
      operation, which can do one of two things in this case:

      1. if `minTo[next] == minToNext`: update the value of `minTo[next]`
          to match `nextPathLen` and return `true`.
      2. if `minTo[next] != minToNext`: update the value of `minToNext`
          to match `minTo[next]` and return `false` `

      In the first case, I know that no other thread has updated the value
      of `minTo[next]` because `compareExchange` has confirmed that `minTo[next] == minToNext`
      is still true. As such, the new minimum value is put in its place; hence
      the *exchange* portion of `compareExchange`. The function also returns
      `true`, so the program leaves the do-while loop and moves on to yield
      `next`.

      In the second case, the values don't match, so I know that another
      thread updated the value while I was executing the body of the do-while
      loop. As such, `compareExchange` kindly replaces `minToNext` with the
      updated value, and I use it to run the check again. This loop keeps running
      until the first case is met (`minTo[next]` is updated with this task's
      smaller value), or until it `continue`s on to the next iteration of the
      outer for-loop.

  In summary, this compare-and-exchange loop has the same effect as the
  serial code. It either updates `minTo[next]` with a smaller path
  length and yields `next`, or it continues checking the subsequent `move`.

  And that's the end of the parallel implementation! Now we can call our
  two primary procedures to find the shortest path in parallel:

*/

const (elevations, start, end) = readElevations();
writeln(findShortestPath(elevations, start, end));

/*

  ### Conclusion and Tips for Part 2

  In summary, this post discussed a serial and parallel implementation
  of a recursive tree search algorithm used to find the shortest path
  through a topographic map. Along the way we reviewed some IO concepts
  from previous posts, discussed recursion and task concurrency, and
  introduced a new concept: `atomic` variables.

  The full parallel code can be downloaded from the top of the article
  or found on [GitHub](https://github.com/chapel-lang/chapel/blob/main/test/studies/adventOfCode/2022/day12/jeremiah/day12a-par-alt.chpl);

  In part two, you are asked to find the shortest path from *any* location
  with an elevation of `a` to `E`. This might sound like it would add a
  layer to the problem (i.e., run a separate search for each `a` in
  the map, and minimize over the shortest path from each); however, the
  algorithm shown above can be adjusted to simply set `minTo[pos]` to zero
  whenever `pos` has an elevation of `0`. This will have the effect of
  moving `S` to whichever `a` is closest to `E`. You could also run a
  reverse search, starting from `E` and ending whenever any `a` is
  encountered.

  With that we've concluded the 12th and final entry in our 'Twelve Days of
  Chapel AoC' series! Thanks for reading, and I hope you'll check out the
  other 11 posts from this series if you haven't already. As always, please
  feel free to leave questions or comments about this post in the Blog Category
  on Chapel's [Discourse Page](https://chapel.discourse.group/c/blog/).

  ### Updates to this article

{{< changetable >}}
  | Date         | Change                                                      |
  |:-------------|:----------------------------------------------------------------------------------|
  | Feb 5, 2023  | Updated `findShortestPath()` to return the value stored in the `atomic` |

*/
