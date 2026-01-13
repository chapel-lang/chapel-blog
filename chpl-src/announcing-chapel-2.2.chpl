// Announcing Chapel 2.2!
// authors: ["Brad Chamberlain", "Engin Kayraklioglu"]
// summary: "A summary of highlights from the September 2024 release of Chapel 2.2"
// tags: ["I/O", "Parallel I/O", "Performance", "GPU Programming"]
// series: ["Release Announcements"]
// date: 2024-09-26
// weight: 90

/*

  The Chapel developer community is happy to announce the release of
  Chapel version 2.2!  In this blog, we'll summarize some of the key
  highlights, including [improvements to Chapel
  libraries](#library-improvements), [key optimizations for array
  computing](#array-optimizations), and [improved GPU
  support](#gpu-improvements).  Other notable improvements in Chapel
  2.2 not covered in this article include:

  * complete support for [remote variable
    declarations](https://chapel-lang.org/docs/2.2/language/spec/locales.html#remote-variable-declarations),
    introduced in [Chapel 2.1]({{< relref
    "announcing-chapel-2.1/#remote-variable-declarations" >}}),
  * [new Linux packages with multi-locale
    support](https://chapel-lang.org/install-pkg.html), including
    [AWS/EFA](https://chapel-lang.org/docs/platforms/aws.html#getting-chapel)-compatible options,
  * and support for LLVM 18.

  For a more complete list of changes in Chapel 2.2, please refer to
  its
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/2.2/CHANGES.md)
  file.  And thanks to [everyone who
  contributed](https://github.com/chapel-lang/chapel/blob/release/2.2/CONTRIBUTORS.md)
  to Chapel 2.2!

  ### Library Improvements

  Now that we are well past the [Chapel 2.0 release]({{< relref
  "announcing-chapel-2.0/index.md" >}}), our team has been putting
  more attention into adding and improving Chapel libraries.  Here are
  some of the notable library-based capabilities added in
  Chapel&nbsp;2.2:
  
  #### Sorting

  Chapel's `Sort` module was promoted to a standard module in this
  release, due to the many improvements that were made to its features
  and interfaces.  As examples, we have added a new stable-sort
  feature (in the sense of preserving the ordering of items with equal
  keys, not the stability of the routine itself), while also improving
  the mechanisms by which a user can specify comparators for a given
  type or call to `sort()`.  See the [`Sort` module's latest
  documentation](https://chapel-lang.org/docs/2.2/modules/standard/Sort.html)
  for details on these changes and others.

  #### Image Files

  The `Image` module that was introduced in Chapel's June release has
  now been extended to support JPEG and PNG image formats.  In
  addition, where it could only be used to write images in
  Chapel&nbsp;2.1, it can now read them as well.  Finally, new
  routines have been added to convert between color and pixel values.
  Learn more in the
  [`Image`](https://chapel-lang.org/docs/2.2/modules/packages/Image.html)
  module documentation.
    
  #### Custom Class Allocators

  This release includes a brand-new library-based capability in which
  users can create custom memory allocators, and then use them to
  allocate class objects.  Beyond the general capability, this new
  module also includes a couple of pre-defined allocators that support
  different memory allocation strategies.  To learn more about these
  capabilities, see the documentation for the
  [`Allocators`](https://chapel-lang.org/docs/2.2/modules/standard/Allocators.html)
  module.

  #### I/O

  Chapel 2.2 includes a number of I/O-related improvements, including:

  * The
    [`lines()`](https://chapel-lang.org/docs/2.2/modules/standard/IO.html#IO.fileReader.lines)
    iterator has been extended to support invocations within `forall`
    loops to read and process a file's lines using all of the
    processor cores of one or more compute nodes.  For example,
    running the following program on ten 32-core compute nodes would
    result in all 320 cores reading the file's lines in parallel: */

 use IO;

 const infile = openReader("file.txt");

 forall line in infile.lines(targetLocales=Locales, stripNewline=true) do
   writeln("Locale ", here.id, " read: ", line);

/*

 * Similar multi-locale support has been added to iterators within the
    `ParallelIO` module, such as
    [`readLines()`](https://chapel-lang.org/docs/2.2/modules/packages/ParallelIO.html#ParallelIO.readLines)
    and
    [`readDelimited()`](https://chapel-lang.org/docs/2.2/modules/packages/ParallelIO.html#ParallelIO.readDelimited).
    
  * A new
    [`PrecisionSerializer`](https://chapel-lang.org/docs/2.2/modules/packages/PrecisionSerializer.html)
    module has been added, supporting serialization of data with
    specific precision/padding values.  This can be particularly
    useful when writing out arrays.  For example, the following
    example writes its array values out with less precision and more
    padding than normal:

*/

 use PrecisionSerializer;

 const arr = [1.123456789, 2.123456789, 3.123456789, 4.123456789],
       fourPaddedDigits = new precisionSerializer(precision=3, padding=9);

 stdout.withSerializer(fourPaddedDigits).writeln(arr);
 // prints: '    1.123     2.123     3.123     4.123'

/*

 * The
   [`Zarr`](https://chapel-lang.org/docs/2.2/modules/packages/Zarr.html)
   module added in Chapel 2.0 has been extended to support a wide
   variety of compression algorithms, as well as to be more flexible
   with respect to which locales are involved in its operations.

 * Finally, two new utility
   routines—[`fromJson()`](https://chapel-lang.org/docs/2.2/modules/standard/JSON.html#JSON.fromJson)
   and
   [`toJson()`](https://chapel-lang.org/docs/2.2/modules/standard/JSON.html#JSON.toJson)—have
   been added to the
   [`JSON`](https://chapel-lang.org/docs/2.2/modules/standard/JSON.html)
   module to convert between Chapel values and JSON strings outside of
   a file I/O context.
   
    
  ### Array Optimizations

  Chapel 2.2 includes several new optimizations for key computational
  patterns involving arrays, described in the following sections.
  
  #### Optimized Array Slice Assignments

  The first optimization greatly improves the performance of
  assignments between array slices, as in the following example:

*/

config const n = 10;

const D = {1..n, 1..n};
var A, B: [D] real;
B = [(i,j) in D] (i-1) + (j-1)/10.0;

A[1..9, 1..9] = B[2..10, 2..10];  // copy between sub-arrays of A and B
A[10, ..] = B[3, ..];             // copy row 3 of B to row 10 of A

writeln(A);

/*

  Traditionally, for rank-preserving and rank-changing slices like
  these, Chapel has created a new pseudo-array, called an _array
  view_, that aliases the original array's data, permitting it to act
  like a normal array.  For an assignment like the above, once we've
  created the array views, we'd simply call the normal array
  assignment operator, passing them as arguments, and then destroy the
  views afterwards.

  The new optimization in Chapel 2.2, called _Array View Elision
  (AVE)_, avoids the creation of the array views by specializing the
  assignment to simply restrict it to the indices in question.  This
  eliminates the need to create and destroy the array views.  AVE
  helps address longstanding requests from Chapel users who had been
  replacing elegant slice assignments like the ones above with
  explicit loops to avoid the array view overheads.

  The result can have a profound impact on performance, particularly
  for small slices where the creation of the slice view can vastly
  outweigh the time required to perform the assignment of the array
  elements.  For example, on desktop systems, we saw a 30x improvement
  for 10-element array copies.  In a 2D shared-memory Poisson solver,
  the optimization improved the boundary update step, reducing the
  execution time of each timestep by ~18% for a 256x256 problem size.
  Meanwhile, a distributed-memory 2D heat equation solver saw an
  improvement of ~4x for various problem sizes between 4 million and
  270 million elements.


  #### Stencil Optimizations

  Another pair of optimizations in Chapel 2.2 helps with stencil
  computations—like the aforementioned Poisson and heat equation
  solvers—when applied to
  [stencil-distributed](https://chapel-lang.org/docs/2.2/modules/dists/StencilDist.html)
  arrays.

  In the first optimization, the compiler recognizes stencil access
  patterns, like `A[i+1,j]`, and optimizes for the common case where
  these accesses don't require communicating with other locales.  This
  optimization is enabled by the fact that stencil-distributed arrays
  store extra rows and columns of {{< sidenote "right" "_fluff_"
  >}}Also known as _ghost cells_, _halos_, or _overlap
  regions_ in the literature.{{< /sidenote >}} elements that cache
  neighboring locales' values.  This eliminates the overhead that's
  typically incurred when accessing a distributed array to determine
  whether the element is local or must be fetched from a remote
  locale's memory.  The resulting performance matches the use of
  explicit `A.localAccess(i+1,j)` calls, which permit programmers to
  assert that a given access is local to the current locale; yet using
  the more convenient `A[i+1,j]` syntax.

  The second optimization reduced overheads in the `.updateFluff()`
  method for such arrays, which refreshes the fluff values to match
  the array values they are caching.  The effect of these two
  optimizations can be seen when zooming in on one of our [nightly
  performance
  graphs](https://chapel-lang.org/perf/16-node-xc/?startdate=2024/06/16&enddate=2024/09/24&configs=gnuugniqthreads&graphs=2dheatsolvers5pointstencil)
  that tracks the performance of the distributed 2D heat equation
  solver mentioned above:

{{< figure src="StencilPerf.png" class="fullwide" caption="Impact of new optimizations on a 5-point stencil" >}}

  As can be seen, once the compiler began optimizing stencil accesses,
  the performance of the version using normal array accesses {{<
  sidenote "right" "began matching" >}}Note that the original
  optimization also introduced an unintentional performance regression
  for stencils on block-distributed arrays, which we fixed upon
  noticing it.{{< /sidenote >}} the one using explicit
  `.localAccess()` calls.  Then, when `.updateFluff()` was optimized,
  both versions improved further.


  #### Domain Localization Optimization

  A third array-based optimization in Chapel 2.2 applies when copying
  a local array from one locale to another.  For example:
*/

on Locales.last {
  var localA = A;  // make a local copy of A on this locale
  // compute with 'localA'
}

/*

  Traditionally, patterns like this have been unnecessarily expensive
  in Chapel, requiring communication back to `A`'s locale for each
  operation performed on `localA`.  The reason for this was that even
  though `localA` was local, the domain describing its indices, `D`,
  was stored back on the original locale and needed to be accessed for
  things like bounds queries.

  The optimization applied in Chapel 2.2 is a simple one: In cases
  like this where the domain is sufficiently constant, we now make a
  local copy of the domain as well, essentially transforming the
  original code into the following (which performance-minded
  programmers have used in the past to avoid these excess
  communications):

  ```chapel
  on Locales.last {
    const localD = D;
    var localA: [localD] A.eltType = A;
    // ...compute with 'localA'...
  }
  ```

  In the example shown above, `D` is declared to be `const`, trivially
  enabling this optimization to fire.  In practice, the optimization
  can eliminate an arbitrary amount of communication, since each
  operation on `localA` would result in communication back to the
  original locale.  This is also a good reminder of the importance of
  declaring domains to be `const` when their index sets won't be
  changing over the domain's lifetime.


  #### Array Reuse Optimization

  The final optimization applies when initializing one array using
  another where the two arrays have the same index sets, but distinct
  domains.  A common case where this comes up is when declaring and
  assigning between arrays using anonymous domains, as in the
  following example:

*/

proc genTriple(): [1..3] real {
  var trip: [1..3] real = [1.2, 3.4, 5.6];
  return trip;
}

var myTriple: [1..3] real = genTriple();
writeln(myTriple);

/*

  Prior to this optimization, the declaration of `myTriple` would
  result in a new array allocation and a copy of `genTriple()`'s
  returned `trip` array into it.  However, with the new optimization,
  `myTriple` can simply re-use, or _steal_, `trip`'s buffer, {{<
  sidenote "right" "reducing both memory utilization and execution time" >}}
  In fact, this optimization also eliminates a second array allocation
  and copy for this program—used to store the array being returned by
  `genTriple()` into a temporary variable.  With this optimization,
  `trip` can similarly be stolen by that temporary array, further
  reducing array memory allocations and copies.{{< /sidenote >}}.

  For a single, small array like this, the benefits may be minimal;
  but for the large arrays that are commonly used in Chapel, the
  impact can be significant.  For example, the green lines on the
  following graph from our [nightly
  trackers](https://chapel-lang.org/perf/chapcs/?startdate=2024/08/27&enddate=2024/09/24&graphs=arrayreturnperformanceserialparallel40000000elementarray)
  capture the improvement that took place for computations like the
  one above when using a 40-million-element array once this
  optimization was added on September 10th:
  
  {{< figure src="ArrayRetPerf.png" class="fullwide" caption="Impact of Chapel 2.2's new array re-use optimization" >}}

  In data-intensive cases, such as recursive procedures returning big
  arrays, this optimization can significantly reduce a program's
  overall memory footprint, allowing it to run to completion rather
  than running out of memory.
  
  ### GPU Improvements

  Chapel 2.2 introduces new GPU programming improvements as well,
  such as new GPU-oriented attributes.

  The `@assertOnGpu` attribute has been an important debugging tool for many users
  since the early days of Chapel's GPU support, to ensure that a
  parallel computation executes on a GPU as expected. As powerful as
  it is, it does have its limitations. Most importantly,
  `@assertOnGpu` requires that code is always executed on the GPU, meaning
  the same code can't be used on the CPU.
    This significantly hinders code reuse between CPUs and
  GPUs. To address this limitation, Chapel 2.2 introduces
  [`@gpu.assertEligible`](https://chapel-lang.org/docs/2.2/modules/standard/GPU.html#GPU.@gpu.assertEligible)
  to assert that a statement is suitable for GPU execution,
  without requiring it to be executed on a GPU.
  This is a much more light-handed approach;
  for example, the code below can be run on a CPU or a GPU:

*/

const target = if here.gpus.size > 0 then here.gpus[0] else here;

on target {
  var Arr: [1..1_000_000] int;

  @gpu.assertEligible
  foreach elem in Arr do
    elem += 1;

  writeln(+ reduce Arr);
}

/*

  Another attribute we introduced with Chapel 2.2 is
  [`@gpu.itersPerThread`](https://chapel-lang.org/docs/2.2/modules/standard/GPU.html#GPU.@gpu.itersPerThread). By
  default, Chapel uses a GPU thread per iteration for a
  GPU-eligible loop. However, in some applications this leads to
  suboptimal performance, where mapping multiple iterations to a
  single GPU thread can be preferable. Here's a quick example of how this
  attribute can be used in such scenarios:

  ```chapel
  on here.gpus[0] {
    foreach i in 1..1000 {
      // will run using 1000 GPU threads
    }

    @gpu.itersPerThread(10)
    foreach i in 1..1000 {
      // will run using 100 GPU threads
    }
  }
  ```

  The `@gpu.itersPerThread` attribute currently divides the iteration space into
  blocks. In future releases, we plan to add more knobs to
  control thread-to-iteration mapping.

  Chapel 2.2 also features many improvements for high-end HPC
  systems with GPUs. Chapel's
  [_co-locales_](https://chapel-lang.org/docs/2.2/usingchapel/multilocale.html#co-locales),
  [first introduced in Chapel
  1.32]({{< relref "announcing-chapel-1.32/#support-for-co-locales" >}}),
  can now be used with GPUs. This enables
  significantly better affinity in systems with multiple GPUs
  per node, such as Frontier or Perlmutter. Chapel 2.2 is also the
  first release to support ROCm 6, which is key for
  enabling Chapel programs to target AMD's MI300A APUs that will power El
  Capitan. Last but not least, we have resolved a user-reported
  performance bug where GPU kernels running on multiple GPUs per
  node were unnecessarily synchronized, creating arbitrary slowdowns.

  For more information about Chapel on GPUs, please refer to our
  ongoing [GPU Programming in
  Chapel](https://chapel-lang.org/blog/series/gpu-programming-in-chapel/) blog
  series or the [GPU
  Programming](https://chapel-lang.org/docs/2.2/technotes/gpu.html) tech
  note.


  ### For More Information

  If you have questions about Chapel 2.2 or its new features, please
  reach out on Chapel's [Discourse
  community](https://chapel.discourse.group/) or one of our other
  [community forums](https://chapel-lang.org/community.html).  As
  always, we're interested in feedback on how we can make the Chapel
  language, libraries, implementation, and tools more useful to you.
  
*/
