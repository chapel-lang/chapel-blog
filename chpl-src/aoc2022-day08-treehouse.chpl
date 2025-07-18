// Advent of Code 2022, Day 8: Hiding Treehouses
// authors: ["Brad Chamberlain"]
// summary: "A solution to day eight of AoC 2022, introducing domains and multidimensional arrays."
// tags: ["Advent of Code", "How-To"]
// series: ["Advent of Code 2022"]
// date: 2022-12-08

/*

  Here we are on day 8 of Advent of Code 2022, two-thirds of the way
  through our 'Twelve Days of Chapel AoC' series!  If you're new to
  the series, check out the [introductory
  article]({{< relref "aoc2022-day00-intro" >}}) for more context.

*/

/*
  ### The Task at Hand and My Approach

  In [part one of today's
  puzzle](https://adventofcode.com/2022/day/8), we're given a
  2-dimensional (2D) grid of integers, representing the heights of
  trees in a very dense, regular forest.  Our goal is to determine how
  many trees are visible from outside the forest by looking for lines
  of sight to each tree along the rows or columns of trees.
  Essentially, starting from a given tree, if you can walk directly to
  the edge of the forest encountering only trees that are shorter,
  your starting tree is visible.

  To accomplish this, I'm going to use a 2D array to represent the
  forest, which will be the first higher-dimensional Chapel array
  we've seen in this series.  I'll also be introducing the concept of
  the _domain_, which is Chapel's way of representing sets of indices
  that can be used for declaring arrays or describing iteration
  spaces.  I'll also make use of slicing, reductions, and promotion,
  which we've seen in earlier articles.

  **For those who looked in their parents' closets for presents before holidays, here's my full solution for today:**
  {{< whole_file_min >}}

  The code for this one's going to be short and sweet, so let's get
  into it.

*/

/*

  ### Reading the Forest Input

  Here, I'm going to take the approach we've used in a lot of these
  articles, of writing an iterator that reads and yields lines,
  storing them as an inferred-size array named `Lines`:

*/

const Lines = readLines();

iter readLines() {
  use IO;

  var line: string;
  while readLine(line, stripNewline=true) do
    yield line;
}

/*

  If you've been following this series, you might notice a few
  differences between this code and my last such routine on [day
  5]({{< relref "aoc2022-day05-cratestacks#reading-the-initial-state-of-the-stacks" >}}).
  Specifically:

  * I moved my `use IO;` statement into the iterator itself.  The
    `use` statement only makes its module's contents available to the
    scope that contains it, and this is the only scope in which I need
    to access symbols from 'IO'.  So I move it from the file's module
    scope to this local scope in order to not pollute the namespace of
    the whole program with symbols that won't be needed.

  * I've also used the optional `stripNewline` argument provided by
    the `readLine()` routine, which tells it to remove the terminating
    newline character (`\n`) before storing a line of input into
    `line`.  Note that identifying the argument name, as I've done
    here with `stripNewline=`, is not necessary; however, it makes the
    call more self-documenting than if I'd simply written
    `readLine(line, true)`.

  After executing these statements, `Lines` will be a 1-dimensional
  (1D) 0-based array of strings, with each `string` value representing
  one line from the file (or, a row of trees in our forest).

*/

/*

  ### Storing the Forest in a 2D Array

  Up until this point in the series, we have used arrays frequently,
  but only 1D arrays.  Because Chapel was designed for scientific
  computing, where modeling the physical world often involves
  multidimensional data sets, it also supports n-dimensional arrays,
  as in NumPy or Fortran.  Such arrays are notably absent from C, C++,
  Java, and the like, which support arrays-of-arrays, yet don't have a
  language-supported way to represent a dynamically-sized,
  n-dimensional array using a contiguous block of memory.  Doing so
  enables elements to be traversed along any dimension by walking a
  pointer through memory using a fixed stride.  This can be important
  for efficiency in applications using nD arrays.

  For this program, a 2D array is a very natural representation of the
  forest data, since it will permit us to focus on data along rows or
  columns, as desired.  Of course, we could do the computation
  directly on the input array of strings; but as we will see, using
  the 2D array permits us to make use of _slicing_ in interesting
  ways.

  First, I declare a pair of integer constants representing the number
  of rows and columns in the forest:

*/

const numRows = Lines.size,
      numCols = Lines.first.size;

/*

  I compute the number of rows (`numRows`) by querying the size of my
  array of lines that I read in—effectively, the number of lines in
  the file.  Then I take the size of the first line from the file (the
  number of characters or _codepoints_ it is storing), which serves as
  the number of columns (`numCols`).  Note that I'm assuming that all
  lines have the same length.  I can safely make this assumption since
  it is true of the AoC input sets.  Because of this, I could have
  equivalently checked the size of `Lines.last` or `Lines[i]` for any
  value of `i` in `0..<numRows` instead.

  #### Domains: First-class Index Sets

  All arrays in Chapel are defined over a concept known as a _domain_.
  A Chapel domain is a language feature representing a set of indices.
  These indices can be used for a variety of purposes, such as
  defining the indices of an array or an array slice, or serving as
  the iterand for a loop.

  Up until now, the 1D arrays we've declared have had their indices
  defined using a range.  For instance, we've seen declarations like:

  ```chapel
  var A: [1..1000] int;
  ```

  Though ranges are not domains themselves, they are used to build
  rectangular domains of 1 or more dimensions.  As a convenience, they
  can be used to create domains when used in array declarations like
  this.  Specifically, for this declaration of `A`, the compiler will
  introduce an _anonymous domain_ representing the indices `1..1000`.
  Domain literals in Chapel are represented by specifying the indices
  within curly brackets, and if we were to type out the domain's
  value, it would look like `{1..1000}`.  Like ranges, domains can be
  named, so we could write:

  ```chapel
  const D = {1..1000};
  ```

  This declares a 1D domain named `D`, representing the indices `1`
  through `1000`, inclusive.  A named domain can also be used to
  specify an array's indices, like so:

  ```chapel
  var B: [D] string;
  ```

  which would give us an array of 1000 strings, indexed using
  `1..1000`.

  Multidimensional rectangular domains are defined using a list of
  ranges. For example, here is a 3D domain whose size in each
  dimension is defined by the variables `m`, `n`, and `o`
  respectively:

  ```chapel
  var D3 = {1..m, 1..n, 1..o};
  ```

  If we wanted to declare an array over this set of indices, we could
  do it in any of the following ways:

  ```chapel
  var A: [D3] int;
  var B: [{1..m, 1..n, 1..o}] int;
  var C: [1..m, 1..n, 1..o] int;
  ```

  Note that these three forms are equivalent, and that the curly
  brackets used in `B`'s declaration are unnecessary.  In practice, we
  typically omit them for brevity, as in our 1D array declarations up
  to this point.  One motivation for naming domains is that it permits
  them to be reused within the code rather than typing the raw indices
  over and over again, reducing the chances of mistakes.  For example,
  we can write a parallel loop over the indices of these arrays as
  follows:

  ```chapel
  forall (i,j,k) in D3 do
    A[i,j,k] = B[i,j,k] * C[i,j,k];
  ```

  Since D3 is a 3-dimensional domain, loops over it will yield 3-tuple
  indices.  Here, I am de-tupling them into their respective integer
  components, naming them `i`, `j`, and `k`.  We can then index into
  our arrays using the three integers, separated by commas in the
  normal square brackets used for indexing.

  Chapel's arrays can also be accessed using tuple indices.  So if we
  were to store the indices yielded by `D3` using a single loop
  index variable, we could write:

  ```chapel
  forall idx in D3 do
    A[idx] = B[idx] * C[idx];
  ```

  Note that `idx` is a 3-tuple of `int`s in this loop.

  {{< details summary="**(A sidebar on promotion and operators...)**" >}}

  Before going on, note that multidimensional arrays can be used to
  promote a scalar function, just as we've done with 1D arrays earlier
  in this series.  In addition, scalar operators are able to be
  promoted just as scalar procedures are.  Thus, the loop above could
  be written:

  ```chapel
  A = B * C;
  ```

  which promotes the scalar `*` operator supported on pairs of
  integers across all corresponding elements of `B` and `C`,
  generating an array's worth of results.  As with other promotions
  we've seen, this loop can be thought of as the equivalent to:

  ```chapel
  forall (a, b, c) in zip(A, B, C) do
    a = b * c;
  ```

  which in turn is equivalent to our previous domain-based loops that
  indexed into the arrays using triples of scalars or 3-tuples.  Which
  of these forms you choose typically is a mix of style preference and
  whether or not you require the loop indices within the loop's body
  (in which case, iterating over the domain is the way to go).

  {{< /details >}}

  #### Representing our Forest Using a Domain and Array

  We now have everything we need to create our domain and array.
  I start by declaring a 2D array in terms of the number of rows
  and columns we got from the input file:

*/

const ForestSpace = {0..<numRows, 0..<numCols};

/*

  I declare this as a constant because I have no intention of changing
  the domain's indices after it is initialized.  In practice, this
  provides useful semantic information to the compiler that can enable
  important optimizations.

  I named this domain because I want to loop over it in order to
  convert my 1D `Lines` input array into a 2D array.  By giving it a
  name, I avoid the need to repeat these range expressions again when
  I write that loop.  And by giving it a (somewhat) meaningful name, I
  potentially improve my code's readability compared to just using
  literal range and domain expressions.

  I chose to use 0-based indexing for this domain because that's what
  my `Lines` array and its `string` values will use.  That said, I
  don't end up using the numerical values of my indices at all after
  the next statement, so could nearly as easily have used 1-based
  indexing or any other indexing scheme that felt natural.

  At this point, I could declare my array as follows:

  ```chapel
  var Forest: [ForestSpace] int;
  ```

  However, since the first thing I want to do with the array is store
  my input data into it, I took a different approach:

*/

var Forest = [(r,c) in ForestSpace] Lines[r][c]:int;

/*

  As described in our [day
  6]({{< relref "aoc2022-day06-packets#parallel-loop-expressions" >}})
  article, `[idx in expr]` is a Chapel loop expression that is
  equivalent to `for[all] idx in expr`.  It will be parallel if `expr`
  supports parallel iteration and serial otherwise.  Like most
  built-in Chapel types, domains do support parallel iteration, so
  this declaration is equivalent to:

  ```chapel
  var Forest = forall (r,c) in ForestSpace do Lines[r][c]:int;
  ```

  which in turn is very similar to:

  ```chapel
  var Forest: [ForestSpace] int;
  forall (r, c) in ForestSpace do
    Forest[r, c] = Lines[r][c]:int;
  ```

  {{< details summary = "**(Why merely _similar to_ and not equivalent...?)**" >}}

  The difference between the first two declarations of `Forest` and
  the third is that they provide an initialization expression for the
  array at its declaration point.  This causes the array elements to
  be initialized with their corresponding values extracted from
  `Lines`.  In contrast, the third form does not initialize `Forest`,
  so Chapel will ensure that all of its `int` elements store their
  default value of 0.  Then, the loop statement that follows uses the
  assignment operator to store the values from `Lines` into the array
  elements.  The net effect will be the same in terms of the array's
  values, but technically each element is touched twice to get that
  result in the third form.

  {{< /details >}}

  In any of these forms, the loop's body is simply an indexing
  expression into my `Lines` array, first to pick out line `r` and
  then to pick out the `c`th character from that line's string.  I
  cast that character to an `int` in order to make the array store
  integer values that I can compare easily and cheaply.

  {{< details summary = "**(A note on string indexing...)**" >}}

  Throughout this series, I've occasionally mentioned that I've chosen
  to use a `bytes` value in order to avoid the potential overhead of
  string indexing.  Specifically, Chapel strings use a UTF-8 encoding,
  and UTF-8 is a format that generally requires scanning through the
  string's buffer from the start to find position `i` due to the fact
  that some characters or _codepoints_ require 1 byte while others
  require 2.  So why did I use a string here?

  The reason is because when a string is made up strictly of ASCII
  characters (as in today's challenge), all codepoints are known to be
  a single byte, so we can directly compute the address of a character
  and access it without scanning from the beginning.  Chapel optimizes
  accesses to ASCII-only strings in this way.

  This program happens to compute the right result if we change all
  `string` references to `bytes`, though the contents of the `Forest`
  array might surprise you.  If you were to print them out, rather
  than seeing the digits `1` through `9`, you would see the integer
  values of the ASCII characters `"1"` through `"9"` (namely, `48`
  through `57`).  The algorithm still works since we're only comparing
  the tree heights, and the ASCII values maintain the same ordering
  and stride.  But I worried this might be confusing to someone
  printing out the output.  Alternatively, we could have converted the
  ASCII values to `1` through `9` when storing them to this array, as
  in [day 3's
  solution]({{< relref "aoc2022-day03-rucksacks#computing-priorities-using-params-and-bytes" >}}),
  by subtracting the ASCII value of `0` from each when assigning it to
  `Forest`.

  {{< /details >}}

  Note that Chapel distinguishes very strictly between 2D arrays and
  1D arrays of 1D arrays (or in this case, 1D arrays of indexable,
  array-like types, such as strings).  For this reason, we could not
  write `Lines[r,c]` because `Lines` is not a 2D array or data
  structure.  Only `Lines[r]` or `Lines[r][c]` would be legal,
  returning a full-line string or a single-character string from a
  line, respectively..

  We store the result of this `[...]`-loop expression into the new
  inferred-type variable `Forest`.  When a variable is initialized
  with a `[...]`-loop like this, its domain is determined by the index
  set of the loop.  In this case, since `ForestSpace` defines that
  index set, it also serves as the domain for `Forest`.  Thus, this
  statement could have been written out more verbosely as:

  ```chapel
  var Forest: [ForestSpace] int = [(r,c) in ForestSpace] Lines[r][c]:int;
  ```

  {{< details summary = "**(A quick note on array types and `[...]` loops...)**" >}}

  Note that the syntax used for an array type (e.g., `[1..n] int`) is
  very similar to that used for a loop expression (e.g., `[i in 1..n]
  2*i`).  This is intentional in Chapel's design to emphasize the
  relationship between these expressions in type vs.  value contexts.
  For example, where the latter might be read

  > "For all indices i in 1 through n compute 2 times i."

  the former could be thought of as saying:

  > "For all indices in 1 through n store an integer variable."

  In fact, if the index variable is not needed by the loop's body, it
  may be omitted (this is also true of for- and forall-loops).  Thus
  `[1..3] writeln("Ha");` is a concise way of saying

  > "For all indices 1 through 3, print the string 'Ha'"

  This index-less form bears even greater resemblance to an array type
  expression like `[1..n] int`, where the index is similarly not
  necessary.

  {{< /details >}}

  At this point, we have our 2D array, `Forest`, of tree heights and
  are ready to compute on it.

*/

/*

  ### A Procedure for Computing a Tree's Visibility

  Next, let's look at my procedure for computing the visibility of a
  tree.  Here is its argument list:

*/

proc visible((r, c): 2*int, height: int) {

/*
  
  I declare this routine to take a 2-tuple of ints, `(r, c)`, which
  will serve as the row and column coordinates of the tree in
  question—essentially, an index from `TreeSpace`.  It also takes
  `height`, an `int` indicating the corresponding tree's height, for
  use in determining whether it's larger than its neighbors along any
  of the row- or column-based sight lines.

  Those who have been following this series may note that I've
  departed from my typical style of omitting the types for my
  procedures' formal arguments by declaring them here.  If you're
  curious, I'll explain why I did this a bit later.

  #### Using Slices to Refer to Subsets of the Forest

  First, let's focus on the body of the procedure.  We've introduced
  examples of _slicing_ in previous articles in this series, in which
  a range of indices is used to access a subset of elements in a
  `bytes` value, string, or array.  We'll be using slicing today to
  refer to subsets of the forest.  For example, the slice
  `Forest[0..r, 0..c]` would represent the sub-array of trees that are
  in the quadrant northwest of `(r,c)`, inclusive.

  For this computation, we will be looking at trees in the same row or
  column.  For example, the slice `Forest[0..<numRows, c]` would
  represent all trees in my column and `Forest[r, 0..<numCols]` would
  represent all those in my row.  These two slice expressions can be
  written in a more concise form, though, which is `Forest[r, ..]` and
  `Forest[.., c]`, respectively.  When an unbounded range is used in
  an array slicing expression, it uses the array's bounds in place of
  any missing range bounds.  Thus, rather than remembering whether
  `Forest` is 0-based or 1-based, or how many elements it has, I can
  use an unbounded range as a more mnemonic way to refer to sub-arrays
  of values.  This also often reduces the chances of errors.

  Of course, in this computation, we don't want the entire row or
  column of the forest, just the subset directly to the north, west,
  south, and east of the current tree.  These could be expressed using
  the slices:

  ```chapel
  ref north = Forest[ ..<r, c    ],  // all rows before mine in my column
      south = Forest[r+1.., c    ],  // all rows after mine in my column
      west  = Forest[    r, ..<c ],  // all columns before mine in my row
      east  = Forest[    r, c+1..];  // all columns after mine in my row
  ```

  (where the spacing here is not necessary or meaningful, but just
  used to align the dimensions).

  As before, I'm using unbounded ranges, but leaving only one of the
  two bounds unspecified.  As a result, missing low bounds will use 0,
  the array's low bound in each dimension; and missing high bounds
  will use `numRows` or `numCols`, respectively.  These four slice
  expressions describe the neighbors we must analyze.

  #### Using Promotions and Reductions to Compute Visibility

  Here's how I wrote the body of `visible()` itself:

*/
  
  return && reduce (Forest[..<r, c] < height) ||
         && reduce (Forest[r+1.., c] < height) ||
         && reduce (Forest[r, ..<c] < height) ||
         && reduce (Forest[r, c+1..] < height);
}

/*

  Note that I wrote the slice expressions directly rather than naming
  them and using those names here.  Either approach is fine, but I
  found I preferred seeing the slice expressions directly in the
  computation for some reason.

  I use the `<` operator to compare each of the four sight-line slices
  to my tree's height, `height`.  This is another instance of
  _operator promotion_ as described in the sidebar above.
  Specifically, the `<` operator takes two `int` arguments, yet I am
  passing it an array slice and an `int`.  As a result, an expression
  like:

  ```chapel
  Forest[..<r, c] < height
  ```

  can be thought of as equivalent to:

  ```chapel
  forall f in Forest[..<r, c] do (f < height)
  ```

  which in turn is equivalent to:

  ```chapel
  forall i in Forest.domain.low..<r do (Forest[i, c] < height)
  ```

  This computation could have been written in any of these equivalent
  ways if preferred.

  Because we are interested in whether all of the trees in these
  slices are shorter than ours, we use a _logical and_ (`&&`)
  reduction, which applies a boolean short-circuiting 'and' operation
  to the arguments.  This causes it to quit early if a single `false`
  is found, since there is no way for the result to become `true` at
  that point.  Then, because only one of the four directions is
  required to get visibility, we use the short-circuiting 'or'
  operation (`||`) to combine the results.  This means that if the
  tree is visible from any of the four directions, we don't need to
  check the other three.

  In this way, I've computed whether the tree at `(r, c)` is visible
  in a very succinct manner.  It may seem surprising that I didn't do
  any special handling of trees at the edge of the forest.  Let's look
  at why that is.

  The first thing to note is that for a tree on the border, like
  `(r=3, c=0)`, the slice that governs its west neighbors is
  `Forest[r, ..<c]` or `Forest[3, ..<0]` or `Forest[3, 0..<0]`.
  However, `0..<0` is a degenerate, or empty, range since there are no
  integers between `0` and `0` excluding `0`.  As a result, this slice
  is empty.

  That leads to the question "What do reductions do if they are
  applied to an empty collection of values?"  The answer is that they
  generate the identity element of their reduction operator, which is
  `true` for the `&&` operator.  Thus, our border trees are
  automatically visible, which matches the AoC definition as well.
  For this reason, no special handling for them is required!

*/

/*

  ### Computing Visibility in Parallel via Promotion

  Now all we have to do is call our `visible()` routine for all trees
  in the forest, passing in their coordinates and heights.  We could
  do this using:

  ```chapel
  forall rc in ForestSpace do
    visible(rc, Forest[rc]);
  ```

  However, this is another chance for us to apply promotion.  We've
  already seen that we can promote an integer argument, like `height`
  above, with an array in order to promote the function.  However, we
  can also use a domain to promote arguments, so long as the formal
  arguments are the same as the domain's index type—in this case, a
  2-tuple of `int`s.  As a result, our forall-loop above can be
  written as:

  ```chapel
  visible(ForestSpace, Forest);
  ```
  which is equivalent to the loop:

  ```chapel
  forall ((r, c), height) in zip(ForestSpace, Forest) do visible((r, c), height);
  ```

  (yet, in a far more succinct manner).

  {{< details summary = "**(Returning to the question of 'Why did Brad start declaring his formal types?'...)**" >}}

  This promotion turns out to be the reason that I declared the types
  of my arguments in `visible()`, uncharacteristically for me when
  compared with other procedures I've written in this series.  The
  reason is that if I were to declare the procedure without types, as:

  ```chapel
  proc visible((r, c), height) {
  ```

  the compiler would correctly see that the actual argument
  `ForestSpace`, a 2D domain, could only be passed to a 2-tuple formal
  argument `(r,c)` through promotion.  So it would correctly identify
  this as a promoted procedure call.  But then, because `height` is
  generic, it would send the whole `Forest` array in as `height` on
  every call.  Because of this, the resulting loop would effectively
  end up being:

  ```chapel
  forall (r, c) in ForestSpace do
    visible((r, c), Forest);
  ```

  This would result in the compiler treating `visible()` as if it had
  a definition like this:

  ```chapel
  proc visible((r, c): 2*int, height: [ForestSpace] int) {
    return && reduce (Forest[..<r, c] < height) ||
    // etc..
  }
  ```

  Of course, this was not at all what I intended, since I just wanted
  the right-hand side of the `<` to be a single integer, not an entire
  array.  So, `height` should be an `int`, not an array of `int`.  And
  this quickly became obvious to me because the compiler complained
  that it could not zipper the 1D array represented by `Forest[..<r,
  c]` with the 2D array `height` when promoting the operator `<`.
  Oops!

  Declaring the formal type of `height` to be `int` fixed this issue
  by making it a promoted argument as well.  And then I added the
  argument type to `(r, c)` for consistency, even though it was not
  strictly necessary.  I did continue to rely on the compiler to infer
  that the return type of `visible()` is `bool`, which also is
  relatively obvious since we're returning the result of an `||`
  expression.

  That makes this a case where typed arguments not only improve a
  program's readability and safety, but are also required to get the
  intended behavior.  I want to emphasize that by omitting types in my
  codes in this series, I don't mean to imply in any way that this is
  a best practice in Chapel.  Rather, I am trying to show off the
  language's power combined with how it often results in writing
  clear, concise code quickly, as feels appropriate for these toy AoC
  programs.  In larger or more important programs, using argument
  types is definitely a good practice for the purposes of clarity,
  safety, and documentation.

  {{< /details >}}

  Finally, since the AoC problem asks us to find the number of visible
  trees in the forest, we can use our old friends, the `+` reduction
  and `writeln()` routine to do so:

*/

writeln(+ reduce visible(ForestSpace, Forest));

/*

  And there you have it.  Hopefully you did not have any trouble seeing
  the forest for the trees!  [rim shot].

  Before wrapping up, here are some optional, and slightly technical,
  notes on parallelism and performance in the code above:

  {{< details summary = "**(Notes on parallelism and performance with this approach...)**" >}}

  ### A Note on Parallelism and Performance

  The first thing I want to point out about the code above is that we
  have created an abundance of parallelism in this program.
  Specifically, in that last line of code, I've parallelized all of
  the iterations over our forest.  So, as long as `numRows*numCols` is
  greater than the number of processor cores on our system, we've
  pretty likely saturated our processors with tasks to run.

  But then, within the `visible()` routine my use of the `[...]` loop
  form is also interpreted as a `forall` since it is over an array
  (slice).  Parallelism is good, but this might lead one to wonder
  whether there could be too much of a good thing?  And the answer is
  that there can be, but also "it depends."
 
  Chapel's built-in parallel iterators, like the ones on domains and
  arrays that are leading these forall loops, are designed to check
  how utilized the system is (or, really, how many tasks are running).
  In the event that it finds there are already more tasks than cores,
  it takes a branch that runs the loop serially, as if it was a
  for-loop.  This is good because it avoids the overhead of creating
  tasks that don't have their own core to run on, so would end up
  running serially anyway.  However, the checking and branching do add
  some amount of overhead.  Whether that overhead is meaningful or
  negligible depends heavily on the size of the loop and the
  computational intensity of its body—essentially, whether enough time
  is spent in it to overwhelm the compiler-generated "should it be run
  in parallel or serially?" checks.

  In this case, since we are effectively firing off up to
  `numRows*numCols*4` such parallel loops within the context of an
  already highly parallel loop, it is unlikely that we will have the
  cores to execute them in parallel.  For that reason, a programmer
  who wants to squeeze every last bit of performance out of this loop
  _might_ choose to write their reductions using serial `for` loops
  instead.  This would eliminate any overheads involved in checking
  for parallelism only to decide to run serially anyway.  The result
  of this rewrite would be:

  ```chapel
  return && reduce (for f in Forest[..<r, c] do f < height) ||
         && reduce (for f in Forest[r+1.., c] do f < height) ||
         && reduce (for f in Forest[r, ..<c] do f < height) ||
         && reduce (for f in Forest[r, c+1..] do f < height);
  ```

  For any large forest, this would still generate plenty of parallelism
  from the outer-loop promotion of `visible()`.  Is this rewrite worth
  it?  It depends a lot on how much you care about succinct code
  vs. not leaving performance on the floor, as well as how good the
  Chapel compiler is (or gets) at reducing overheads in the face of
  unnecessary nested parallelism.  In any event, it's good to
  understand these tradeoffs and some of the options available for
  rewriting code.

  ### A Note on Slicing and Performance

  One other way to optimize the performance of this program, at least
  given Chapel's status today, relates to the slice expressions.
  When slicing a 2D array, there are two similar-yet-different forms
  I'd like to compare:

  ```chapel
  ref Slice1 = [..<r, c];
  ```

  and

  ```chapel
  ref Slice2 = [..<r, c..c];
  ```

  The first of these is slightly more succinct and results in a
  virtual 1D _array view_ into the original 2D array, owing to the
  fact that one of the dimensions is a range (`..<r`) and the other is
  the singleton index, `c`.  This collapses that dimension out of the
  view, leaving a 1D array with the indices `[0..<r]`.  Meanwhile, the
  second is a 2D array view that happens to be degenerate in the
  second dimension.

  A difference between these is that if we were to create named
  references to these slices, as in the lines above, those references
  are essentially like virtual arrays themselves.  The first would act
  like a 1D array, so would be indexed `Slice1[i]`, equivalent to
  `Forest[i,c]`.  Meanwhile, the second is still a 2D array, so would
  be indexed `Slice2[i,j]`, where `j` would have to be `c` in order to
  stay in-bounds for the slice.  Note that these views can be passed
  to other routines or used in other computations as though they were
  normal 1D or 2D arrays, respectively.

  Due to vagaries of the Chapel implementation, as things stand today
  (Chapel version 1.28), the performance of rank-change slices, like
  `Slice1` above is notably worse than that of rank-preserving slices,
  like `Slice2`.  As a result, performance minded programmers will
  tend to want to use rank-preserving slices whenever possible, at
  least until we improve the performance of rank-change slices.

  This suggests that an even better-performing way to write this code
  would be:

  ```chapel
  return && reduce (for f in Forest[..<r, c..c] do f < height) ||
         && reduce (for f in Forest[r+1.., c..c] do f < height) ||
         && reduce (for f in Forest[r..r, ..<c] do f < height) ||
         && reduce (for f in Forest[r..r, c+1..] do f < height);
  ```

  Or, we could do away with creating either kind of slice altogether
  and just loop over the indices in question directly, as follows:

  ```chapel
  return && reduce for rc in {0..<r, c..c} do Forest[rc] < height) ||
         // etc.
  ```

  Or we could avoid creating the domains and loop over ranges, or...,
  or ...

  There are definite decisions to be made here between which code
  styles you find clearest, which are going to result in the best
  performance, and where your tastes and needs fall on that spectrum.
  I'll also mention that Chapel performance is improving all the time,
  particularly for higher-level idioms such as these array slices.  To
  that end, if you prefer writing at a higher level but encounter
  unacceptable performance overheads, or just find yourself wishing
  things were faster, that is always feedback we are happy to receive
  and slot into our priority list.  Just let us know.

  {{< /details >}}

  ### Summary

  That concludes today's article and a brief introduction to Chapel's
  domains and multidimensional arrays, as well as their relationship
  to forall loops, promotion, slicing, and reductions.  You can browse
  or download my code from the top of this article or
  [GitHub](https://github.com/chapel-lang/chapel/blob/e055a3f4e8469f1d351829038149d2ce891c986f/test/studies/adventOfCode/2022/day08/bradc/day08.chpl)
  if you want to try it yourself or make modifications to it.

  Part two of today's exercise is not too much harder (though I had a
  hard time with it due to not reading the instructions carefully).
  You should already have all the Chapel features you need to solve
  it.  Essentially, you can create another procedure like `visible()`
  that implements different logic to compute a tree's score and invoke
  it in the same promoted manner.  Just be sure to read the
  description of how the score is computed more carefully than I did!

  Thanks for reading this blog post and series, and please feel free
  to ask any questions or post any comments you have in the new [Blog
  Category](https://chapel.discourse.group/c/blog/) of Chapel's
  Discourse Page.

*/

