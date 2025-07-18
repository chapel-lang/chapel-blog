// Advent of Code 2022, Day 5: Stacking Crates
// tags: ["Advent of Code", "How-To"]
// series: ["Advent of Code 2022"]
// summary: "A solution to day five of AoC 2022 featuring arrays, lists, strided ranges, zippered iteration, unbounded ranges, and references."
// authors: ["Brad Chamberlain"]
// date: 2022-12-05

/*

  Welcome to day 5 of Chapel's Advent of Code 2022 series!  For more
  context, check out our introductory [Advent of Code 2022: Twelve
  Days of Chapel]({{< relref "aoc2022-day00-intro" >}}) article for background and
  instructions on compiling this code.

  ### The Task at Hand and My Approach

  In brief, [the challenge for
  today](https://adventofcode.com/2022/day/5) is to read in an initial
  configuration of crates in stacks, followed by various commands that
  indicate how to move a subset of the crates in one stack to another.
  This problem is fairly sequential by nature since the list of moves
  needs to be processed in order.

  **For those who like to hear the punchline before the joke, here is our solution to part one of this challenge in Chapel:**
  {{< whole_file_min >}}

  For this problem, our general approach is to use an array of
  conceptual
  [stacks](https://en.wikipedia.org/wiki/Stack_(abstract_data_type))
  that represent the state of the elves' shipping dock.  The _stack_
  is a natural data structure for cases like this where elements can
  only be added to, or removed from, one end of a sequential list of
  items (in this case, our stack of crates).  Meanwhile, the array
  gives us the ability to directly access a given stack so that we can
  add crates to it, or remove them.

  As it turns out, Chapel's standard library doesn't currently support
  a `stack` data type (which we should really address... Recall that
  Chapel is an open-source project if you'd like to help out in this
  regard! :D ); however, it does have a
  [`list`](https://chapel-lang.org/docs/modules/standard/List.html)
  type that will serve the purpose just as well.

  For many of us on the team, the most challenging part of this
  program turned out to be creating the initial array of stacks by
  parsing the input's representation of the starting state:

  ```
      [D]    
  [N] [C]    
  [Z] [M] [P]
   1   2   3 
  ```

  We'll describe how to do this in the latter part of this article,
  using zippered iteration, strided ranges, unbounded ranges, and
  references.  But first, let's start with territory that should be a
  bit more familiar to those who've been following this series.

*/

/*

### Initial Declarations

  At the start of the program, we indicate which modules we will need:

*/

use IO, List;

/*

  `IO` is the module that we'll rely on for helping us read the input.
  Meanwhile, `List` provides the standard `list` datatype that we'll
  use for our stacks.


  Next, we declare and initialize our array of `Stacks` using a helper
  routine that we've written to do all of the fancy parsing needed:

*/

var Stacks = initStacks();

/*

  As usual, we are leaning on Chapel's type inference here, where
  Chapel will infer `Stacks` to be an array of lists because that is
  what `initStacks()` returns.  As mentioned above, we'll look at the
  implementation of `initStacks()` a bit later in this article.  For
  now, understand that each list it returns will be storing the crates
  in its respective stack, from bottom to top.  Let's start by looking
  into how to move the crates between stacks now that they're set up.

*/

/*

  ### Reading Rearrangement Procedure Commands

  With the `Stacks` in their initial state, we are ready to read in
  and execute the rearrangement procedure.  All of the steps of the
  procedure follow a very structured format in the input, making them
  a good match for the `readf()` routine.  See [yesterday's
  post]({{< relref "aoc2022-day04-ranges#first-solution-hand-coded-interval-arithmetic" >}})
  for a detailed description of `readf()` and its use in various
  examples.

  Specifically, in this case, we declare three `int` variables
  representing the stack number, the source, and the destination.  We
  then use a `readf()` to express the pattern we're expecting on each
  line, using `%i` to indicate where an `int` should be read:

*/

var num, from, to : int;
while readf("move %i from %i to %i\n", num, from, to) {

/*

  Note that our format string ends with a newline character (`\n`).
  This is because the first thing in the string is a literal string
  (`"move"`), which must exactly match the input and will not skip
  over whitespace.  If we did not consume the newline, we would get a
  mismatch when trying to read the second line of input.

  Because these commands are the last thing to appear in the input
  stream, when we hit the end-of-file, `readf()` will return `false`
  and we'll exit this loop.

  ### Moving Crates within an Array of Lists

  To execute the command, we need to remove the specified number of
  crates from one stack, adding them to another as we go.  We use the
  following for-loop over the range `1..num` to iterate for the
  specified number of crates to move, `num`.

*/

  for i in 1..num {
    const crate = Stacks[from].popBack();
    Stacks[to].pushBack(crate);
  }
}

/*

  For each crate, we index into the array of stacks using the `from`
  and `to` indices to access the stacks that we'll be adjusting.  To
  take the top crate off of a stack, we use the `.popBack()` method
  provided by lists, which removes and returns the final element in
  the list.  We store this into a local constant, `crate`.  Then, we
  use the list's `.pushBack()` method to add the crate to the end of the
  destination stack (equivalent to the `.push()` method on a true
  `stack` datatype).  Note that these two statements could also be
  written in one as follows:

  ```chapel
    Stacks[to].pushBack(Stacks[from].popBack());
  ```
  

  Once we exit this nested loop over commands and moves, we are done
  with the rearrangement procedure.

*/

/*

  ## Writing out the Top Crates

  All that remains for the computation is to print out which crates
  are at the top of each stack.  Here, we do that by iterating over
  the `Stacks` array using a for-loop.  When using a `for` or `forall`
  loop to iterate over an array in this way, the loop index variable
  (`stack` in this case) will refer to the elements of the array.  In
  this case, it means that `stack` will refer to the lists in the
  `Stacks` array one at a time.

*/

for stack in Stacks {
  write(stack.last);
}

/*

  Within the loop, we use the list's `.last` method to get the final
  element of each stack (the `top()` using typical stack operations).
  Because we want all of the crate IDs to be concatenated together in
  the output, we print them out using `write()`, which is similar to
  the `writeln()` routine we've used to print output on previous days.
  However, where `writeln()` prints a newline character after all of
  its arguments have been printed, `write()` does not.  This will
  cause our crate names to come out adjacent to one another.

  Then, once we've exited the loop, we use a final `writeln()` with no
  arguments to terminate the output with a linefeed (equivalently, we
  could have used `write("\n");`):

*/

writeln();


/*

  ### An Inherently Sequential Program?

  One of our goals in this blog series is to teach you how to use
  Chapel to write programs that execute in parallel.  However, today's
  challenge is not particularly well-suited to parallelism.  Even if
  we were to read all of the rearrangement commands into an array, we
  couldn't really execute the array of commands in parallel using a
  `forall` loop as we have on previous days, because each command must
  be completed before the next one in order to get a correct solution.

  Or must it...?

  There actually _are_ approaches one could take to parallelize the
  rearrangement procedure, but they are more complex than what we've
  seen up to this point, so let's push the discussion of such
  approaches into a sidebar:

  {{< details summary="**(How we could apply some parallelism to the rearrangement procedure...)**" >}}

  The key to parallelizing this computation is to realize that it's
  not that each command must be completed before the _next one_, but
  that it must be completed before the next command that accesses the
  _same stacks_.  So while we wouldn't be able to simply use a
  `forall` to iterate over the commands and execute them in parallel,
  we could use parallel tasks to execute the commands in another way.

  Specifically, imagine having an array of locks, one per stack, which
  would say whether or not that stack's crates were currently being
  modified.  When looping over the commands using our serial `for`
  loop, we would check to see whether the `from` and `to` stack locks
  were being held.  If not, we could grab them for ourselves to
  indicate that we were going to modify those stacks' crates.  Then,
  we could create an asynchronous task using Chapel's `begin`
  statement to move the specified number of crates between those
  stacks and release the crates' locks when finished.

  Once that task was created (but not yet complete), the `for` loop
  could then go on to the next command, see whether its locks were
  free, and execute a distinct task to run it.  If, instead, the locks
  were held, the main task would wait until they were free before
  proceeding.

  Rather than the very structured data parallelism that we used in
  previous days, this is a very asynchronous task-based approach.  And
  in truth, it would not be terribly difficult to write in Chapel.

  So why didn't we do it?

  Primarily because it felt like overkill for this situation.  The
  time required to move a number of crates from one stack to another
  is very small, and relative to the time required to check the locks,
  take the locks, create a task, and release the locks, it is unlikely
  that using asynchronous tasks would result in any real speedup.  In
  addition, with such a small number of stacks, it is unlikely that
  very many tasks would be able to execute simultaneously, since the
  chances of them needing to access the same stacks would be high.

  But is that a good reason?  After all, yesterday we used data
  parallelism even though the problem size wasn't necessarily large
  enough to see benefits from it.

  So then, maybe it's just because we didn't think of it soon enough.
  Or that we had a sufficient number of serial Chapel concepts to
  teach today without it.  We'll keep an eye out for other
  opportunities to use Chapel's task parallelism and synchronization
  features in future articles, though.

  {{< /details >}}

  Meanwhile, on with our sequential solution!

*/

/*

  ### Reading the Initial State of the Stacks

  "All" that remains is to read in the initial state of the stacks.
  We start by defining an iterator that reads all of the initial input
  lines and yields them, similar to previous days' approaches:

*/

iter readInitState() {
  var line: string;
  while readLine(line) && line.size > 1 do
    yield line;
}

/*

  This iterator uses the same `readLine()` routine we've seen in
  previous days to read in lines one at a time, storing them in the
  string `line`.  In addition to exiting out of the loop if we reach
  the end-of-file (EOF), we'll also exit if we find an empty line.
  Such a line will only have the newline character in it, so will fail
  the `line.size > 1` check.  For today's input format, since a blank
  line is used to separate the initial state from the commands, that's
  the reason we'll exit this iterator.

  ### Parsing the Initial State

  The `readInitState()` iterator is called by the helper procedure
  `initStacks()` that we called at the start of the program:

*/

proc initStacks() {
  const InitState = readInitState();


/*

  This stores the array of lines representing the sketch of the
  initial state into `InitState` as an array of strings.  Now let's go
  through the rest of this procedure a few lines at a time.

  The next line declares a `param`—a compile-time
  constant—representing the number of characters of input that are
  used to represent each stack in the input configuration:

*/

  param charsPerStack = 4;

/*

  This value is `4` to account for the opening bracket (`[`), the
  crate's letter (`A`–`Z`), the closing bracket (`]`), and the
  whitespace that follows (` ` or `\n`).

  Next, we compute the number of stacks that the input represents:

*/

  var numStacks = InitState.last.size / charsPerStack;

/*

  Here, we're using the `.last` method that is available on arrays to
  access the last line of input.  For the sample input, this will be
  the one that contains the numerical stack labels, like:

  ```
   1   2   3 
  ```

  We take the line's size using the `.size` query supported by strings
  and divide by `charsPerStack` to get the number of stacks
  represented by each line.  As mentioned on [day
  3]({{< relref "aoc2022-day03-rucksacks#chapel-params" >}}), using the
  `param` `charsPerStack` is equivalent to just typing `4` here, but
  results in more self-descriptive code (and code that is potentially
  more maintainable if the input format changes in the future, say to
  support 6 characters per stack and 3-character labels).

  As mentioned on [day
  2]({{< relref "aoc2022-day02-rochambeau#use-statements-and-enumerated-types" >}}),
  computing with `enum` values can be much faster than strings, so we
  declare an enum representing the possible crate IDs in order to
  support a faster execution:

*/

  enum crateID {A, B, C, D, E, F, G, H, I, J, K, L, M,
                N, O, P, Q, R, S, T, U, V, W, X, Y, Z};

/*

  Specifically, since executing the commands involves moving crates
  from one stack to the next, copying an enum around is a simple
  load/store instruction.  In contrast, copying strings around tends
  to be much more expensive since they have variable length and
  are typically stored on the heap.

  Note that `crateID` is an _abstract enum_ because it does not
  associate integer values with the symbols.  In this program, we have
  no need of such values, so we just treat the enum as a set of names.

*/

/*

  #### Declaring Arrays in Chapel

  Next, let's (finally!) declare our array of stacks.  

  Though we've computed on arrays throughout this series, all the
  arrays we've used up until now have been defined by capturing the
  invocation of an iterator.  Here, we'll see our first explicit array
  declaration in this series.

  In Chapel, an array type is specified as a set of indices enclosed
  in square brackets, followed by the array's element type.  Here's
  our declaration for this program:

*/

  var Stacks: [1..numStacks] list(crateID);

/*

  For a dense 1D array like this one, a common way to specify the
  indices is using a range expression.  Chapel's rectangular arrays
  are defined in terms of both low and high bounds, so a programmer
  can use 0-based arrays, 1-based arrays, arrays indexed from `-3..3`
  or whatever is most natural for them.  Here we're indicating that we
  want to refer to our stacks as `1`, `2`, `3`, ..., `numStacks`, to
  reflect the numbering given by the AoC problem statement.

  The element type of our array is `list(crateID)` indicating that it
  will be a list of our enumerated type representing the crate IDs.

*/

/*
  
  #### Using Strided Ranges to Populate the Stacks of Crates

  Our last lines are also our most complex.  In them, we'll iterate
  over the lines in `InitState` representing the crates, converting
  the strings into initial values for our stacks.  Because we want to
  fill the stacks from the bottom upwards, we'll iterate over the
  lines of input backwards.  We do this in Chapel using a _strided
  range_ (or, more precisely, a range with a stride other than the
  default of `1`).

  The _stride_ of a range is the value that's used to count from one
  integer to the next.  By default, ranges like `1..n` have a stride
  of `1` in Chapel since they represent consecutive integers.  Chapel
  supports a `by` operator that can be applied to a range in order to
  count by a different stride.  For example `1..n by 2` would
  represent the odd integers between `1` and `n`: `1`, `3`, `5`, ...

  The `by` operator is also how we count down in Chapel.  Users often
  mis-assume that writing:

  ```chapel
  for i in 10..1
  ````

  will count down from `10` to `1`, and for good reason—it seems like
  it could/should.  However, in Chapel, when a range's low bound (to
  the left of `..`) exceeds its high bound (to the right of `..`), as
  in the loop above, it is considered an empty or _degenerate_ range.
  As a result, it will not iterate at all, and control will skip to
  the statement that follows it.  Instead, to count downwards in
  Chapel, we write:

  ```chapel
  for i in 1..10 by -1
  ```

  The negative stride says to start at the high bound (`10`), applying
  the stride until we reach or exceed the low bound (`1`).

  In this program, since we want to iterate over all lines other than
  the last (which contained the stack labels), we write:

*/
  
  for i in 0..<InitState.size-1 by -1 {

/*

  Since our `InitState` array uses Chapel's default 0-based indexing,
  this starts at the second-to-last line (the final one containing
  crates) and counts backwards until the initial line number (`0`).

*/

/*

  #### A Reference Variable for Readabiliy

  Now, for line `i`, we need to search through that line looking for
  crates.  Let's start by coming up with a more concise and
  descriptive way of referring to the line than `InitState[i]` (the
  `i`th element of the `InitState` array).  We'll do this by using a
  `ref` declaration in Chapel to store a reference to the array
  element in question:

*/

    ref line = InitState[i];

/*

  This is similar to saying `var line = InitState[i];` except that
  instead of creating a new string variable storing a copy of the
  string, the `ref` declaration simply creates a name that refers to
  an existing variable's value rather than copying it and creating a
  new one.  This is more efficient, particularly for string data like,
  which can be expensive to copy (well, expensive relative to copying
  an integer, or just referring to an existing string).  Any
  subsequent references to `line` will be like referring to
  `InitState[i]` directly.

*/

/*
    
  #### Zippered iteration, Unbounded Ranges, and another Strided Range

  Now, let's parse the line into the crates it contains.  What we want
  to do is simultaneously iterate through:

  1. the stacks in our `Stacks` array, ready to add new elements to
     them

  2. the characters in our `line` of input that correspond to crate IDs
     (or blank spaces for non-crate entries)

  Chapel supports _zippered iteration_, which is a great way to
  iterate over multiple things simultaneously like this.  It is a way
  to to drive a `for` or `forall` loop using multiple iterand
  expressions simultaneously. As an example, the loop:

  ```chapel
  for (a, i) in zip(MyArray, 1..n)
  ```

  would associate the loop variables `a` and `i` to the corresponding
  values yielded by iterating over `MyArray` and the range `1..n`,
  respectively.  In the first iteration of the loop, `a` would be a
  reference to the first element of `MyArray` and `i` to `1`; in the
  second, `a` is the second `MyArray` element and `i` is `2`; and so
  on.  Generally speaking, the things zipped together must be of the
  same size, and if they are not, the program is erroneous.  For
  example, `MyArray` needs to have `n` elements for this loop to be
  correct.

  In practice, zippered iterations like this yield tuples of values,
  and the index declaration `(a, i)` is simply de-tupling that result
  into distinct index variables.

  Another way to write this loop would be:

  ```chapel
  for tup in zip(MyArray, 1..)
  ```

  This time, we are storing the tuple of array values and indices into
  a single index variable, `tup`. So it will be a 2-tuple of MyArray's
  element type and an `int`.
 
  The other change here is that we've used an _unbounded range_ in the
  `zip()` expression—that is, one that has a missing bound.  In a
  zippered context like this, we say that the first iterand in the
  `zip()` is the _leader_ and subsequent iterands are _followers_.
  When an unbounded range is used as a follower, as in this loop, it
  will automatically conform to the size of the leader.  Thus, this
  would be a way to associate integers with array elements without
  having to know how large the array was.

  Now we have all the tools necessary to iterate simultaneously over
  the characters in our `line` of input and the stacks.  We write this
  loop as:

*/
    
    // do a zippered iteration over the stack IDs and
    // offsets where crate names will be
    for (offset, stackIdx) in zip(1..<line.size by charsPerStack, 1.. ) {

/*

  In this `zip()` expression, the leader is the range `1..<line.size
  by charsPerStack`.  This describes the characters in the input that
  will contain crate IDs (or be blank).  Specifically, since strings
  use 0-based indexing, we start at offset 1 to skip past the initial
  `[` at the start of the line.  Then, to make sure we don't go past
  the end of the line, we define the high bound of the range as
  `line.size`. We use an open-interval range (`..<`) due to the
  0-based indexing.  Finally, we use the `by` operator to apply a
  stride of `charsPerStack` (`4`) to skip over the intervening
  characters (`]`, ` `, `[`) and on to the next crate label.

  The follower iterand is the range `1..` which will count off the
  corresponding stacks.  Because the input format always extends lines
  out to their full length even when the tail end of the line is
  blank, we could have written this `1..numStacks` without problems.
  But here, we're using an unbounded range because we can, nothing is
  lost, and if a future version of the file format removed all
  trailing spaces on the line, the loop would still work correctly.

  We de-tuple the results of the zippering into an `offset` within the
  line where the crateID is and a `stackIdx` indicating the stack's
  index within our array.  As a visualization of this zippering, here
  is a simple diagram showing the offsets into the string, the first
  line of input, and the `offset` and `stackIdx` values that would be
  yielded by this loop:

  ```
  0..<line.size::  0123456789...
  input:           [Z] [M] [P]
  offset:           1   5   9  (skipping through the raw offsets by 4)
  stackIdx:         1   2   3
  ```

*/

/*
 
  #### Converting Characters to Crate IDs

  Now that we've got our `offset` into the line and `stackIdx`, all
  that remains is to convert the character at that offset into one of
  our `enum` values.  Here's the code to do that:

*/
      
      const char = line[offset];
      if (char != " ") {  // blank means no crate here
        Stacks[stackIdx].pushBack(char: crateID);
      }

/*

  We start by capturing the substring of `line` at `offset` into a
  variable named `char`—really a string storing a single letter.  Then
  we check to see whether the character is a blank, which would
  indicate a stack that has no more crates in it.  If it is not, we
  cast the character to a `crateID` and append it to the
  corresponding stack.  Piece of cake.

  All that remains is to return our array of stacks:

*/
    }
  }

  return Stacks;
}

/*

  and do the actual computation from the top of this article (which
  seemed relatively simple by comparison, wouldn't you agree?).

  Even though this input parsing was tricky, Chapel's support for
  zippered iteration, strided ranges, unbounded ranges, references,
  and string-to-enum casts makes it not so bad.  There are plenty of
  places to make off-by-one errors or get an index wrong, but Chapel's
  execution-time bounds-checking made working through them not so bad
  in practice.

  {{< details summary="**(A Parting Note on Printing Enums...)**" >}}

  Speaking of enums and strings, recall that way back at the top of
  the program, we printed out our crates using:

  ```chapel
  for stack in Stacks {
    write(stack.last);
  }
  writeln();
  ```

  At the time, we hadn't really discussed what type we were storing in
  our stacks, and the computation itself didn't really care.  Now that
  we know we were storing stacks of enums, this demonstrates a nice
  property of Chapel enums: that they can be printed out.
  Specifically, if our final conceptual configuration was:

  ```
          [D]
          [N]
          [Z]
  [M] [C] [P]
   1   2   3

  ```

  This loop would print out the values `crateID.M`, `crateID.C`, and
  `crateID.D` stored at the tops of the stacks, which would render as:

  ```
  MCD
  ```

  Pretty nice!

  {{< /details >}}

*/


/*
  ### Summary and Tips for Part Two

  And that's our solution to part one of day three!  If you understand
  the code in this post (available for download at the top of this
  post or [at
  GitHub](https://github.com/chapel-lang/chapel/blob/main/test/studies/adventOfCode/2022/day05/bradc/day05.chpl)),
  you have all the tools you need to complete part two.  As a hint, as
  you pop values from one stack, you can append them to a temporary
  list.  Then pop the values from the temporary list onto the
  destination stack to reverse their order.  Alternatively,
  `list.getAndRemove()` takes an integer argument and will return the
  element at that position in the list.  See the [`List` module
  documentation](https://chapel-lang.org/docs/modules/standard/List.html)
  for further information about using lists.

  Thank you for reading this blog post, and feel free to make comments
  or ask questions by creating a thread in the new [Chapel Blog
  Discourse Category](https://chapel.discourse.group/c/blog/21).

  ### Updates to this article

{{< changetable >}}
  | Date         | Change                                                      |
  |:-------------|:----------------------------------------------------------------------------------|
  | Feb 5, 2023  | Updated to reflect changes to the `list` interface |

*/
