// Advent of Code 2022, Day 2: Rochambeau
// tags: ["Advent of Code", "How-To"]
// series: ["Advent of Code 2022"]
// summary: "A parallel solution to day two of AoC 2022, introducing enums, procedures, iterators, arrays, and promotion"
// authors: ["Brad Chamberlain"]
// date: 2022-12-02

/*

  Welcome to day 2 of Chapel's Advent of Code 2022 series!  If you've
  stumbled in the door by chance, you might want to check out the
  previous articles in this series to [get the
  context]({{< relref "aoc2022-day00-intro" >}}) for what we're doing here or
  [learn basic Chapel features]({{< relref "aoc2022-day01-calories" >}}) that we'll
  build on in today's article.

  ### Today's Task and How I Approached It

  [Today's challenge](https://adventofcode.com/2022/day/2) is to read
  in a mysterious guide consisting of pairs of letters, then use them
  to drive a game of rock-paper-scissors.  In part one of the
  challenge, we'll interpret the letters as being indicative of which
  shape our opponent throws and which one we do.  A somewhat byzantine
  scoring system is applied, awarding points for wins and draws, as
  well as the shape thrown, even in the case of a loss.  Our task is
  to add up all of the scores across the games.

  **For those who eat dessert first, here's my approach to part one that I'll be describing:**
  {{< whole_file_min >}}

  In today's program, I had the opportunity to use more interesting
  Chapel concepts, including our first parallel, multicore-ready
  computation.  I also approached today's problem with the goal of
  using high-level, descriptive features rather than worrying too much
  about code size or performance (though neither one is too shabby).

  Some of the features I use in my solution include:
  * _enumerated types_ to represent groups of symbols with associated values
  * _procedures_ to factor sub-computations into useful units
  * an _iterator_ to read the input and help populate an array
  * _tuples_ to pass pairs of values into and out of the routines
  * _argument promotion_, an elegant form of data-parallelism within Chapel
  * a _reduction_ to combine an array of values down to a scalar

*/

/*

  ### `use` Statements and Enumerated Types

  My program begins with a pair of `use` statements:

*/

use IO;
use outcome, shape;

/*

  The first of these, `use IO;` we saw yesterday, and it will again
  give us access to routines that we can use to read the input set.
  The second `use` statement is slightly different in that it is not
  making module symbols available to the scope, but symbols defined by
  our enumerated types, or `enum`s.  Let's take a look at the enums
  themselves and then come back to this.

  I defined three enums for this program, one describing the three
  shapes that a competitor can throw, one describing the three
  outcomes of a match, and one describing the six entries that can be
  read from the guide:

*/

enum outcome {lose=0, draw=3, win=6};
enum shape {rock=1, paper, scissors};
enum entry {A=rock:int, B, C,
            X=rock:int, Y, Z};

/*

  In Chapel, the symbols of an enumerated type need not have values
  associated with them, and in practice, many `enum`s do not.  These
  are referred to as [_abstract_
  enums](https://chapel-lang.org/docs/language/spec/types.html#enumerated-types),
  and they do not support the ability to be converted to integers.  In
  this program, associating the `enum` symbols with integers permits
  us to do some convenient conversions, so we will define _concrete_
  enums in which each symbol has an associated `int` value.

  For example, when scoring a match, losses count for 0 points, draws
  for 3, and wins for 6, so I gave our three `outcome` symbols their
  respective values.  Similarly, throwing rock, paper, or scissors
  earns 1, 2, or 3 points.  Here, I only explicitly assign the value
  `1` to `rock`, and the symbols that follow will automatically be
  associated with the subsequent integers.

  Though I might like to map the letters to the `rock`, `paper`, and
  `scissors` enums, since that's what they represent, currently Chapel
  enumerations can only be mapped to integer values.  Moreover, `enum`
  constants with associated integer values do not coerce to that
  value; instead, casts are required to convert from an `enum` to
  `int`.  So here, I am casting `rock` to an integer and associating
  that value with `A` and `X`, since those are the two letters we're
  interpreting as 'rock'.  As before, the subsequent letters will take
  on the next numerical values, so `B` and `Y` will share `paper`'s
  integer value, and `C` and `Z`, `scissors`'.

  Let's now return to my second `use` statement.  By default in
  Chapel, references to an `enum`'s symbols must be fully _qualified_,
  providing a form of namespace safety.  For example, given the
  declaration of `shape` above, I would need to write `shape.rock` in
  my code to refer to that shape rather than simply `rock`.  While
  this is a very safe default, it can also be somewhat onerous when
  trying to write simple programs quickly, as in AoC.  For that
  reason, the `use` statement can be applied to an `enum` to make its
  symbols available to the scope, analogously to how `use` works with
  modules.  In this program, I only `use`d two of the three enums
  because they were the only two whose symbols I needed to refer to
  within the program text.

  {{< details summary="**(A note on declaration orderings and visibility...)**" >}}

  Astute readers will note that the `use` statement refers to the
  `outcome` and `shape` types before they are defined, and this may
  seem strange coming from other programming languages, like C.  In
  Chapel, a symbol defined within a scope is generally visible from
  anywhere within the scope, whether before or after its declaration
  point.  As a result, it is not a problem for the `use` to refer to
  my `enum` types before they have even been defined.

  One benefit of this approach is that procedures do not require
  prototypes in Chapel, as in languages like C, and they can be called
  whether they are defined earlier or later in a scope.  As a result,
  Chapel programs are often written to be read from the top downwards,
  as in English, rather than bottom-up as in many traditional
  programming languages.  In fact, [my GitHub solution for today's
  program](https://github.com/chapel-lang/chapel/blob/main/test/studies/adventOfCode/2022/day02/bradc/day02.chpl)
  follows this principle by putting the first statements to be
  executed—those that read the file—near the top of the listing.  For
  this blog, I used a more traditional bottom-up approach simply
  because it lets me describe Chapel features to you in a more natural
  order.

  Before we go on, one place where declaration order _does_ matter is
  in variable declarations.  For example, if I write:

  ```chapel
  var x = y;
  var y = 10;
  ```

  the reference to `y` in `x`'s initializer refers to the variable `y`
  defined on the next line; however, this is not legal Chapel code
  because variables are not permitted to be referred to before they
  have been initialized.  So the principle of the symbols being
  visible throughout the scope still holds, but it is not useful in
  this specific context—either the declarations must have their orders
  swapped, or `x`'s initializer cannot refer to `y`.

  {{< /details >}}

*/

/*

  ### Procedures in Chapel

  The _procedure_ is one of two kinds of subroutines (or simply
  _routines_) in Chapel, the other being the iterator, which we'll see
  a bit later.  Procedures are used to factor a segment of code away
  from its callsite, as in other languages.  They may take arguments
  and/or return values.  In my program, I define three procedures,
  `beats()`, `verdict()`, and `score()`.

  #### The `beats()` procedure

  The first procedure I'm defining takes two shapes and determines
  whether or not the first beats the second in a game of
  rock-paper-scissors:

*/

proc beats(s1, s2) {
  return s1 == rock && s2 == scissors ||
         s1 == paper && s2 == rock ||
         s1 == scissors && s2 == paper;
}

/*

  Procedures are introduced using the `proc` keyword in Chapel,
  followed by the name of the procedure—in this case, `beats`.  This
  procedure takes two arguments, `s1` and `s2`, which represent two
  shapes that have been thrown.

  Note that the arguments of `beats()` do not have declared types, nor
  have I declared the procedure's return type.  Like the variable and
  constant declarations we saw yesterday, this is another form of
  _type elision_, provided for convenience and flexibility.  In
  practice, the compiler will analyze the Chapel source code and
  determine that this procedure will take two `shape`s and return a
  `bool`.

  {{< details summary="**(For readers familiar with C++ or generic instantiation...)**" >}}

  More precisely, `beats()` is _generic_ in that it was written to
  take two arguments of any type.  The compiler examines the call(s)
  to `beats()` within the program and determines that the only
  _instantiation_ required is one that takes two `shape` arguments.
  It therefore creates a copy of `beats()` with the signature:

  ```chapel
  proc beats(them: shape, us: shape): bool {
  ```

  In this way, Chapel's generic procedures are a lot like C++ template
  functions, but using simpler (and arguably more intuitive) syntax.

  {{< /details >}}

  In practice, it can often be valuable to constrain a procedure's
  arguments, for documentation purposes, safety, or just to avoid
  confusion.  For example, even though this procedure was written to
  accept two arguments of any type, its body compares the arguments to
  `shape` values; therefore, the procedure will only work for
  arguments that support comparisons with `shape` values—which, for
  our program, means only other `shape`s.  Since we know that the
  procedure was only designed to take `shape` arguments, we could make
  this explicit in the code by providing argument types.  We could
  also add a return type for the purposes of documentation and to have
  the compiler validate that we're keeping our types straight.  The
  result would look like this:

  ```chapel
  proc beats(them: shape, us: shape): bool {
  ```

  In my AoC codes, I tend to write most of my routines generically
  since the programs are not very complicated, and to keep the code
  concise and flexible.  However, when defining libraries for others
  to use, my preference is definitely to specify argument and return
  types as a form of creating well-defined interfaces and
  self-documenting code for a user.

  #### The `verdict()` procedure

  The next procedure I'll define takes two arguments representing
  entries from the guide.  It will convert those entries to shapes and
  then use them to determine whether we won, lost, or had a draw,
  returning the corresponding `outcome`:

*/


proc verdict(abc, xyz) {
  const them = abc: int: shape,
        us   = xyz: int: shape;
  
  if them == us {
    return draw;
  } else if beats(them, us) {
    return lose;
  } else if beats(us, them) {
    return win;
  } else {
    halt("We should never get here: ", (them, us));
  }
}

/*

  The constant declarations convert each argument from an `entry`
  value to a `shape`, leveraging the fact that we defined the entries
  to have integer values matching the shapes.  Chapel does not support
  enum-to-enum casts by default and I don't have time to teach you how
  to write one today, so we'll just cast each `entry` to `int`, and
  then cast that `int` to a `shape`, one for our opponent and one for
  us.

  Next, we check whether the shapes are the same, indicating a draw.
  If they're not, we pass them to our `beats()` routine to see whether
  we lost or won.  In each of the three cases, we return the
  corresponding `outcome` value.

  The call to `halt()` in the final `else` clause should be
  unnecessary if my program is correct (and I believe it is!), and I
  could even replace the check for whether we won with a simple `else`
  clause since it's the only other rational possibility.  However, I
  wrote it this way in case my code had bugs, and an earlier version
  of it did, so this saved me some headache by pointing out my mistake
  blatantly rather than silently returning a `win` for that case.

  Chapel's `halt()` routine is a lot like `writeln()` in that it
  prints out all of its arguments, but then it also exits the program.
  For the second argument I'm passing to `halt()`, I've created a
  _tuple_ of the two values, which would print out like `(0, 3)`.
  We'll see additional uses of tuples as we go.

  #### The `score()` procedure

  My final procedure computes the score of a round of
  rock-paper-scissors, given two `entry` values from the strategy
  guide:

*/

proc score((abc, xyz)) {
  return xyz:int + verdict(abc, xyz):int;
}

/*

  Though it may not look like it, this procedure takes just a single
  argument, but that argument must be a 2-tuple.  The tuple nature of
  the argument is indicated by the additional set of parentheses.
  This represents a syntactic de-tupling of the argument that is
  passed in, binding its component values to the argument names.
  Since there are two argument names, the actual argument passed in
  must be a 2-tuple.  My reasons for taking this approach will become
  clear as we get further along.

  If we were to create the fully typed version of this procedure,
  it could be written as follows:

  ```chapel
  proc score((abc, xyz): (entry, entry)): int {
  ```

  This indicates that the two tuple elements are both `entry` values
  and that the procedure returns an `int`.  A shorthand for writing
  homogeneous tuple types like this is:

  ```chapel
  proc score((abc, xyz): 2*entry): int {
  ```

  This indicates that we are expecting a 2-tuple of `entry` values.

  The body of this procedure is quite simple: It returns the sum of
  our entry's `shape` and the `outcome` of our call to `verdict()`
  after casting both to integers.

*/



/*

  ### Chapel Iterators

  As mentioned above, Chapel's second type of subroutine is the
  _iterator_, declared with the `iter` keyword.  Iterators are like
  procedures in that they are used to factor code away from callsites
  and can be passed arguments.  However, where a called procedure can
  only return a single time, an iterator can _yield_ multiple values
  back to its callsite before ultimately returning (or, it could be
  written to iterate forever).

  The iterator we're going to create is named `readGuide()` and it
  will be written to read pairs of strings from the console, yielding
  them back to the callsite as a 2-tuple of entries:

*/


iter readGuide() {
  var abc, xyz: string;

  while readf("%s %s", abc, xyz) do
    yield (abc:entry, xyz:entry);
}

/*

  We start by declaring two strings, `abc` and `xyz`, which will hold
  the `A`–`C` and `X`–`Z` values that we read in, respectively.  Note
  that the names are simply mnemonic and have no bearing on what
  values the strings can hold.

  To do the input for today's entry, I'm using the `IO` module's
  `readf()` routine, which supports formatted reads from the console.
  The format string `"%s %s"` indicates that we want to read two
  `s`tring values, separated by whitespace, into the arguments that
  follow—`abc` and `xyz`.  `readf()` returns `false` once it cannot
  fulfill the requested read, such as at the end of the file).  So at
  that point, we will exit the `while` loop and fall out of the
  iterator, returning to the callsite.

  The body of the iterator's `while` loop takes the two string values
  and casts them to their corresponding `entry` values.  In Chapel,
  strings can be cast to `enum`s and vice-versa, which tends to be
  very convenient in I/O situations like this one.  We then form a
  2-tuple of the two `entry` values and `yield` them back to the
  callsite.

  Iterators are often used to drive loops in Chapel.  For example, we
  could write a serial for-loop over our `readGuide()` iterator as
  follows:

  ```chapel
  for (i,j) in readGuide() { ... }
  ```

  and this would cause the loop body to run for each pair of values
  yielded, binding them to the loop's index variables, `i` and `j`,
  respectively.  Another way to write this loop would be to use a
  single index variable:

  ```chapel
  for pair in readGuide() { ... }
  ```

  In this case, `pair` would be a 2-tuple of `entry` values.

*/

/*

  ### From Iterator to Array

  Though loops over iterators are very common in Chapel, in this
  program, we're going to use the iterator in another way, and one
  that is very powerful for these AoC exercises where the amount of
  input is typically unknown.  Specifically, we're going to use a call
  to the iterator to initialize a constant, `Guide`, representing our
  strategy guide.

*/

const Guide = readGuide();

/*

  When a variable or constant is initialized using an iterator call
  like this, it becomes a 1-dimensional, 0-based array containing all
  of the yielded values.  In this case, for the AoC sample input of
  three pairs, `Guide` would be equivalent to the array declaration:

  ```chapel
  const Guide: [0..<3] 2*entry = [(A, Y), (B, X), (C, Z)];
  ```

  What makes this such an attractive pattern for AoC codes is that the
  array's size need not be known _a priori_ to declare the array.
  Moreover, arrays are very powerful and fundamental types in Chapel,
  particularly for use in parallel computation.  So once we have our
  input data in an array, we can start to do cool things with it.

  ### Argument Promotion

  In this case, the cool thing we're going to do is so subtle and
  powerful, you might miss it, so let's work our way up to it.
  In Chapel, given a procedure that accepts a scalar value, like:

  ```chapel
  proc inc(x: int) { return x+1; }
  ```

  in addition to calling the procedure with an integer argument, like
  `inc(42)`, you can also call it with an argument that is an array
  of integers and get an array of results back.  For example:

  ```chapel
  var result = inc([42, 33, 78, 45]);  // result will be the array '[43, 34, 79, 46]'
  ```

  This is known as _argument promotion_, where the scalar formal
  argument is being _promoted_ by passing it an array actual
  argument.

  Not only is this a powerful and compact idiom, but it is also the
  first parallel computing concept we've seen in AoC 2022.
  Specifically, Chapel can and will evaluate promoted function calls
  in parallel.  For example, for a large array on a sixteen-core
  processor, each processor will compute the function call for 1/16 of
  the array elements in parallel, ideally resulting in a 16x speedup
  as compared to iterating over the array serially and making the
  calls one at a time.

  By now, you can probably see where this is going: By calling
  `score(Guide)`, we pass our array of 2-tuples to our `score()`
  procedure, which expects a 2-tuple as its argument.  This promotes
  the call, generating an array of resulting scores.  We could then
  capture those scores into a new array variable as follows:

  ```chapel
  var Scores = score(Guide);  // Scores will be an array of `int` scores
  ```

  Because promotion enables parallel execution, this also has the
  potential to parallelize the main computation in our program.  The
  3-element AoC sample input is small enough that its promotion will
  be computed serially to avoid unnecessary task creation overheads;
  but for the full-sized input, Chapel should use all of your
  laptop's processor cores to compute the scores in parallel.

  {{< details summary="**(Performance notes for this code...)**" >}}

  For anyone inclined to do performance studies of this Chapel
  program, or others, note that once you have a correct Chapel
  program, you should always [recompile it with
  `--fast`](https://chapel-lang.org/perf-tips.html) before doing
  performance studies with it.

  Furthermore, for this quick-running program, note that the I/O
  required to read the guide as input is likely to dominate the
  execution time of the program, potentially overwhelming any benefits
  gained from the parallelism here.  However, for a longer-running or
  more computationally-intensive program, this form of implicit
  parallelism can result in significant performance gains.  You can
  simulate this by putting a serial loop around the promoted call to
  `score(Guide)` to run it for a larger number of trials until it
  overwhelms the input time.  To compare with a serial execution, try
  replacing the promotion with a serial for-loop that iterates over
  the `Guide` array, calling `score()` on each element.

  {{< /details >}}

*/

/*
  ### Reductions

  At this point, all that is required is to sum all of the values
  returned by our promoted call, `score(Guide)`.  Because this is a
  common idiom in parallel computing, Chapel supports a `reduce`
  expression which can be used to collapse a collection of values down
  to a single result.  In this case, we want to sum all of the values,
  so we use a `+ reduce` expression and just print out the result
  using a `writeln()`::

*/

writeln(+ reduce score(Guide));

/*

  One thing to note here is that Chapel is designed to avoid silently
  creating temporary arrays whenever possible. This is because, when
  working at the supercomputer scales that Chapel was built for,
  arrays can be massive, and allocating an extra array here or there
  can exhaust your memory very quickly.  So where we might think of
  the call to `score(Guide)` as conceptually creating an array of
  results, if we reduce the call immediately rather than storing it
  into an explicit array, the reduction will actually combine the
  scalar `int` scores as they are returned, eliminating the need for
  any temporary arrays.  As a result, the memory requirements for this
  program's variables are essentially just the space for the `Guide`
  array and some scalar variables.

  {{< details summary="**(Do we need any arrays at all...?)**" >}}

  We could even eliminate the space required by the `Guide` array by
  promoting `score()` with the invocation of the iterator itself, as
  follows:

  ```chapel
  writeln(+ reduce score(readGuide()));
  ```

  However, my `readGuide()` iterator is serial, for reasons I'll
  explain in a moment, which means that the promotion would be as
  well.  As a result, this is a classic time-space tradeoff: Spend
  some space to store the data in an array to enable parallel
  computation?  Or conserve the space and spend more time computing
  serially?  In Chapel, this decision is yours to make.

  My `readGuide()` iterator is serial because it is implemented using
  a serial while-loop.  In practice, textual input can generally be very
  difficult to parallelize due to the difficulty in anticipating how
  many bytes each element will require.  However, this program's input
  is regular enough that it _could_ be parallelized, with effort.
  Specifically, we could write a parallel overload of `readGuide()`
  that would use Chapel's support for files and channels to read
  entries from the file in parallel.  However, that is beyond the
  scope of this article (and series, likely).

  {{< /details >}}

*/

/*

  ### Summary and Tips for Part Two

  We covered a lot of ground today including several key features that
  should serve you well during AoC 2022: procedures, iterators, enums,
  halts, and your first introduction to arrays and parallel computing
  in Chapel, including promotion and reductions.  In future articles,
  we'll almost certainly spend more time with arrays as well as more
  explicit forms of concurrency in Chapel, such as parallel loops.

  Like yesterday, the full code for my solution can be viewed and
  downloaded at the top of this article, or [at
  GitHub](https://github.com/chapel-lang/chapel/blob/main/test/studies/adventOfCode/2022/day02/bradc/day02.chpl),
  noting again that the GitHub version of the code uses my preferred
  top-down ordering of the code.

  Refreshingly, you have all the tools you need to complete part two
  of today's assignment.  It's essentially a fairly minor variation on
  part one in which you'll need to redefine what entries `X`, `Y`, and
  `Z` mean, and change the interpretation of the `xyz` variables in
  the guide.

  Good luck, and see you tomorrow!
*/
