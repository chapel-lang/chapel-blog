// Advent of Code 2022, Day 6: Packet Detection
// tags: ["Advent of Code", "How-To"]
// series: ["Advent of Code 2022"]
// summary: "A parallel solution to day six of AoC 2022, introducing configs, parallel loop expressions, range translation, and named, unbounded, and counted ranges."
// authors: ["Brad Chamberlain"]
// date: 2022-12-06

/*

  Welcome to day 6 of Chapel's Advent of Code 2022 series.  We're now
  just about halfway through our twelve days of Chapel AoC!  For more
  context, check out our introductory [Advent of Code 2022: Twelve
  Days of Chapel]({{< relref "aoc2022-day00-intro" >}}) article for background and
  instructions on compiling this code.

  ### The Task at Hand and My Approach

  In brief, [the challenge for
  today](https://adventofcode.com/2022/day/6) is to read in a
  datastream buffer (a line of characters) and to find its packet
  header, which is a window of 4 consecutive characters that are all
  unique.

  My approach today will be to start with a serial solution and work
  towards a parallel one.  Specifically, I'll read the datastream in
  as a `bytes` value and use _slicing_ to look at a 4-byte sliding
  window of the value.  To see whether the bytes in that window are
  unique, I'll put them into a set and check its resulting size.  If
  it's `4`, we'll know we've found our header and can stop executing,
  printing the offset.

  For the parallel solution, I'll take a similar approach, but using a
  `maxloc` reduction to find the header.  Along the way, we'll see
  some other features for the first time in this series, including
  _configurable declarations_ (`config`), named ranges, the `#`
  operator, and a shorthand parallel loop expression.  Oh, and we'll
  write a single code that will work for both parts one and two, so,
  no homework for you tonight!  (But this _will_ be on the test...)

  **If you want to live your life like Merlin, here's my complete solution for today:**

  {{< whole_file_min >}}

  ### Starting Out: Using Standard Modules

  In this article, I'll be taking a bottom-up approach to walking
  through the code.  Though this isn't my preferred style of coding in
  Chapel, it allows me to start with the code that is common between
  my serial and parallel solutions.

  I start out with a `use` statement in order to access the standard
  modules I want to use today:

*/

use IO, Set;

/*

  The `IO` module will be familiar to readers of this series.  For
  those just joining us, it will provide the routine I'll use to read
  our datastream.  Meanwhile, the `Set` module provides the `set`
  datatype that I'll use to count unique values.

*/

/*

  ### A `config` Declaration for the Marker Length

  Our next declaration uses a very common Chapel feature, but one that
  we have not yet seen in this series—the _config_ declaration:

*/

config const markerLen = 4;

/*

  This statement declares a constant (`const`) named `markerLen`,
  which I've initialized to `4`.  This represents the window size as
  well as the number of unique characters the window must contain.
  Like all constants in Chapel, it cannot be modified once it has been
  initialized.

  The `config` keyword here means that the initial value of this
  constant can be overridden when running the program using a
  command-line flag.  To illustrate this, let's assume we were to save
  this code into a file named `day06.chpl` and compile it as usual:

  ```bash
  $ chpl day06.chpl
  ```

  If we ran the program as-is: `./day06`, it would use the value of
  `4` for this constant, as indicated in the source code.  However, we
  can also run it using a flag to specify a new initial value, like
  this:

  ```bash
  $ ./day06 --markerLen=14
  ```

  This overrides the value of `4` from the source, causing `markerLen`
  to be initialized to `14` for this program's execution.  The goal of
  Chapel's `config` declarations is to reduce the degree to which many
  programs need to do argument command-line parsing for common cases,
  by having the compiler implement flags on the generated executable
  that can set the values of such constants.  Of course, if you
  prefer, you can do your own command-line parsing as well (though I'm
  not covering that today).

  {{< details summary="**(More details on `config` declarations...)**" >}}

  The default value of a `config` can also be set at compile-time, if
  you'd like to override the initializer in the source when you're
  building the executable.  For our program, this can be done as
  follows:

  ```bash
  $ chpl -smarkerLen=14 day06.chpl
  ```

  When overridden at compile-time, `config` declarations can be
  initialized not just with literal values, but also with expressions
  that would be legal if they appeared in the source code at the
  initialization point, such as `-smarkerLen="(2*5)+4"`,
  `-smarkerLen="+ reduce [1, 1, 2, 3, 3, 4];"` or even
  `smarkerLen="x*foo(y)"`, assuming `x`, `y`, and `foo()` have valid
  interpretations at `markerLen`'s declaration point.

  In addition to `config const`s, Chapel also supports `config var`,
  `config param`, and `config type` declarations.  A `config var` is
  similar to a `config const` except that the variable can be
  re-assigned after its initialization, just like any variable.
  In Chapel, `param` and `type` declarations must be well-understood
  by the compiler, so they don't support overrides at execution-time,
  just compile-time.  Recall that `param`s are compile-time constants
  in Chapel.  We haven't seen `type` declarations in this series yet,
  but as you might guess, they support the declaration of type
  aliases.  In this way, a compile-time constant or type alias can be
  changed from one compile to the next using the same `-s` flag as
  above.

  {{< /details >}}

*/

/*

  ### Helper Routines for Identifying the Marker

  Next up, we declare a pair of helper routines that will do the work
  on each of our `markerLen`-sized windows.  The first takes in a
  `window` and counts the number of unique characters in it:

*/

proc uniqueChars(window) {
  var s: set(uint(8));

  for ch in window do
    s.add(ch);

  return s.size;
}

/*

  As usual, I've written this using inferred types, but am expecting
  it to take a `bytes` value as the window and return an `int`.
  Because I've written it in this generic style, in practice, it would
  work with any argument type whose serial iterator yields 8-bit
  unsigned integer values (`uint(8)`s).

  The body of this routine is fairly straightforward: I first declare
  a set of 8-bit unsigned integers named `s`.  Then I iterate over the
  `bytes` value, representing the component 8-bit values with my loop
  index variable `ch`.  Then I add each value into my set `s`.  At the
  end, I return the size of the set, which represents the number of
  unique bytes or characters within `window`.

  My second helper routine is even simpler:

*/

proc isMarker(window) {
  return uniqueChars(window) == markerLen;
}

/*

  It takes an argument, passes it along to `uniqueChars()` and returns
  whether or not the result is equal to `markerLen`.  It is similarly
  generic, so will accept anything that `uniqueChars()` can handle and
  will return a `bool` indicating the result.  I obviously could have
  combined these two routines into one, but for some reason it struck
  me as a better work decomposition to use two separate procedures.

*/

/*

  ### Reading the Input Buffer

  This is the simplest case of input we've had for AoC 2022 yet,
  perhaps to make up for yesterday.  We only need to read a single
  line of data.  Because we're going to do a lot of indexing into this
  buffer, I've chosen to use a `bytes` type for similar reasons as in
  [day 3]({{< relref "aoc2022-day03-rucksacks" >}}): they support efficient
  indexing due to their simple nature and fixed-size elements.

  All I have to do is declare the buffer and pass it to the
  `readLine()` routine that we've used for several of these exercises
  now:

*/

var buffer: bytes;
readLine(buffer);

/*

  ### A Named Range for the Sliding Window

  Before getting into the details of my solution, I'll declare a named
  range to represent the indices that I'll be using to control this
  sliding window across the buffer:

*/

const inds = 0..<buffer.size-markerLen;
/*

  We've seen several Chapel ranges in this series so far, but I
  believe this is the first that we've stored into a named constant or
  variable.  Like other such declarations, this gives us the
  opportunity to create the range once and refer to it symbolically,
  perhaps using a name that is clearer the range expression itself.
  In this case, I chose to make the range a named `const` simply
  because the lines where it's used in my two solutions were a bit
  cluttered when they contained the literal range
  `0..<buffer.size-markerLen`.

  Now let's talk about value of `inds`, which represents the indices
  where I'll want to apply my sliding window.  Its low bound is `0`
  since `bytes` values like our `buffer` use 0-based indexing.  Since
  our sub-buffer window will be `markerLen` characters (or bytes), I
  subtract `markerLen` from the buffer's size in order to avoid
  indexing the buffer out-of-bounds and use this as the high bound.
  As in previous days' exercises, I'm using the open-interval range
  syntax (`..<`) to indicate an exclusive upper-bound, due to the
  0-based indexing.

  ### Finding the Marker Sequentially

  Before introducing my parallel solution, I'll start with a
  sequential one.  The main control flow is a serial `for` loop:

  ```chapel
  for i in inds {
    if isMarker(buffer[i..#markerLen]) {
  ```

  This iterates over the range of starting indices, binding them to
  the loop index variable `i`, one at a time.  I then compute the
  window or sub-buffer to pass to `isMarker()`, using a new range
  operator we haven't seen yet in this series.  Let's break it down:

  #### Specifying the Window Using an Unbounded, Counted Range

  I start with the range `i..`, which is an _unbounded range_. We
  touched on these very briefly in [yesterday's
  article]({{< relref "aoc2022-day05-cratestacks#zippered-iteration-unbounded-ranges-and-another-strided-range" >}}),
  but to summarize, it can be thought of as a range that starts
  counting from `i` upwards towards infinity.

  I then apply the count operator (`#`) which says to take the first
  `markerLen` elements of the expression to which it is applied—in
  this case, my unbounded range.  The expression `i..#markerLen` can
  be read aloud as:

  > "Start counting from _i_ and give me _markerLen_ indices."

  As a concrete example, if `i` were `6`, `i..#4` would represent
  `6..#4`, which is equivalent to `6..9` or the sequence `6`, `7`,
  `8`, `9`.  More precisely `lo..#n` is the same as `lo..<lo+n`, so in
  this context, `#` can be viewed as a convenient form of syntactic
  sugar that makes common range idioms easier to read and get right
  the first time.

  #### Getting the Window's Sub-Buffer via Slicing

  We then take this range expression and use it to access `buffer`,
  giving us a `markerLen`-sized sub-buffer, itself represented as a
  new `bytes` value.  We pass this `bytes` value to our `isMarker()`
  routine, which will tell us whether or not these specific byte
  values represent the marker we're looking for.

  As a result, the net effect of these two lines is to slide this
  `markerLen` window of indices across the entire input `buffer`,
  looking for the marker.  If we find it, the conditional evaluates
  to `true` and we execute the body, which is:

  ```chapel
      writeln(i+markerLen);
      exit();
    }
  }
  ```

  Essentially, we print out the offset that follows the header by
  adding `markerLen` to the index representing the start of the marker
  (`i`).  We then exit the program by calling `exit()`, since we've
  printed the marker we're looking for and have nothing more to do.

  Overall, pretty straightforward.  Was that our shortest Aoc 2022
  program yet?


  ### Finding the Marker in Parallel

  Our parallel solution is even shorter, and not much more difficult,
  though its code is a bit denser.  Rather than running the window
  over our buffer serially, one element at a time, why not apply it in
  parallel across the buffer simultaneously?  Since we are only
  reading the buffer and not modifying it, there is no problem if
  several parallel tasks are inspecting it at once, even if their
  windows overlap.

  The one trick to getting this right is the following: What if
  multiple tasks find a `markerLen`-length sequence that meets our
  marker criteria?  How do we know which one to return?  One approach
  for this that I'll use today is to use the _`maxloc` reduction_.
  But first, I need to introduce a few building blocks I'll be relying
  on:

  #### Parallel Loop Expressions

  In earlier posts in this series, we've seen Chapel's `forall` loop,
  which specifies that the iterations of a loop can and should be
  executed in parallel.  Up until this point, all `forall` loops that
  we've seen have been statements.  However, `forall` loops can also
  be expressions.  For example, I could write:

  ```chapel
  MyArray = forall i in 1..1000 do i;
  ```

  The forall-loop expression on the right-hand side specifies a
  parallel computation that will yield values (in this case, the
  indices `i`) back to the execution context.  Arrays like `MyArray`
  support assignment overloads that take such iterable expressions and
  assign them, element-wise, to the array.  The net effect is that the
  elements of `MyArray` would be assigned the values between `1` and
  `1000`, respectively.  In essence, this statement could be viewed as
  a more concise way of writing:

  ```chapel
  forall (elem, i) in zip(MyArray, 1..1000) do
    elem = i;
  ```

  At the same time, the `forall` expression can be somewhat unwieldy
  due to the keywords involved.  Because of this, Chapel provides an
  alternative, symbol-based way to write a _(potentially)_ parallel
  loop expression, which looks like this:

  ```chapel
  MyArray = [i in 1..1000] i;
  ```

  {{< details summary="**(Wait, why did you say 'potentially' there...?)**" >}}


  The opening and closing square brackets in this expression are often
  interpreted as `forall` and `do` respectively.  And in most cases,
  that's an appropriate interpretation, though there is one slight
  difference between the two forms (the reason I said "potentially"
  above): As mentioned on [day
  3]({{< relref "aoc2022-day03-rucksacks#forall-loops-and-task-intents" >}}),
  a `forall` loop says "invoke this iterand's default parallel
  iterator method."  In contrast, Chapel's square-bracket loop form
  says to invoke the parallel iterator if there is one; but if not, to
  fall back to the traditional serial iterator.  In practice, most
  built-in Chapel types like ranges and arrays support parallel
  iterators, making the the two loop forms equivalent for those cases.

  {{< /details >}}

  For our purposes in today's code, think of this as a shorthand for
  a forall-loop expression.

  #### Range Translations

  In this computation, I also rely on the ability to translate ranges
  by an integer offset.  As an example, consider a range like:

  ```chapel
  const r = 1..10;
  ```

  The expression `r+5` would result in the range `6..15`.
  Essentially, we've just added `5` to every integer in the range,
  resulting in a new range shifted by the integer offset.  Intuitive,
  right?

  #### The `maxloc` Reduction

  In previous entries in this series, we've seen reductions, both in
  [expression]({{< relref "aoc2022-day02-rochambeau#reductions" >}}) and
  [task
  intent-based]({{< relref "aoc2022-day03-rucksacks#forall-loops-and-task-intents" >}})
  forms.  Both forms are used to combine a collection of values—like
  the elements of an array—down to a single result value.  In
  practice we've exclusively used the `+` reduction, which combines
  the elements by adding them together.

  Chapel has other flavors of reductions as well, such as the `max` and
  `min` reductions, which can be used to find the largest and smallest
  values in a collection.  For example, given an array of student test
  scores named `SAT`, the following lines would find the lowest and
  highest scores in the array:

  ```chapel
  const lowest = min reduce SAT,
        highest = max reduce SAT;
  ```

  Sometimes, though, it's not enough to just find the lowest or highest
  value in a collection, but also where that value lives in the
  collection.

  This is where the `minloc` and `maxloc` reductions come in.  Rather
  than reducing a collection down to a single value, they reduce a
  zippered pair of collections—one representing the values and the
  other representing their indices—down to a tuple result: the
  smallest/largest value and that value's index.  When multiple
  positions have the same value, the location of the lowest index in
  the collection is returned.  For example:

  ```chapel
  const (highScore, idx) = maxloc reduce zip(SAT, 1..SAT.size);
  ```

  This would return the highest SAT score of any student, along with
  that student's corresponding index in the range `1..SAT.size`.  If
  multiple students got the same maximum score, the index of the
  student appearing earliest in the array would be returned.

  In practice, indexable types in Chapel generally support a
  `.indices` query that returns their indices, so a common idiom for
  these reductions is:

  ```chapel
  ...maxloc reduce zip(X, X.indices)...
  ```

  #### Putting it All Together

  Now we have everything we need to interpret the following statement,
  which implements my parallel solution:

*/
var (_, loc) = maxloc reduce zip([i in inds] isMarker(buffer[i..#markerLen]),
                                 inds+markerLen);

/*

  Starting from the right, we're calling `isMarker()` identically to
  my serial solution, but within the loop expression `[i in inds]`.
  Because `inds` is a range and ranges support parallel iteration,
  this will act like a `forall` expression.  This implements my loop
  over the windows into my `buffer` like before, and is the first
  component of the `zip()` passed to my `maxloc` reduction.  Because
  `isMarker()` returns `true` or `false`, the `max` values will be
  those positions that returned `true`—that is, any windows that meet
  our marker criterion.  In addition, because `maxloc` will return the
  first such occurrence, we'll get the one we're looking for towards
  the start of the datastream.

  The second component I pass to `maxloc`'s `zip()` expression is the
  range of indices I'm iterating over, but shifted by `markerLen`.
  This will cause the location that's returned by `maxloc` to be the
  index following the header that we need to print out.

  All that's required now is to get the result of the the `maxloc
  reduce` and print it out.

  ### Printing the Result (ignoring part of it with `_`)

  In de-tupling the result of the `maxloc`, I'm using a special Chapel
  identifier `_`, which means "This value doesn't matter, so don't
  bother naming it; just drop it on the floor."  Since we trust that
  AoC will give us legal input, we know that the header exists and
  that the maximum value will be `true`, so we don't really need to
  capture its value into a variable.  If our input source was not so
  trustworthy (or I was less confident my code was correct), I'd
  probably want to capture the maximum value and verify that it was
  `true`.

  At this point, all that remains is to print out our answer, using
  the now-familiar `writeln()`:

*/

writeln(loc);

/*

  ### Summary

  That concludes my introduction to the serial and parallel Chapel
  solutions that I wrote for day 6 of AoC 2022.  You can browse or
  download the code at the top of this article or [at
  GitHub](https://github.com/chapel-lang/chapel/blob/main/test/studies/adventOfCode/2022/day06/bradc/day06.chpl).  As mentioned at the outset, my
  solution solves part two as well, though you will need to read its
  instructions to see why (hint: it's the `config`).

  Thanks for reading this blog post and series, and please feel free
  to ask any questions or post any comments you have in the new [Blog
  Category](https://chapel.discourse.group/c/blog/21) of Chapel's
  Discourse Page.

*/
