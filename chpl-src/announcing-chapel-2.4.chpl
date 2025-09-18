// Announcing Chapel 2.4!
// authors: ["Brad Chamberlain", "Jade Abraham", "Daniel Fedorin"]
// summary: "Highlights from the March 2025 release of Chapel 2.4"
// tags: ["Release Announcements", "Python", "Dyno"]
// date: 2025-03-20
// weight: 90
// chplVersion: 2.4

/*

  The Chapel community is happy to announce the release of Chapel 2.4!
  In this article, we'll summarize some of its main highlights,
  including:

  * Brand-new syntax for defining [multidimensional array
    values](#multidimensional-array-literals)

  * Significant improvements in [Chapel-Python
    interoperability](#python-interoperability)

  * Support for building Chapel programs [with
    CMake](#chapel-support-for-cmake)

  * Significant advances in [Dyno's ability to resolve Chapel
    features](#dyno-support-for-chapel-features)

  Other highlights of Chapel 2.4 that are not covered in this article
  include:

  * Parallel iterator and zippering support over the
    [`set`](https://chapel-lang.org/docs/2.4/modules/standard/Set.html)
    and
    [`map`](https://chapel-lang.org/docs/2.4/modules/standard/Map.html)
    types

  * The ability to query the [number of
    co-locales](https://chapel-lang.org/docs/2.4/language/spec/locales.html#ChapelLocale.locale.numColocales)
    running on a node

  * New custom settings, location-based rules, and documentation for the
    [`chplcheck`](https://chapel-lang.org/docs/2.4/tools/chplcheck/chplcheck.html)
    linter

  For a much more complete list of changes in Chapel 2.4, see the
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/2.4/CHANGES.md)
  file.  And huge thanks to [all the Chapel community
  members](https://github.com/chapel-lang/chapel/blob/release/2.4/CONTRIBUTORS.md)
  who contributed to version 2.4!

  ### Multidimensional Array Literals

  Since Chapel's inception, the language has supported both
  multidimensional rectangular arrays and _arrays of arrays_—arrays
  whose elements also happen to be arrays.  For example, the following
  declarations each create $n^2$ array elements, where the first is a
  2D array of real floating point values (`real`), while the second is
  a 1D array whose elements are each a 1D array of `real` values:

*/

  config const n = 10;

  var Arr2D:    [1..n, 1..n] real,   // a 2D array of reals
      ArrOfArr: [1..n] [1..n] real;  // a 1D array of 1D arrays of reals

/*

  There are a few differences between these two types in Chapel, as
  well as potential motivations for using either over the other.

  {{< details summary="**(Expand this section for background on some of the key differences...)**" >}}

  Focusing on the simple declarations above, some important
  distinctions between the two array types are:

  * `Arr2D` will allocate all of its elements using a single block of
    consecutive memory.  In contrast, `ArrOfArr` allocates each of its
    inner array's `n` elements in a block of consecutive memory, but
    with no guarantee as to where each inner array will be placed in
    memory relative to the others.

  * The elements of `Arr2D` can be accessed using either a pair of
    integer indices or a 2-tuple of integers. However, `ArrOfArr` must
    be indexed using an integer index to select one of its inner
    arrays, after which a second integer index can be used to access
    one of its `real` values.  This can be seen in the following
    lines, which write and read elements of each array:

*/

 // Initialize the arrays using element-wise assignments
 forall i in 1..n {
   forall j in 1..n {
     const val = i + j / 10.0;

     Arr2D[i,j] = val;
     ArrOfArr[i][j] = val;
   }
 }

 // read a 2-tuple index from the console
 use IO;
 const idx = read(2*int);

 // use it to index the 2D array directly
 writeln(Arr2D[idx]);

 // index the array-of-arrays by indexing into the tuple...
 writeln(ArrOfArr[idx(0)][idx(1)]);

 // ...or by de-tupling it into distinct integers:
 const (i,j) = idx;
 writeln(ArrOfArr[i][j]);

/*

    Note that multidimensional arrays and tuple-based indexing can be
    particularly valuable when writing rank-independent code, since
    they don't require a number of commas or brackets proportional to
    the array's rank.
  
  * `Arr2D` can also be _sliced_ across both of its dimensions to
    create a pseudo-array that refers to the elements in question.  In
    contrast, `ArrOfArr` doesn't support directly referring to an
    arbitrary subset of its elements—just to some or all of the
    elements in one of its inner arrays:

*/

 inspectArr(Arr2D[i, ..]);             // pass the i-th row
 inspectArr(Arr2D[.., j]);             // pass the j-th column
 inspectArr(Arr2D[n/2..#2, n/2..#2]);  // pass the central 2x2 sub-array

 inspectArr(ArrOfArr[i]);              // pass the i-th inner array
 inspectArr(ArrOfArr[i][n/2..#2]);     // pass the i-th array's center

 // print an array's values and indices
 proc inspectArr(X: [?I]) {
   writeln("Got array:");
   writeln(X);
   writeln("Declared over indices ", I, "\n");
 }

/*

  {{< /details >}}
  
  Despite Chapel's longstanding support for multidimensional array
  types and computations, up until this week's release, the language
  has only supported a syntax for specifying 1D array values, or
  _literals_.  Thus, a user could write:

*/

 var Arr1D = [1, 2, 3];  // declare a 1D, type-inferred array

/*
  or:
*/

 var ArrOfArrs = [[1, 2], [3, 4], [5, 6]];  // declare an array of arrays

/*

  where these two declarations rely on Chapel's type inference to
  infer that the variables are arrays, based on the initializing array
  literal.

  However, there has not been an equivalent way to declare a
  type-inferred multidimensional array, nor to create such a value to
  pass as an argument or compute with directly.  This deficiency in
  the language has long been noted by users, who have requested a
  solution.

  Happily, Chapel 2.4 adds this requested feature.  Even better, the
  approach taken reflects the result of intensive user discussions,
  including live community feedback sessions to reach consensus.  The
  resulting approach is to use semicolons as a kind of "heavyweight
  comma" to indicate the end of a dimension.  Thus, a 2D 3$\times$3
  array can be written:

*/

 var Arr3by3 = [11, 12, 13;
                21, 22, 23;
                31, 32, 33];

/*

  Similarly, a 3D, 2$\times$2$\times$2
  array can be written:

*/

 var Arr3D = [11.1, 12.1;
              21.1, 22.1;
              ;
              11.2, 12.2;
              21.2, 22.2];

/*

  Note that the whitespace and linefeeds used in these examples are
  optional, but used here to improve readability.

  We're very pleased by the addition of this feature, and thoroughly
  appreciate all the input we've received from the Chapel community on
  this topic over the years, and particularly as we completed the
  feature over the past few months.


  ### Python Interoperability

  Chapel 2.4 contains significant improvements to the Python
  interoperability support that we introduced in version 2.3.  Let's
  look at some of the improvements in terms of ergonomics and data
  types:
  
  #### Ergonomic Improvements

  As a motivating example, consider the following snippet of Python
  code:

  {{< file_download fname="compute_sum_lib.py" lang="python" >}}

  Previously, calling `compute_sum()` on a Chapel array required a lot
  of explicit handling of types; it also resulted in `lst` being
  copied twice, unnecessarily.  Calling such a function also required
  using multiple files, as the Python code needed to be in its own
  module for Chapel to import.  Here's an example of how this looked
  in Chapel 2.3:

*/

 use Python;
 const interp = new Interpreter();

 // the old way of invoking 'compute_sum()'
 {
   const lib = new Module(interp, 'compute_sum_lib'),
         compute_sum = new Function(lib, 'compute_sum');

   var myArr = [i in 1..10] i,
       res = compute_sum(int, myArr);

   writeln("The sum of the numbers from 1 to 10 is ", res);
 }

/*

  In this week's release, this computation can now be expressed much
  more succinctly and with less overhead.  Rather than importing a
  piece of Python code from a standalone module, we can now
  {{< sidenote "right" "directly load a string to create a new Python module:" >}}
  Chapel 2.4 can also directly pull in Python bytecode as
  a module or a [pickle
  object](https://docs.python.org/3/library/pickle.html) as a
  value. {{</ sidenote >}}

*/

 const lib = interp.importModule("compute_sum_lib",
   """
   import numpy as np
   def compute_sum(lst):
       arr = np.asarray(lst)
       return np.sum(arr)
   """.dedent());

/*


This gives us a `lib` object like before, but without the need for a
separate file.  And now, when we acquire a handle to `compute_sum()`,
it reads better:

*/

 const compute_sum = lib.get('compute_sum');

/*

  The next lines are the most important part, as we can now call
  `compute_sum()` using a direct reference to the Chapel array (rather
  than the default copying behavior) and get the result back:

*/

 var myArr = [i in 1..10] i,
     res = compute_sum(int, new Array(interp, myArr));  // no copies are done!

 writeln("The sum of the numbers from 1 to 10 is ", res);

/*

  We can actually make one more productivity improvement here. Since all
  we do with `res` is print it out, we don't really need to specify
  the return type of `compute_sum()` at all:

*/

 var res2 = compute_sum(new Array(interp, myArr));

 writeln("The sum of the numbers from 1 to 10 is ", res2);

/*

  In this version, `res2` is a generic Python value that Chapel's
  `Python` module knows how to print, so we can just pass it to
  `writeln()` directly. While this is a small change, across larger
  programs such brevity can add up.

  All of the improvements above come together to form a much more
  ergonomic and powerful interface to the Python ecosystem.


  #### Data Type Improvements

  Chapel 2.4 also expands the Chapel types that the `Python` module
  understands, specifically adding the new Chapel types `PyList`,
  `PySet`, `PyDict`, and {{< sidenote "right" "`PyArray`" >}} Python
  provides a low-level `array` type that the Chapel
  `PyArray` type represents. This type can also refer to other
  array-like things in Python, such as NumPy arrays. {{</ sidenote >}}.
  Values of these types are handles to Python objects that provide
  specialization over an abstract `Value` type.

  For example, the following code creates a Python set, and then adds
  new elements to it.  The `make_set()` function it uses is a simple
  Python function that takes an arbitrary number of arguments,
  returning a set containing those arguments.

*/

 var make_set = interp.importModule("make_set",
   """
   def make_set(*args):
       return set(args)
   """.dedent()).get('make_set');

/*

  Using `make_set()`, we can create a set containing arbitrary elements:

*/

 var s = make_set(owned PySet, 1, 2, 3);

/*

  We _could_ use a generic return type and have an opaque handle to the
  set, but since we know it's a set, we use the `PySet` type to
  get a more specialized handle. This lets us invoke set-specific
  operations using normal Chapel method calls:

*/

 s.add(4);
 s.add("hello");
 s.add("world");
 writeln(s);

/*

  For those familiar with Chapel's sets, the above may look a little
  suspect.  A Chapel `set` can only store a single element type, but
  here, we are adding strings to a set that was originally created to
  store integers. By using the Python set, we are taking advantage of
  Python's loose typing and can store any type we'd like (provided the
  `Python` module knows how to convert the data to Python). This
  doesn't result in the same performance and parallelism as native Chapel
  sets support, but it provides a new level of flexibility to Chapel
  programmers using Python code.

  The combination of exposing these new Python types and the
  aforementioned ergonomic improvements make the `Python` module far
  more powerful and easy to use than it was in the previous Chapel 2.3
  release.  We're very interested in hearing feedback from users on
  their experiences with the module.


  ### Chapel Support for CMake

  Chapel 2.4 also contains new support for building Chapel
  applications with CMake. Previously, users could only use CMake to
  build Chapel by defining custom commands. We now provide CMake
  module files to build applications in a more idiomatic
  way.

  Currently, this is enabled by adding the necessary files to your
  project.  As an example, the following `CMakeLists.txt` file builds
  a simple Chapel application from two module files, `A.chpl` and
  `B.chpl`:

  ```cmake
  find_package(chpl REQUIRED HINTS .)
  project(myProgram LANGUAGES CHPL)
  add_executable(myProgram A.chpl B.chpl)
  ```

  This results in a project that can be built and executed using the
  normal CMake workflow:

  ```terminal
  $ mkdir build && cd build
  $ cmake ..
  $ make
  $ ./myProgram
  ```

  See [the documentation for this new
  support](https://chapel-lang.org/docs/2.4/usingchapel/compiling.html#cmake)
  for more information.

  ### Dyno Support for Chapel Features

  As you may have seen in [previous]({{< relref
  "announcing-chapel-2.3#dyno-compiler-improvements" >}})
  [release]({{< relref
  "announcing-chapel-1.31#scope-resolution-and-errors-by-dyno" >}})
  [announcements]({{< relref
  "announcing-chapel-1.29#better-error-messages-via-dyno" >}}), _Dyno_
  is the name of a project whose aim is to modernize and improve the
  Chapel compiler. Dyno improves error messages, allows incremental
  type resolution, and enables the [development of language
  tooling]({{< relref "chapel-py" >}}).  Among the major wins for this
  ongoing effort is the [Chapel Language Server
  (CLS)](https://chapel-lang.org/docs/2.4/tools/chpl-language-server/chpl-language-server.html),
  which was previously featured on this blog in [the post about editor
  integration]({{< relref "chapel-lsp" >}}).  The team has been hard
  at work implementing many features of Chapel's type system in Dyno,
  which---among other things---will enable tools like CLS to
  provide more accurate and helpful information to users.

  This release has seen a significant number of language features come
  online within Dyno. One major area of focus has been Dyno's support
  for arrays and domains.  These types are incredibly powerful and
  implemented using Chapel.  As a result, they draw on a lot of the
  language's features. The following picture shows an editor in which
  CLS is displaying the type information computed by Dyno (in grey)
  for the Chapel program that follows, which relies heavily on
  inferred types.

  {{< figure src="release-2.4-arrays.png" class="fullwide" >}}
  {{< file_download_min fname="release-2.4-arrays.chpl" lang="chapel" open=true >}}

  In addition to arrays and domains, Dyno is now capable of verifying
  [interface
  constraints](https://chapel-lang.org/docs/2.4/technotes/interfaces.html).
  The [`manage`
  statement](https://chapel-lang.org/docs/2.4/technotes/manage.html),
  similar to Python's `with`, and built on top of interfaces, is also
  now supported.  The following program demonstrates resolving a
  `manage` statement, as well as the error issued when the
  `contextManager` interface constraint is not met.

  {{< figure src="release-2.4-interfaces.png" class="fullwide" >}}
  {{< file_download_min fname="release-2.4-interfaces.chpl" lang="chapel" >}}

  Another group of features that is fun to demonstrate are those that
  have to do with the compiler itself. In 2.4, Dyno is able to handle
  [`compilerError()`](https://chapel-lang.org/docs/2.4/modules/standard/Errors.html#Errors.compilerError)
  and
  [`compilerWarning()`](https://chapel-lang.org/docs/2.4/modules/standard/Errors.html#Errors.compilerWarning),
  as well as routines for retrieving the current line number and
  filename. The following program demonstrates the use of these:

  {{< figure src="release-2.4-compiler.png" class="fullwide" >}}
  {{< file_download_min fname="release-2.4-compiler.chpl" lang="chapel" >}}

  All of the code presented in this section began resolving in Dyno
  for the first time in Chapel 2.4, and this doesn't even remotely
  cover {{< sidenote "right" "all the improvements that have been made" >}}
  Over 27 PRs have been merged into the Dyno library since
  the December release.  {{< /sidenote >}} since version 2.3. With
  each release, Dyno draws nearer to feature parity with the
  production compiler.

  Since Dyno is still a work-in-progress, the editor features showcased
  above are turned off by default in CLS. You can try them by
  [enabling experimental features](https://chapel-lang.org/docs/2.4/tools/chpl-language-server/chpl-language-server.html#experimental-resolver-features).


  ### For More Information


  If you have questions about Chapel 2.4 or its new features, please
  reach out on Chapel's [Discord
  channel](https://discord.gg/xu2xg45yqH), [Discourse
  group](https://chapel.discourse.group/), or one of our other
  [community forums](https://chapel-lang.org/community/).  As always,
  we're interested in feedback on how we can make the Chapel language,
  libraries, implementation, and tools more useful to you.

*/
