// Advent of Code 2022, Day 10: Scan Lines
// authors: ["Daniel Fedorin"]
// summary: "A solution to day ten of AoC 2022, introducing `scan` expressions."
// tags: ["Advent of Code", "How-To"]
// series: ["Advent of Code 2022"]
// date: 2022-12-14

/*
  Welcome to day 10 of Chapel's Advent of Code 2022 series. Having taken a little
  break for the weekend, we're ready to dive into the remaining three problems
  in our [Twelve Days of Chapel]({{< relref "aoc2022-day00-intro" >}}). Check
  out that linked introductory post if you would like more context on the
  series!
 */

/*
  ### The Task at Hand and My Approach
  It wouldn't be Advent of Code without a [problem](https://adventofcode.com/2016/day/12)
  [involving](https://adventofcode.com/2017/day/18) [some](https://adventofcode.com/2018/day/16)
  [virtual](https://adventofcode.com/2019/day/5) [machine](https://adventofcode.com/2021/day/24). In [today's challenge](https://adventofcode.com/2022/day/10),
  we are given a virtual computer with a single register (memory cell) `X`, and two operations:
  `addx` and `noop`. The `addx` operation is used to add a number to the
  `X` register (subtractions can be achieved by adding negative numbers to `X`),
  and `noop` does nothing. Each instruction takes some time to execute: the
  `noop` instruction takes one step, while `addx` takes two steps. We are tasked
  with determining the values of the register `X` at particular times, which
  realistically means we have to figure out what `X` is equal to after every
  step.

  My approach for this problem uses concepts that we've already covered
  in previous articles, with the notable exceptions of _scan expressions_
  and _array reshaping_. By expressing our computation as a scan, we can elegantly solve the first
  part of today's puzzle. Chapel's `scan` expressions, just like its `reduce`
  expressions, are executed in parallel, so our solution immediately benefits from Chapel's
  multitasking capabilities. Array reshaping leads to some very clean code
  when it comes to drawing the output of the CRT monitor for part two. 

  **If you are a fan of palindromes, here is the complete solution for the day:**
  {{< whole_file_min >}}

  As usual, before we begin, let's bring in our old friend, the `IO` module.
 */
use IO;

/* And now, onward to our first task --- parsing! */

/*
  ### An Iterator to Represent Operations
  The first order of business is to read in the puzzle input, and turn it into
  a representation that is convenient for simulating the tiny virtual computer.
  The instructions we're reading look like this:

  ```text
  noop
  addx 3
  addx -5
  ```

  In the world of our little processor, only one thing can change at any
  given step: the value of `X` can go up or down by a certain amount. We can therefore represent
  the effects of the `noop` and `addx` instructions as a
  {{< sidenote "right" "simple list of integers:" >}}
  I think there's a curious analogy between the integers we create and
  CPU [micro-operations](https://en.wikipedia.org/wiki/Micro-operation).
  Just like a CPU might break down complex instructions into smaller ones, we
  break individual operations like `noop` and `addx` into
  smaller pieces (changes to the register).
  {{< /sidenote >}} each integer will indicate that one step took place, and that
  during that step, the register `X` changed by the amount stored in
  the integer. Let's call such a change to `X` a _delta_. My solution defines
  an iterator that reads input from the console and yields deltas.
*/

iter ops() {
  yield 1; // Initial state
  for line in stdin.lines().strip() {
    select line[0..3] {
      when "noop" do yield 0;
      when "addx" {
        yield 0;
        yield line[5..] : int;
      }
    }
  }
}

/*
  The first statement in the iterator is a `yield` that produces
  a fixed value of `1`. As indicated by the comment, this encodes the initial
  state of the CPU. This first value will end up --- unchanged --- in the very beginning of our history of
  values of `X`. If we wanted the CPU to start at `100` instead of `1`, we
  could simply change this statement to `yield 100;`.

  Next, my solution iterates over every line in the input. Here I use
  `stdin.lines()`, which is an iterator that yields a single string for each
  line from the program's input stream. These strings contain the newline
  character `\n`, which I don't want; I get rid of it by calling the `strip()`
  method on each string. Note that it looks like I'm calling `strip()` on the iterator,
  `stdin.lines()`, itself --- this is another example of promotion in Chapel. We
  first covered promotion in [our day 2 article]({{< relref "aoc2022-day02-rochambeau#argument-promotion" >}}).

  For each line of input, what's yielded depends on the instruction; we can
  identify the instruction by its first four characters, which I retrieve
  by slicing the line (see the [day 3 article]({{< relref "aoc2022-day03-rucksacks#ranges-and-slicing" >}}) for
  an introduction to slicing). From there, the two options are:
    * In the `noop` case, a single step transpires. During this step, the value
      of `X` does not change, and so a single integer `0` is yielded.
    * In the `addx n` case, two steps transpire. During the first step, the
      `addx` instruction is still running, so the state doesn't change, and
      the iterator yields `0`. During the second step, however, the instruction
      completes, and the register is changed by the amount listed in the operation, `n`.
      I use more slicing and an integer cast to retrieve the part of the string
      after the `addx` and convert it to an integer.

  That completes the iterator of deltas, `ops`. For a set of instructions
  like the ones in the problem statement:
  ```text
  noop
  addx 3
  addx -5
  ```

  the following integers would be yielded by `ops`:
  ```text
  1 0 0 3 0 -5
  ```

  ### Using Scans to Compute Values of `X` at Every State

  How do we go from a series of deltas to a series of register values? It's
  pretty easy: to get the value of `X` after a certain number of steps,
  we just have to sum up all the changes that have happened so far. Thus,
  for the initial state, we just take the first element yielded by `ops`;
  for the second state we sum the first two elements; for the third, we sum
  up the first three. The words "summing" might evoke memories of `+ reduce`,
  and these memories would be on the right track. However, there's a difference
  between what we can get with `+ reduce` and what we need: reductions compute
  a single value from an iterable, whereas we want to have a whole array of items,
  each representing reductions over some prefix of a sequence!

  This is where Chapel's `scan` expressions come in. They do exactly what
  I just described above: given an iterable and a binary operation, they compute
  and yield partial reductions up to and including each element. For example,
  take the following array:

  ```Chapel
  var A = [1, 2, 3, 4];
  ```

  We can apply a `+ scan` to compute partial sums of its elements:

  ```Chapel
  writeln(+ scan A); // Prints 1 3 6 10
  ```

  We can also use a `* scan` to compute the factorials of the numbers `1` through
  `4`:

  ```Chapel
  writeln(* scan A); // Prints 1 2 6 24
  ```

  Note that although the answer is the same, the way `scan` performs the
  factorial computation above is **not the same** as writing something like
  the following:

  ```Chapel
  writeln([i in A.domain] * reduce A[..i]); // Prints 1 2 6 24
  ```

  In this last snippet, for each index of `A`, we use a `* reduce` to compute
  the partial product of the elements up to that index.
  The difference is that scans don't do extra work; the sum for the first three elements,
  for instance, can be computed just by adding the third element to the sum
  of the first two. Thus, there's no need to re-run a reduction for each prefix:
  the result can be computed incrementally.

  It gets even better: just as `reduce` expressions are parallel operations in
  Chapel, so too are `scan` expressions. Even though it seems like
  computing partial sums is a serial algorithm ("add 1, then add 2, then add 3..."),
  the following code is **also not how `scan` operates:**

  ```Chapel
  for i in A.indices[..<A.size-1] do
    A[i+1] *= A[i];
  ```

  Whereas that last snippet of code is serial, there are ways to break scans
  into concurrent pieces (see the [Parallel Algorithms](https://en.wikipedia.org/wiki/Prefix_sum#Parallel_algorithms)
  section on Wikipedia's page on prefix sums), and Chapel applies such techniques. Thus, we get cleaner code and
  better performance --- nice!

  We can apply a `+ scan` to our `ops()` iterator to create a sequence of
  partial sums. These partial sums, as we have discussed, work out to be the
  values of `X` at each step. I perform the computation as follows:
*/

const deltas = ops(),
      cycles = deltas.size,
      Xs: [1..cycles] int = + scan deltas,
/*
  In this snippet, I first collect the output of the iterator into an array,
  `deltas`. I then retrieve the array's size into another variable, `cycles`.
  Finally, I use a `+ scan` on `deltas` to compute the partial sums, storing
  the result into a new array `Xs`. By default, this new array `Xs` would be
  0-indexed just like the `deltas` array it's computed from. However, the
  problem statement starts counting CPU steps at 1 (i.e., it's 1-indexed).
  I therefore explicitly specify the domain of `Xs` to be `1..cycles`, which
  makes it use 1-indexing and helps me write cleaner code down the line.
 */
/*
  ### Slicing and Operator Promotion to Compute Signal Strengths

  The next thing we need to do is to compute the signal strengths at six
  different indices. The problem asks for strengths at 20, 60, 100, 140, 180,
  and 220. The first step we can take is notice that the numbers go up by 40
  each time, and express them as a range:
*/
      interesting = 20..220 by 40;
/*
  This way of representing the interesting indices is both more concise and less error-prone:
  we only have to keep track of three constants instead of six. Also, because
  `interesting` is a range, we can use slicing to get the values of `Xs` at each
  of the required time steps. This would look like:

  ```Chapel
  writeln(Xs[interesting]); // Prints 21 19 18 21 16 18 for sample input
  ```

  In the above statement, we took advantage of the fact that we declared `Xs`
  to be 1-indexed instead of 0-indexed. The `interesting` range is built
  based on the problem description, which counts from one, making its indices
  a perfect match for the 1-based `Xs` array.

  The values of the register `X` are _not_ signal strengths, though! To compute
  the signal strengths, we must multiply the value of `X` at a particular step
  by the number of that step. Fortunately, we already have both ingredients
  for computing signal strengths: the six values of `X`
  (in `Xs[interesting]`) as well as the indices of these six values (in
  `interesting` itself). We can multiply these two lists of values element-by-element
  --- thus computing the desired signal strengths -- by using Chapel's
  operator promotion (first seen in our [day 8 article]({{< relref "aoc2022-day08-treehouse#using-promotions-and-reductions-to-compute-visibility" >}})).

  ```Chapel
  writeln(Xs[interesting] * interesting);
  // Prints 420 1140 1800 2940 2880 3960 for sample input
  ```

  All that's left is to sum up the signal strengths, which we can do using
  a reduction.

 */
writeln(+ reduce (Xs[interesting] * interesting));

/*
  That's our answer to part one!

  ### Displaying the CRT Output
  In part two, we discover that the value of the register is actually moving
  a three-pixel sprite. A CRT monitor, which is drawing on a screen pixel-by-pixel,
  draws a `#` if the current column overlaps with the sprite's position, and a `.` if the
  current column does not.

  The first thing I do is encode the information about the CRT into a few helper
  variables. I made the variables `config const`s (first seen in our [day 6 article]({{< relref "aoc2022-day06-packets#a-config-declaration-for-the-marker-length" >}}))
  so that it's possible to change the CRT's size from the command line.
 */
config const crtRows = 6,
             crtCols = 40;

/*
  I then use the information to create a new two-dimensional domain
  representing the possible pixel positions on the CRT's screen.
 */

const Screen = {0..<crtRows, 0..<crtCols};

/*
  Iterating over `Screen` would give us the positions (row and column) of each
  pixel that the CRT draws, in order. It would be nice to associate the
  corresponding value of the register `X` (i.e., the location of the sprite)
  with each of these scan positions. To do so, we can make use of Chapel's
  `reshape` function.

  Reshaping lets us "reorganize" the elements of an array:
  for instance, we could turn an 8-element one-dimensional array into a
  two-dimensional 2-by-4 array, or a three-dimensional 2-by-2-by-2 array.
  The elements of the resulting array are the same as those of the original.
  In the case of this problem, we want to arrange the sprite positions from
  `Xs` (a one-dimensional array) into the same shape as our CRT monitor,
  to match them up with each row and column.
 */

const spritePos = reshape(Xs[1..Screen.size], Screen);

/*
  In the above snippet, I use slicing to retrieve only the first `Screen.size`
  positions from `Xs`, since the puzzle input leaves us with slightly more steps
  than we need to draw the screen. Then, I call `reshape` with the resulting
  slice, and the `Screen` domain. This tells Chapel to make `spritePos`
  a two-dimensional array, with `crtRows` rows and `crtCols` columns, whose
  elements are taken from the first `crtRows * crtCols` sprite positions in `Xs`.
 */

/*
  Now: how do we know when the CRT's current column overlaps with the sprite?
  The sprite is three pixels wide, and centered at the value of the register
  `X` at a particular time step. Thus, a column overlaps with the sprite if
  it's no more than one pixel away from its center. We can express this in
  terms of an absolute value:

  ```Chapel
  abs(col - X) <= 1
  ```

  The above expression produces a boolean.  We can get the correct symbol from
  this boolean (`#` when it's `true`, or `.` when it's `false`) by using
  an if-expression:

  ```Chapel
  if abs(col - X) <= 1 then '#' else '.'
  ```

  Since we have just reshaped our `Xs` into a two-dimensional array matching
  our `Screen`, we can figure out the value of `X` simply by accessing that
  array at a particular row and column:

  ```Chapel
  if abs(col - spritePos[row, col]) <= 1 then '#' else '.'
  ```

  That last piece of code gives us the value of a particular pixel in the
  CRT monitor. All that's left is to compute the value of _every_ pixel in
  the monitor. We can accomplish this using a parallel loop expression
  (which we covered in [our day 6 article]({{< relref "aoc2022-day06-packets#parallel-loop-expressions" >}})).
 */

const pixels = [(row, col) in Screen]
  if abs(col - spritePos[row, col]) <= 1 then "#" else ".";
writeln(pixels);

/*
  Since Chapel knows the `pixels` variable is in the shape of `Screen`, it knows
  to print it line-by-line, and we get our desired output.
 */

/*
  ### Summary
  That's it for both parts of today's solution! This time, we used `scan`
  expressions to elegantly compute partial sums of an array (though they can
  be used to compute any partial reduction). We also made use of `reshape`
  to rearrange a one-dimensional array into a more desirable form --- one that
  matched up directly with our two-dimensional CRT screen.

  Our solution is automatically parallel because of the `scan` and
  the loop expression we used to define our `pixels` variable.
  This once again highlights Chapel's power: we expressed our solution using
  natural, high-level patterns, and the language took care of making them
  parallel.

  Thanks for reading! Please feel free
  to ask any questions or post any comments you have in the new [Blog
  Category](https://chapel.discourse.group/c/blog/21) of Chapel's
  Discourse Page.
*/
