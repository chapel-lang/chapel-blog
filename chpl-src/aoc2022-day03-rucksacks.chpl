// Advent of Code 2022, Day 3: Rucksack Comparisons
// tags: ["Advent of Code", "How-To"]
// series: ["Advent of Code 2022"]
// summary: "A parallel solution to day three of AoC 2022, introducing ranges, `bytes`, forall-loops, and sets"
// authors: ["Brad Chamberlain"]
// date: 2022-12-03

/*

  Welcome to day 3 in our Chapel's Advent of Code 2022 series!  If
  you're just joining us, check out the previous articles in this
  series to:
  * [get the context]({{< relref "aoc2022-day00-intro" >}}) for what we're doing
  * [learn basic Chapel features]({{< relref "aoc2022-day01-calories" >}}) like declaring variables and constants
  * [learn about procedures and iterators]({{< relref "aoc2022-day02-rochambeau" >}})
  
  all of which we'll be relying on today.

  ### Today's Task and How I Approached It

  [Today's challenge](https://adventofcode.com/2022/day/3) is to read
  in a series of rucksacks, each represented by one line in a file.
  Each rucksack is a sequence of letters representing the items in
  that rucksack.  Each rucksack is also divided into two compartments
  of equal size—so the first half of each line is the first
  compartment and the second half is the second.  Our goal is to find
  the single item (letter) per rucksack that is contained in both
  compartments and convert that to a priority (numerical score), where
  `a`–`z` are scored as `1`–`26` and `A`-`Z` as `27`–`52`.  Then we
  sum all the priorities and print that as our result.

  **If you like your movies to be spoiled, here's my approach to part one that I'll describe here:**
  {{< whole_file_min >}}

  In today's program, I wrote a solution in which each rucksack's
  score is computed in parallel.  However, where yesterday's solution
  used implicit parallelism by promoting a procedure with an array,
  today I'll be using _forall loops_, which are a key workhorse for
  data-parallelism in Chapel.  Other features I'll introduce in this
  article include:

  * _ranges_ for representing regular sequences of integers and their use in _slicing_
  * the `bytes` type for representing raw byte strings
  * the standard library's `set` collection
  * unsigned integers and integers of specific bit-widths
  * `param` values to represent compile-time constants

  Also in today's blog, my code is organized in the way I prefer to
  write Chapel—top-down, so that the order of the code matches the way
  we'd read English and also (roughly) the order in which the code is
  executed.  I'll also provide a bit more detail about Chapel program
  structure and execution.

*/

/*

  ### Getting Started: Kicking off Execution

  My program starts, as most Chapel programs do, with a `use`
  statement that gives me access to some standard modules:

*/

use IO, Set;

/*

  The first is `IO`, which will be familiar to readers of this series:
  it provides the routines I'll use to read in the rucksack data.  The
  second is `Set`, which is a standard module providing a `set`
  datatype.  This is the first AoC program I've written that `use`s
  two standard modules, and you can see that they can be
  comma-separated rather than each needing a distinct `use` statement.

  Next, in my top-down coding style, I'm going to write the first
  statements that I want to execute when my program starts running:

*/


var Rucksacks = readRucksacks();
writeln(sumOfPriorities(Rucksacks));

/*

  The first statement calls an iterator that I've written to read in and
  yield the rucksacks.  The second calls a routine to compute the sum
  of the rucksacks' priorities, printing out the result.  All I have
  to do now is write those routines.

  {{< details summary="**(More on Chapel program structure and execution...)**" >}}

  Before going on, let's talk a bit more about how programs begin
  executing in Chapel.  As mentioned earlier in the series, if today's
  code was stored in a file named `day03.chpl`, it would introduce a
  module named `day03`.  I also stated that Chapel programs begin by
  initializing all of their modules, which includes any executable
  code defined at the module scope.  When we compile a program, like

  ```bash
  $ chpl day03.chpl
  ```

  and that file defines a single module, it is considered the
  program's _main module_.  In Chapel, the main module governs how the
  program executes.

  In this case, when I run the resulting program using `./day03`, the
  first thing that happens is that the `IO` and `Set` modules will be
  initialized, since our code relies on them due to its `use`
  statements (and, recursively, any modules that they `use` or
  `import` will also be initialized).  Next, our own module will be
  initialized, which involves running the two module-scope statements
  we've just seen.  All the other code in this file declares our
  subroutines, which are not executed until they are called.

  If you're coming from a more structured programming style and it
  seems odd to have filenames define module names or file-scope code
  be executed, Chapel also permits these things to be stated more
  explicitly.  For example, I could define all of this file's contents
  within an explicit `module` declaration to avoid relying on the
  filename, like this:

  ```chapel
  module day03 {
    // put the rest of this file's contents here
  }
  ```

  This would fix the name of the module regardless of whether I saved
  it in a file named `day03.chpl`, `day03-attempt2.chpl`, or
  `day03-why-isnt-this-working.chpl`.

  Then, instead of relying on module-scope code to execute, I could
  introduce a `main()` procedure, as in other languages, to contain
  the two statements from above that define how my program should
  start executing:

  ```chapel
  module day03 {
    proc main() {
      var Rucksacks = readRucksacks();
      writeln(sumOfPriorities(Rucksacks));
    }

    // put the rest of my subroutines here
  }
  ```

  Note that this module will still be initialized before `main()` is
  executed, it's just that there's no other executable module-level
  code, so nothing is required to initialize it.

  When writing large Chapel programs, this style of coding can be very
  useful to make the program's organization clear and explicit.
  However, when writing short programs, as in AoC, I typically tend to
  prefer the style I've been using because it feels more lightweight,
  like scripting.

  {{< /details >}}

*/

/*

  ### An Iterator for Reading Rucksacks

  As in [yesterday's solution]({{< relref "aoc2022-day02-rochambeau" >}}), I'm
  defining an iterator to read today's lines of input and yield them,
  such that `Rucksacks`, defined above, will be an array containing
  all of the input data.  Here's the first part of that iterator:

*/

iter readRucksacks() {
  var rucksack: bytes;

  while readLine(rucksack) {

/*

  As in my [day 1]({{< relref "aoc2022-day01-calories" >}}) solution, I'm relying
  on the `readLine()` routine from `IO` to read a line of input at a
  time.  However, where I read in `string` values on day 1, I'm
  reading in values of the `bytes` type here.  These two types are
  very similar.  Chapel strings are
  [UTF-8](https://en.wikipedia.org/wiki/UTF-8), which permits them to
  support a wide variety of international characters or _codepoints_.
  In contrast, `bytes` types are like a string of raw bytes, or 8-bit
  values.

  When working with ASCII data, as in this program, the reason I tend
  to use `bytes` values is that their operations can generally be
  implemented more efficiently.  That said, it would certainly be
  possible to take the same approach I did here using `string`s
  instead.

  {{< details summary="**(More on performance of `bytes` vs. strings...)**" >}}

  Both strings and bytes support indexing to extract a specific
  element, using the syntax `myStringOrBytes[i]`.  However, since
  strings are UTF-8, a naive implementation would have to walk through
  the string data consecutively to find the `i`th codepoint.  In
  contrast, `bytes` are made up of fixed-size bytes, so the `i`th byte
  can be accessed directly by the implementation, simply using math.

  Another difference is that indexing a `string` in this way returns
  a new string of length 1, whereas indexing a `bytes` returns a
  single byte—an 8-bit value.  While either would work for today's
  computation, the performance-minded programmer in me prefers doing
  most of my work using integers rather than strings since integer
  operations are supported natively by processors.

  Again, though, all that said, this program could have been written
  with strings, probably with very few changes to the code.

  {{< /details >}}

  Since we need to divide each rucksack into two compartments, I'm
  going to yield those compartments using a tuple, making `Rucksacks`
  an array of 2-tuples, similar to yesterday's array.  But where that
  program stored 2-tuples of enums, today I'll store 2-tuples of
  `bytes`.

  To split my rucksacks into compartments, I start by calculating the
  midpoint of each one after reading it:

*/
    const len = rucksack.size-1,
          mid = len / 2;
/*

  I first compute the length (`len`) of the rucksack by querying its
  `size`, subtracting one for the newline byte (`\n`).  Dividing that
  by two gives me the midpoint, `mid`.

  Then, to compute the two compartments, I use a Chapel feature known
  as _slicing_, in which a variable is indexed not using a single
  integer, but a sequence of them:

*/

    yield (rucksack[0..<mid], rucksack[mid..<len]);
  }
}

/*

  Though we've seen Chapel's ranges in passing, we haven't really
  discussed them much, so let me do a bit of that now:

  ### Ranges and Slicing

  In Chapel, a _range_ represents a regular sequence of integers.  For
  example `1..4` represents the integers `1`, `2`, `3`, `4`.  In this
  code (and on previous days) I've used _open-interval ranges_ which
  are written `lo..<hi`.  This excludes the upper bound from the
  range, similar to open intervals in math.  For example, `1..<4`
  would represent the integers `1`, `2`, `3`.  When counting from `0`,
  open-interval ranges are commonly used, in order to write `0..<n`
  rather than `0..n-1`.  As used here, open-interval ranges are
  admittedly syntactic sugar, but I find them easier to read.

  Certain types in Chapel, like arrays, strings, and `bytes` support
  indexing using a range to refer to a subset of their value(s).  For
  example, here, I'm slicing the rucksack `bytes` value that I just
  read with `0..<mid` and `mid..<len` to refer to the bytes
  representing the first and second halves.  The result of each slice
  is a new `bytes` value, and I yield these back to the callsite as a
  2-tuple.

  Note that Chapel's `bytes` values use 0-based indexing, as do all
  Chapel types for which the user does not specify indices.

  Ranges support a number of other queries and operations, like
  non-unit striding, and we'll likely come across some of those in the
  days to come.

*/

/*

  ### Forall Loops and Task Intents

  Though there is a way to write today's computation using promotion
  and implicit parallelism, like we did yesterday, my first thought
  happened to be to use a parallel loop.  And since my job is to teach
  you Chapel features, let's take a look at how I did it and then
  consider the promotion-based approach afterwards as an optional
  sidebar.

  In defining my `sumOfPriorities()` routine, my first thought was
  that I could iterate over all the pairs of compartments in parallel,
  computing their values independently and adding them up.  When
  looping over large data structures in Chapel, like arrays, the
  _forall loop_ is typically the best way to do it in parallel.  A
  `forall` loop essentially asserts that its iterations can be
  executed in any order, and that they _should_ be executed in
  parallel if possible.

  As an example, here's a simple forall loop in Chapel:

  ```chapel
  forall i in 1..1000 do
    writeln("Hello from iteration ", i);
  ```

  Semantically, the use of `forall` in this loop says "These 1000
  iterations can, and should, be executed in parallel."  In practice,
  `forall` loops are implemented by invoking the iterand expression's
  parallel iterator.  In this case, it would invoke the default
  parallel iterator method for the `range` type (which itself is
  implemented as Chapel code).  That iterator will create a number of
  tasks, divide the range's indices between them, and have each task
  compute its iterations in parallel.  If you compile and run this
  program, you will likely see the messages come out in a
  semi-arbitrary order, indicative of the parallelism.  If you use
  tools to monitor your system's CPU usage, you should also see signs
  of parallel computation, in terms of the processors' utilization.

  Without getting into too many implementation details, the tasks
  created to implement a `forall` loop are executed by the system's
  _threads_ which are typically mapped to distinct _processor cores_.
  For example, if my laptop had a 16-core processor, each of those
  cores would execute ~1/16 of the above loop's iterations in parallel
  with the other cores.

  In today's AoC computation, we want to use our loop to compute a sum
  of all the rucksacks' items' priorities.  Writing this as a simple
  for-loop, we might say:

  ```chapel
  var sum = 0;

  for (compartment1, compartment2) in Rucksacks {
    sum += ...;
  }
  ```

  That is, we'd iterate over our array of rucksacks, de-tupling each
  one into its two compartments, and then accumulate their priorities
  into a running `sum` variable using the `+=` operator.

  The problem with trying this same approach in a `forall` loop is
  that it can lead to what is known as a _race condition_ or _data
  race_.  These are a bit technical, so I'll describe them in a
  sidebar:

  {{< details summary="**(More on race conditions...)**" >}}

  As an example of a race condition, consider the following loop:

  ```chapel
  var sum = 0;

  forall i in 1..1000 do
    sum += i;
  ```

  This appears as though it might conceivably add up the integers from
  1 to 1000 in parallel.  However, since the iterations of this loop
  are potentially all executing in parallel, it is likely that
  multiple tasks will try to update `sum` simultaneously, which can be
  problematic.

  To see why, pretend that you and I are two tasks that have divided up
  the iterations between ourselves, and we are each executing our
  first iteration, such that I am trying to add the value `i=1` into
  the sum and you are trying to add the `i=501` case.  Here is how our
  operations might interleave in time::

  * You read `sum`, with the value of `0` into a register
  * I read `sum`, with the value of `0` into a register
  * You add `501` to your register, making it hold `501`
  * I add `1` to my register, making it hold `1`
  * You store your register back to `sum`, making it hold `501`
  * I store my register back to `sum`, making it hold `1`

  So where these operations should have resulted in `sum` holding
  `502`, the interleaving has caused my update to blow away your
  contribution without a trace.  Over the course of all the
  iterations, you can imagine this happening multiple times, where
  the fact that we're executing in an uncoordinated way causes us to
  each stomp on each others' contributions.  And with 4, 16, or 128
  tasks, the races are only more likely to occur.

  {{< /details >}}

  Happily, Chapel is designed to reduce the chances that users
  inadvertently create data races like these.  Specifically, if you were
  to try and compile the code above with version 1.28 of the Chapel
  compiler, you'd get the following error:

  ```bash
  testit.chpl:4: error: cannot assign to const variable
  testit.chpl:3: note: The shadow variable 'sum' is constant due to forall intents in this loop  
  ```

  What's happening here is that when an outer scalar variable, like
  `sum`, crosses over into a parallel construct, like a `forall` loop,
  the compiler creates a `const` copy of that variable called a
  _shadow variable_ for each task that is helping to run the `forall`
  loop.  Because the shadow variable for `sum` is `const`, it cannot
  be assigned and prevents you from accidentally creating a race.

  One way to fix this data race in Chapel is to use a variable type
  that supports coordinated accesses between parallel tasks—so-called
  _sync_ or _atomic_ variables.  However, today I'll use another
  approach related to the `reduce` expression we saw yesterday.
  Specifically, I'll apply a _reduce intent_ to the loop, as follows:

  ```chapel
  var sum = 0;

  forall i in 1..1000 with (+ reduce sum) do
    sum += i;
  ```

  This tells Chapel that instead of giving the tasks `const` copies of
  `sum`, it should give them their own modifiable copies.  Then, as
  the tasks complete their portions of the `forall` loop, Chapel will
  automatically combine their individual copies of `sum` together
  using `+`, leaving the result in the original `sum` variable.  Note
  that each task's copy of `sum` will be initialized to `0` (since
  that is the identity value for `+`), and that the original `sum`
  variable's value will also be accounted for in the final result (in
  this case, since it's `0`, it has no effect).

  Doing the same for our advent of code loop, we get the following:

*/




proc sumOfPriorities(Rucksacks) {
  var sum = 0;

  forall (compartment1, compartment2) in Rucksacks with (+ reduce sum) {
/*

  ### The `set` type

  Next, we need to compare the items (letters or byte values) stored
  within each of the two compartments to find the one that they share
  in common.  This is where the `Set` module comes in.

  The approach I took was to iterate over all of the byte values
  represented by the first compartment, storing each one's value into
  the set. Then, I iterate over the second compartment's byte values,
  looking for an item that is already in the set.

  Here's the declaration of my set:

*/
    
    var items: set(uint(8));

/*

  Chapel's standard `set` type is generic and parameterized by the type
  of values the set will store.  The `bytes` type represents the byte
  values that comprise it as 8-bit unsigned integers, which in Chapel
  is written `uint(8)`.  So the type specifier `set(uint(8))` defines
  `items` to be a set of 8-bit unsigned integers.

  Next we iterate over the first compartment:

*/

    for item in compartment1 do
      items.add(item);

/*

  The default iterator for the `bytes` type yields `uint(8)` values
  representing the individual byte values that comprise it.  So this
  loop simply iterates over those bytes, adding them into our set
  using the `.add()` method.  If we encounter duplicates, this is not
  a problem due the nature of the `set` type.

  Then, we can iterate over the second compartment similarly:

*/

    for item in compartment2 {
      if items.contains(item) {

/*

  Here, we're using the set's `.contains()` method to see whether the
  given `item` is already in the set.  If it is, we call a helper
  procedure to compute its priority and add it into our task's `sum`
  variable:

*/
        
        sum += itemToPriority(item);

/*

  Then, because the day's instructions assured us that the two
  compartments would only have one item in common, there's no real
  need for us to consider the rest of the items in the container, so
  we can break out of the `compartment2` loop using a `break`
  statement (in practice, the time saved here is probably negligible,
  given that the compartments are not very big...).

*/
        
        break;
      }
    }
  }

/*

  After breaking out of the loop, our task will continue on to the
  next pair of compartments that we own from the array of rucksacks,
  until we have completed all of our iterations.  Then, Chapel will
  ensure that our local copy of `sum` is added back into the original,
  due to the `reduce` intent.

  Once all tasks have completed their iterations, the `forall` loop
  is complete, and our routine can return the final `sum`:

*/
  
  return sum;
}

/*

  ### Promotion vs. `forall` loops

  As I was preparing to write up this article, I started looking into
  ways to refactor or clean up my code and found I could write the
  whole thing as a promotion, similar to yesterday's approach.  The
  choice between the two approaches is primarily stylistic and, as
  mentioned above, I stuck with the `forall`-based approach for this
  article because it's the first thing that occurred to me and gave me
  an opportunity to introduce one of Chapel's main parallel loop
  styles.  But in the following sidebar, I'll show how I arrived at
  the promoted version, for those who are interested (you may want to
  see if you can come up with it yourself first):

  {{< details summary="**(Converting my `forall` loop into a promotion...)**" >}}

  The thing that led me to the promoted version was wondering whether,
  in the loop nest above, it would be clearer if I were to move the
  comparison of the compartments into a helper function.  This
  led me to write the following helper procedure:

  ```chapel
  proc rucksacksToPriority((compartment1, compartment2)): int {
    var items: set(uint(8));

    for item in compartment1 do
      items.add(item);

    for item in compartment2 {
      if items.contains(item) {
        return itemToPriority(item);
      }
    }
    halt("We didn't find any items of overlap!");
  }
  ```

  Its body is almost identical to that of my `forall` loop except that
  I've changed the `break` statement and `sum` addition into a
  `return`.  I've also added a `halt()` to the end of the routine to
  avoid surprises and make the Chapel compiler stop complaining that I
  might not return anything if I reached that point.

  Note that I had my helper take a 2-tuple of compartments as its
  arguments, similar to yesterday's code.  This was so that I
  could move the de-tupling of my rucksacks from the `forall` loop
  to the call to the helper routine.  Here's the resulting version
  of `sumOfPriorities()`:

  ```chapel
  proc sumOfPriorities(Rucksacks) {
    var sum = 0;

    forall compartments in Rucksacks with (+ reduce sum) do
      sum += rucksacksToPriority(compartments);

    return sum;
  }
  ```

  Nothing new here, just a loop over an array, passing the elements
  to a helper routine and accumulating the sums.  But at this point,
  I realized that this was a lot of code to write where we could
  simply use a promotion and reduction instead.  Namely:

  ```chapel
  proc sumOfPriorities(Rucksacks) {
    return + reduce rucksacksToPriority(Rucksacks);
  }
  ```

  Or at this point, I could just rewrite my original `writeln()` as:

  ```chapel
  writeln(+ reduce rucksacksToPriority(Rucksacks));
  ```

  A very succinct and tidy expression of data parallelism!

  {{< /details >}}

  As mentioned at the outset, for this program, the choice between
  these approaches is primarily a matter of style, based on whether
  you prefer loops and explicit parallelism or promotion and implicit
  parallelism.  In fact, promoted procedure calls are implemented by
  the compiler using `forall` loops; and `reduce` expressions are
  implemented using `reduce` intents on those loops.  So they really
  are essentially equivalent.

  ### Computing Priorities using `param`s and `bytes`

  All that remains is to write the helper procedure to convert an item
  (a `uint(8)`) into its integer score.  The approach I took here
  relies on two properties of ASCII characters.

  The first is that the letters `A` through `Z` are consecutive ASCII
  values, as are the lowercase letters `a` through `z`.  However, note
  that there are other characters between each of these ranges.  The
  second, which I had to Google to remind myself of, is that the
  upper-case letters have lower ASCII values than the lower-case
  letters.

  I'll confess here that I can never remember the numeric values of
  ASCII characters despite having worked with them for decades.  So I
  wrote my code without the need to refer to those values directly,
  which also makes it more self-documenting.  Specifically, I started
  out my procedure by having Chapel compute the ASCII values of `"A"`,
  `"Z"`, and `"a"`, as follows:

*/

proc itemToPriority(item) {
  param A = b"A".toByte(),
        Z = b"Z".toByte(),
        a = b"a".toByte();

/*

  There are a few important new concepts here.  The first is the
  `param` keyword:

  ### Chapel `param`s

  In Chapel, a `param` is a value that is known to the compiler at
  compile-time.  As a simple example, the literal integer `42` is a
  `param` because the compiler knows its value, as are the literal
  string `"hello"` and the literal Boolean value `true`.  Like
  `const`s, `param`s cannot be re-assigned once they are initialized.

  For this routine, I chose to use a `param` because I knew that these
  ASCII values are well-defined constants that never change.  I also
  knew that they are values that the compiler could compute for me,
  for reasons I'll get to in a second.  So rather than hard-coding
  `65`, `90`, and `97` into my code (the ASCII values of these three
  characters—I just Googled it), I wanted to do the next best thing:
  Namely, have the compiler determine these values to avoid spending
  any time computing them when running my program.

  ### `bytes` literals and the `toByte()` method

  The other thing that's new here are the expressions like `b"A"`.
  This is Chapel's notation for a `bytes` value, similar to the string
  value `"A"`, but using a `b` prefix as a mnemonic for `bytes`.  For
  example, the following code shows the use of both literal types to
  declare variables and then check their types::

  ```chapel
  const first = "Brad",
        last = b"Chamberlain";
  writeln((first.type:string, last.type:string));  // prints '(string, bytes)'
  ```

  The `bytes` type supports a method called
  [`.toByte()`](https://chapel-lang.org/docs/language/spec/bytes.html#Bytes.bytes.toByte)
  that, for a single-byte `bytes` value returns it as a `uint(8)`.
  When the `bytes` value is a `param`, as these literals are, the
  `uint(8)` it returns is as well.  Thus, these declarations are
  equivalent to writing:

  ```chapel
  param A = 65,
        Z = 90,
        a = 97;
  ```

  or just directly using those numeric values where `A`, `Z`, and `z`
  are referenced.  Which brings us to our final bit of code:

*/

  if item <= Z {
    return item-A + 27;
  } else {
    return item-a + 1;
  }
}

/*

  Here, I'm leveraging the fact that `A` through `Z` come before `a`
  through `z` by checking to see whether the current item's numerical
  value is less than `Z`'s.  Since all our items are letters, if it
  is, then it is a capital letter.  I then compute its priority by
  subtracting `A`'s numerical value and adding 27.  This maps `A` to
  the priority `27`, `B` to `28`, and so on.  Otherwise, the item must
  be a lowercase letter, so I do the same sort of subtraction, mapping
  `a` to the value `1`, `b` to `2`, etc.

  If, like me, you find it somewhat distasteful to be computing on
  ASCII values, another approach might be to create a map from byte
  values to scores at the outset of the program, and then look up the
  byte values in that map.  This felt a bit heavyweight to me given
  the nice numerical properties of adjacent letters, and I wasn't sure
  I wanted to teach you about maps today anyway.  But it's another
  approach to consider.

  ### Summary and Tips for Part Two

  And that's my solution to day three!  Most of the features used
  today show up in a lot of Chapel programs in practice.  Ranges are
  so fundamental and intuitive that we've seen them in the previous
  days' articles without even defining them.  Forall-loops are one of
  the pillars of data parallelism in Chapel and show up frequently.
  And `param`s are crucial for doing compile-time computation in
  Chapel, including procedures which take in and return `param`s.
  Finally, the `bytes` type is a nice alternative to strings,
  particularly in cases where you are only using ASCII strings, want
  to compute on numerical byte values, and/or want guarantees of
  better performance.

  As on previous days, the full code for my solution can be viewed and
  downloaded at the top of this article, or [at
  GitHub](https://github.com/chapel-lang/chapel/blob/main/test/studies/adventOfCode/2022/day03/bradc/day03.chpl).

  If you are interested, you should have everything you need to do
  part two on your own.  The main changes I made to my code were to

  * change my iterator to return triples of lines rather than pairs of
    compartments

   * use a second set to store all of the items appearing in the first
    two rucksacks

  Tomorrow, if all goes as planned, you'll be hearing from one of my
  colleagues—so I will see you sometime next week!

*/
