// Advent of Code 2022, Day 4: Finding Overlaps in Cleanup Ranges
// tags: ["Advent of Code", "How-To"]
// series: ["Advent of Code 2022"]
// summary: "A couple of succinct solutions to day four of AoC 2022.  Learn about formatted IO, ranges, and parallel reductions in Chapel as well as some general problem-solving approaches."
// authors: ["Michelle Strout"]
// date: 2022-12-04

/*

Welcome to day 4 of Chapel's Advent of Code 2022 series!
For more context, check out our introductory [Advent of
Code 2022: Twelve Days of Chapel]({{< relref "aoc2022-day00-intro" >}}) blog
article for context or instructions on compiling this code.

### The Task at Hand and My Approach

In brief, [the challenge for
today](https://adventofcode.com/2022/day/4) is to read in a series of
range pairs representing work assignments and determine how many of those assignments
are subsets of one another for part 1 and how many overlap at all for part 2.
An example range pair is `24-42,30-42`.  The first elf in the pair
is assigned to clean up the range of sections `24-42` in camp, and the second
elf is assigned the range of sections `30-42`.  The second range is a subset of
the first range, so would be counted for both part 1 and part 2 of this challenge.

**Here is the recommended, parallelized approach that we get to at the end of
this blog.**
{{< whole_file_min >}}

Chapel's formatted IO made the code to read in the data for this challenge very
succinct.  In this post, I discuss how Chapel's formatted IO works, especially
within the context of the day 4 challenge.  I also talk about some general
problem-solving strategies and how they can be applied to this AoC challenge,
including examples that show how the Chapel range feature is an excellent
conceptual fit to solve this problem.  I wrap up showing how to parallelize a
Chapel solution to day 4.

*/

/*
### First Solution: Hand-coded Interval Arithmetic
Here is a succinct solution for both parts in Chapel.

```Chapel
use IO;

var sumSubset = 0;
var sumOverlap = 0;
var s1, e1, s2, e2: int;

while readf("%i-%i,%i-%i", s1, e1, s2, e2) {
  // Check if the second section assignment is a subset
  // of the first or vice versa.
  if (s1<=s2 && e2<=e1) || (s2<=s1 && e1<=e2) {
    sumSubset+= 1;
  }
  // Partial overlap: if both starts are less than
  // the other end, then we have overlap
  if s1<=e2 && s2<=e1 {
    sumOverlap += 1;
  }
}

writeln("sumSubset = ", sumSubset);
writeln("sumOverlap = ", sumOverlap);
```

[Formatted IO](https://chapel-lang.org/docs/main/modules/standard/IO/FormattedIO.html)
is what makes reading/parsing the input so easy.  The call to
```Chapel
readf("%i-%i,%i-%i", s1, e1, s2, e2)
```
does all of the work!  See [the blog post for day
1]({{< relref "aoc2022-day01-calories" >}}) for more information about the `use IO;`
statement that enables us to use the `readf` procedure.  The procedure `readf`
will try to read the given formatted string (e.g., `"%i-%i,%i-%i"`) from
standard input into the provided variables, much like `scanf` works in the C
programming language.  The `%i`s indicate integer values of any number of
digits. The `-` and `,` are the dash and comma characters respectively and will
be matched directly.  Whitespace is just ignored between calls to `readf`.
Since `readf` returns false when it can't match the format or when it sees an
end-of-file (EOF), we can use `readf` in a `while` loop to gather all of our
input.

{{< details summary="**(More examples of using Chapel's formatted IO for AOC 2022...)**" >}}
For the day 1 challenge of calorie counting, `readf` could have been used to
read in the integers.  However, this approach wouldn't have been that helpful for the
challenge, because the empty line between groups of integers would just be ignored.
```Chapel
use IO;
var num : int;
while readf("%i", num) {
  writeln("num = ", num);
}
```

Here is how `readf`
was used to read in the "character space character"
format used for the rock, paper, and scissors
[challenge from day 2]({{< relref "aoc2022-day02-rochambeau" >}}).
```Chapel
use IO;
var abc, xyz : string;
while readf("%s %s", abc, xyz) {
  writeln("abc = ", abc, ", xyz = ", xyz);
}
```
The `%s` format character will read characters into the given variable
until a whitespace character is reached.

The `readf` procedure can also be used for the day 3 input, but it isn't as exciting
or necessary since iterating over the strings provided by `stdin.lines()` or `readLine()` also
works.
```Chapel
use IO;
var line : string;
while readf("%s", line) {
  writeln("line = ", line);
}
```

{{< /details >}}
*/

/*
Once we are able to read in the problem input, we can work on solving the
problem.  My go-to approach for solving any programming problem is to think
about how the current problem is similar to problems I have seen in the past.
[Yesterday's advent of code problem]({{< relref "aoc2022-day03-rucksacks" >}}) involved
determining what item showed up in two different compartments of a rucksack.
Putting the items in the first compartment into a set and then checking if any
of the items in the second compartment are in that set was an approach that
worked well.  We could do that approach here, but it would be inefficient
because today's problem has more structure.  Specifically, the set of sections
each elf has been assigned to clean is being specified with a range `a-b`,
where we know all of the integers between `a` and `b`, inclusive,
are in the set.  Because of that, we can avoid putting all of
those integers explicitly into a set to check for subsetting and partial
overlap.  Instead, we can rely on the mathematical properties of the range.

Finding out how to leverage existing structure in problems is an important
problem-solving technique.  You can start out considering the whole space of
possible inputs and solutions to a problem, and then use the structure of the
problem to prune that space. In other words, some of the possibilities are
going to result in the same answer, so we don't have to code the answer for all
possibilities.

For today's problems, we are comparing two ranges/intervals
for each pair of elves to determine if one range is a subet of another for part
1 and to determine if there is any overlap for part 2.  The code above reads
the start and end of the ranges into variables so that _[s1,e1]_ is the first
range and _[s2,e2]_ is the second range.  The _[s1,e1]_ notation indicates a
set with the numbers _s1_ through _e1_ including _s1_ and _e1_.  There are 48
possibilities for the relationships between the `s1`, `e1`, `s2`, and `e2`
values, assuming that _s1<=e1_ and _s2<=e2_ (e.g., s1<e1<s2<e2, s1==e1<s2<e2,
...).  To solve part 1, we can check if the second range is a subset of the
first with `(s1<=s2 && e2<=e1)`, or if the first range is a subset of the second
with `(s2<=s1 && e1<=e2)`.  To solve part 2, we can just check if the start of
the first range is less than or equal to the end of the second range and the
second range start is less than or equal to the first range end, `s1<=e2 &&
s2<=e1`.  Deriving this condition takes some reasoning about all possible 48
input conditions and which groups of them end up with the same answer.
*/

/*
### Second Solution: Range-based Approach
This solution uses Chapel ranges to reason about whether there are subsets or overlap.

There are lots of applications that involve reasoning about overlapping
ranges/intervals (i.e., interval arithmetic).
In Chapel, there is a built-in abstraction called a 'range' that makes computing
on ranges/intervals even easier.
Chapel ranges were developed with High Performance Computing (HPC) applications
in mind, like Adaptive Mesh Refinement (AMR), where it is important to determine
the intersections/overlaps of grids that model physical phenomena.

The code below shows the creation of a range representing each elf's cleanup
assignment.  Then we can use the `contains()` method to determine if one range
is a superset of another one, and the range slicing operator to determine if
there is any overlap.  Determining whether one range contains a specific
index—or an entire range of indices as is done here—is a common operation to want
to do in interval computations. The range's built-in `contains` method supports
such queries out of the box.  Then the expression `r1[r2]` _slices_ the `r1`
range with the `r2` range.  This is equivalent to range intersection and is
discussed in
more depth in the
[Chapel range documentation](https://chapel-lang.org/docs/main/primers/ranges.html?highlight=slicing#range-slicing-intersection).
*/


/*
```Chapel
use IO;

var sumSubset = 0;
var sumOverlap = 0;
var s1, e1, s2, e2: int;

sumSubset = 0;
sumOverlap = 0;
while readf("%i-%i,%i-%i", s1, e1, s2, e2) {
  // Initialize a Chapel range for each elf
  var r1 = s1..e1;
  var r2 = s2..e2;

  // Check if the second section assignment is a subset
  // of the first or vice versa.
  if r1.contains(r2) || r2.contains(r1) {
    sumSubset += 1;
  }
  // Partial overlap occurs if the intersection of the ranges is non-empty
  const intersection = r1[r2];
  if intersection.size>0 {
    sumOverlap += 1;
  }
}

writeln("sumSubset = ", sumSubset);
writeln("sumOverlap = ", sumOverlap);
```
*/

/*
### Third Solution: Parallel Approach
Now let's look at creating a parallel solution.  This means that distinct
portions of the computation will be computed simultaneously to reduce overall
execution time.  Parallelization is important because today's computing
processors all have multiple cores, perhaps even dozens or hundreds, so without
parallel computations, a large amount of a system's processing power may go
unutilized.  The Chapel programming language was designed from the ground up to
express parallelism (and locality, which is critical for high performance).

The example problem has quite a bit of inherent parallelism: we could
potentially read the lines of input in parallel, and determining if each pair is
a subset or overlaps can both be done in parallel.  In the provided solutions,
reading the input file in parallel is out of scope for this blog article.  With
Chapel, it is easy to expose the parallelism available for determining the
subsets and overlaps.  To do this, we create an array using an iterator (see
the [day 2 blog post]({{< relref "aoc2022-day02-rochambeau" >}}) where it talks about
iterators).  This is a super-powerful way to create an array without having to
compute how many entries will be in the array ahead of time.
*/
  use IO;
  // Chapel iterator that reads in all lines from standard input
  // and yields 2-tuples of ranges.
  // Assumes that all lines are in the format "%i-%i,%i-%i".
  iter readSections() {
    var s1, e1, s2, e2: int;
    while readf("%i-%i,%i-%i", s1, e1, s2, e2) {
      yield (s1..e1, s2..e2);
    }
  }
  // Creates an array with all elements yielded
  // by the `readSections` iterator.
  var sections = readSections();

/*
Once we have an array, Chapel has built in ways to do a parallel `forall`
loop over that array.

When parallelizing computations, we do have to ask the question "Is this loop
actually parallel?".  The below `forall` loop isn't fully parallel.  Fully
parallel is when all of the iterations of the loop can be executed at the same
time and you will get the same answer.  But the loop does have a common pattern
called a _reduction_.  We can't overlap (aside: parallel computing requires
reasoning about intervals/ranges as well!!) the increments to the sum variables
because if one iteration reads between the read and write of another then we
have problems.  However, addition is associative and commutative.  Associative
means the expressions being added up can all be evaluated in parallel, but then
the summation of the results needs to happen in order.  Commutative means we
can do the additions in any order.  Chapel can leverage reduction parallelism
for associative and commutative operators such as addition.
The second phrase of the `forall` loop
```Chapel
with (+ reduce sumSubset, + reduce sumOverlap)
```
indicates that summations are being done on the `sumSubset` and `sumOverlap`
variables.
*/
  // Parallel reduction to add up the number of subsets and the number of overlaps.
  var sumSubset = 0;
  var sumOverlap = 0;
  forall (r1,r2) in sections with (+ reduce sumSubset, + reduce sumOverlap) {
    sumSubset += r1.contains(r2) || r2.contains(r1);
    const intersection = r1[r2];
    sumOverlap += intersection.size > 0;
  }

  writeln("sumSubset = ", sumSubset);
  writeln("sumOverlap = ", sumOverlap);

/*

A challenge to parallelizing AoC codes, particularly during these
early days, is that the computations are simple enough that the
running time tends to be dominated by the overheads of reading the
input from, and writing the results to, the console.  In addition, if
the problem size is not big enough, the overheads of creating
parallelism and computing the reduction can also weigh down a parallel
execution.  In contrast, in the real-world HPC problems for which
Chapel was designed, the computational intensity and data set sizes
tend to require parallelism to be accomplished in any
reasonable time at all.  All that said, with a big enough dataset, and
compiling the code using the Chapel compiler's `--fast` flag, today's
parallel solution can be shown to outperform the serial range-based
approach on my laptop.  Parallelism for the win!

*/

/*
### Summary

That wraps up this fourth day of introducing Chapel through AoC 2022.
The full code for these solutions can be browsed and downloaded from
https://github.com/mstrout/adventOfCode2022.
Thank you for reading this blog post, and feel free to make comments or ask
questions by creating a thread in the
[Chapel Blog Discourse Category](https://chapel.discourse.group/c/blog/21).
*/
