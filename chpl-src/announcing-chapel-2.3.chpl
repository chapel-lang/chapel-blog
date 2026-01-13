// Announcing Chapel 2.3!
// authors: ["Brad Chamberlain", "Jade Abraham", "Michael Ferguson", "John Hartman"]
// summary: "Highlights from the December 2024 release of Chapel 2.3"
// tags: ["Python", "Sparse Arrays", "Performance", "GPU Programming", "Dyno"]
// series: ["Release Announcements"]
// date: 2024-12-12
// weight: 90

/*

  The Chapel developer community is pleased to announce the release of
  Chapel version 2.3!  In this article, we'll summarize some of the
  major highlights, including:

  * Brand-new support for [calling to Python from
    Chapel](#python-interoperability)

  * Improvements for [computing with sparse
    arrays](#sparse-computations),

  * [Performance improvements](#performance-improvements) in the
    tasking and communication aspects of the runtime

  * New features for [GPU programming](#new-gpu-features) with Chapel

  * Advances in the [_dyno_ resolver](#dyno-compiler-improvements) for
    calls and types

  Before we get started, though, a few noteworthy improvements in
  Chapel 2.3 _not_ covered in this article include:

  * New [atomic
    min/max](https://chapel-lang.org/docs/2.3/language/spec/task-parallelism-and-synchronization.html#Atomics.fetchMin)
    operations, including support for network-based implementations

  * An
    [`allocations()`](https://chapel-lang.org/docs/2.3/modules/standard/MemDiagnostics.html#MemDiagnostics.allocations)
    iterator that enumerates the memory allocations made by a locale

  * New [Linux packages](https://chapel-lang.org/install-pkg.html) for
    AmazonLinux 2023 and Fedora 41

  * Support for ROCm in [Chapel's Spack
    formula](https://packages.spack.io/package.html?name=chapel)

  * Support for LLVM 19 as the preferred back-end compiler, resulting
    in better performance

  For a more complete list of changes in Chapel 2.3, please refer to
  its
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/2.3/CHANGES.md)
  file.  And thanks to [everyone who
  contributed](https://github.com/chapel-lang/chapel/blob/release/2.3/CONTRIBUTORS.md)
  to Chapel 2.3!

  ### Python Interoperability

  One of the coolest features of Chapel 2.3 is a [new `Python` package
  module](https://chapel-lang.org/docs/main/modules/packages/Python.html)
  that supports calling from Chapel to Python.  This allows Chapel
  code to use many popular Python libraries like NumPy and PyTorch
  directly. This is a great way to leverage the power of Chapel's
  parallelism and Python's rich ecosystem of libraries.

  As a simple example, this program creates a 2 x 2 PyTorch tensor
  from Chapel and prints it out: */

use Python;

var interp = new Interpreter(),
    torch = new Module(interp, "torch"),
    tensor = new Function(torch, "tensor");

var T = tensor(owned Value, [[1.0,2.0], [3.0,4.0]]);
writeln(T.str());

/*

  The `[[1.0,2.0], [3.0,4.0]]` argument is a native nested Chapel
  array that is copied into the PyTorch tensor. To print out the
  tensor, we again call into Python to get its string representation.
  This is a simple example, but it shows how easy it is to call into
  Python from Chapel.

  The other cool feature this enables is the ability to embed Python
  code in Chapel programs that can then be changed at execution
  time. This is a powerful way to create dynamic programs that can be
  modified on the fly. For example, suppose you want to apply a change
  to each element of an array, but don't want to have to recompile the
  program each time you change the operation. You could write a Python
  function that performs the operation and then call that function
  from Chapel. Here's an example: */

config const func = "lambda x,: x";

var myFunc = new Function(interp, func);

var A: [1..10] int = 1..10;

writeln("Before: ", A);

for a in A do
  a = myFunc(int, a);

writeln("After: ", A);

/*

  After compiling this program (see the
  [docs](https://chapel-lang.org/docs/main/modules/packages/Python.html#compiling-chapel-code)
  for details on how to do this), you can change the `func` variable
  to any Python lambda function you like on the command-line and
  re-run the program.

  ```bash
  # increment each element
  ./myApply --func="lambda x,: x + 1"
  # square each element
  ./myApply --func="lambda x,: x * x"
  # zero out even elements
  ./myApply --func="lambda x,: 0 if x % 2 == 0 else x"
  ```

  While this support is still a work in progress, it's a great start
  that opens up a lot of possibilities for Chapel programmers.
  
  ### Sparse Computations

  Chapel 2.3 continues a recent focus to improve support for sparse
  computations using Chapel's domains and arrays.  This section
  summarizes some of these recent advances.  But first, we'll start
  with some background for those unfamiliar with Chapel's sparse
  features.

  #### Background on Sparsity in Chapel
  
  Chapel supports sparse arrays that act like dense rectangular
  arrays.  However, their sparse nature means that they only
  explicitly store data at a subset of their bounding boxes' indices
  (e.g., the _non-zeroes_ in a sparse matrix computation).

  Chapel's approach to sparsity is fairly unique in that it uses
  _domains_ to represent the non-zero indices of a sparse array, and
  these domains may be shared by multiple arrays.  This supports
  amortizing the storage of indices, permitting each sparse array to
  simply store its non-zero values.  By default, Chapel stores sparse
  domains using a Coordinate (COO) storage format, though there are
  also options to store 2D sparse domains using Compressed Sparse Row
  or Column formats (CSR/CSC).  In addition, Chapel supports
  distributed sparse arrays by block-distributing the domain's
  bounding box, and then storing every locale's subdomain using COO,
  CSR, or CSC formats (as specified by the user).

  
  Chapel's sparse features were not part of the stabilization effort
  that culminated in [Chapel 2.0]({{< relref "announcing-chapel-2.0"
  >}}), due to our intention to make significant usability and
  implementation improvements rather than just adjustments to existing
  interfaces.  Now that we're past that milestone release, we've
  turned our attention to improving and stabilizing these features.


  #### Recent Sparse Improvements
  
  Chapel 2.1 and 2.2 contained sparse feature improvements in the form
  of new convenience methods for iterating over rows/columns of sparse
  arrays, and for querying or overwriting a single locale's chunk of a
  block-distributed sparse array or domain.  In addition, we made
  general orthogonality improvements that caused sparse domain/array
  features to be more equivalent to their dense counterparts.  Though
  these improvements were not highlighted in this blog's release
  announcements, they were summarized in the [language/library
  improvements](https://chapel-lang.org/releaseNotes/2.1-2.2/01-lang-lib.pdf)
  deck of our release notes for Chapel 2.1 and 2.2 (see slides 13–21).

  Chapel 2.3 continues this trend by adding new interfaces in response
  to user feedback.  It also improves sparse naming schemes and layout
  types to match their dense counterparts, while improving the
  performance of key idioms.

  Specifically, the types used to represent CSR and CSC formats were
  renamed from the previous class type, `CS(compressRows=true|false)`,
  to a pair of record types, `csrLayout` and `cscLayout`.  In
  addition, the module defining the types was renamed from `LayoutCS`
  to `CompressedSparseLayout`.  All of these changes were done to
  improve the clarity of the identifiers, and to unify the approach
  with distributions like `blockDist`, as well as the modules that
  define them, like `BlockDist`.

  The following example illustrates Chapel's sparse features in action
  using the new identifiers.  Specifically, it declares a sparse
  domain and array representing the main diagonal of an $n \times n$
  matrix using CSR storage:

*/

 use CompressedSparseLayout;

 config const n = 9;

 // declare a dense domain of size n x n, as well as a sparse subdomain
 // storing just the main diagonal in CSR format
 const D = {1..n, 1..n},
       Diag: sparse subdomain(D) dmapped new csrLayout() = [i in 1..n] (i,i);

 // declare an array over that domain, storing a real value per non-zero
 var Mat: [Diag] real;

 // initialize each non-zero element with a unique value
 forall (i,j) in Diag do
   Mat[i,j] = i + j/10.0;

 // print the sparse array as though it was dense
 for (i,j) in D do
   write(Mat[i,j], if j == n then "\n" else " ");

/*

  The last loop in this example demonstrates how sparse arrays in
  Chapel can be accessed as though they were dense—in this case, by
  iterating over a dense index set and using those indices to print
  the array out.
  
  Chapel 2.3 also contains a new optimization for inter-locale copies
  of CSR/CSC arrays.  Previously, such copies required
  _O(#non-zeroes)_ communications.  Now they only result in a few
  transfers regardless of size when compiled with `--fast`.  Here's an
  example of such a cross-locale copy, along with a demonstration of
  some of the recently-added iterators:

*/

 // move this task to another locale
 on Locales.last {
   // make a local copy of the sparse array
   var LocMat = Mat;

   // double its values
   LocMat *= 2;

   // iterate over the non-zeroes, printing them out
   for r in LocMat.rows() do
     for (c, m) in LocMat.colsAndVals(r) do
       writeln("Mat", (r,c), " = ", m);
 }

/*
  Chapel 2.3 adds additional utility routines, including:

  * a `.getCoordinates()` method for COO-stored domains that returns
    an array of tuples representing the non-zeroes' coordinates

  * a `.localSubarrays()` iterator method for block-sparse arrays that
    yields each locale's sub-array, either serially or in parallel.

  * a `getLocalSubarray()` method for block-sparse arrays that returns
    the current locale's sub-array.  This is a convenience method
    supporting a common case, where previous releases added the
    ability to query a specific locale's sub-array.

  To see an example of Chapel's sparse features in action, browse
  [`MatMatMult.chpl`](https://github.com/chapel-lang/chapel/blob/release/2.3/test/studies/spsMatMatMult/MatMatMult.chpl)
  and the other files in [its
  directory](https://github.com/chapel-lang/chapel/tree/release/2.3/test/studies/spsMatMatMult),
  which implement local and distributed sparse matrix-matrix
  multiplication routines in Chapel—an algorithm that has served as a
  testbed and motivator for many of these recent improvements.


  ### Performance Improvements

  Beyond the sparse copy optimization mentioned above, Chapel 2.3
  includes several additional performance improvements.  In this
  section, we describe two classes of optimizations, both of which
  involve the Chapel runtime. As such, they have the potential to
  benefit any program without requiring source changes by the user.
  The first involves performance improvements for Chapel's tasking due
  to a Qthreads update.  The second reduces overheads for many idioms
  when using Libfabric/OFI as the communication layer.

  All graphs shown in this section are taken from our [nightly
  performance graphs](https://chapel-lang.org/perf-nightly.html),
  which track Chapel performance over time, similar to stock tickers.
  
  #### Qthreads Tasking Improvements

  Parallel tasks in Chapel are typically implemented using the
  [Qthreads lightweight threading
  library](https://github.com/sandialabs/qthreads#readme) developed by
  Sandia National Laboratories.  Chapel 2.3 includes an upgrade to
  version 1.21 of Qthreads, which accelerated several tasking idioms.
  One example of these improvements can be seen in the following
  thread-ring micro-benchmark, which originated from the [Computer
  Language Benchmarks Game
  (CLBG)](https://benchmarksgame-team.pages.debian.net/benchmarksgame/index.html):

  {{< figure src="thread-ring.jpg" class="fullwide" caption="Impact of Qthreads 1.21 on the CLBG thread-ring benchmark" >}}

  The Qthreads upgrade also had a noticeable and positive impact on
  more significant computations, such as studies of proxy applications
  like SSCA#2, LULESH, MiniMD, and the following CoMD run, gathered on
  16 nodes of HPE Apollo:

  {{< figure src="CoMD.jpg" class="fullwide" caption="Impact of Qthreads 1.21 on a port of the CoMD proxy application from LLNL" >}}

  We greatly appreciate the ongoing support we receive from the
  Qthreads team, and particularly want to thank Ian Henriksen, who has
  debugged and fixed a few performance regressions caused by recent
  upgrades, such as the initial uptick that can be seen in the
  'coforall-begin' version of the thread-ring benchmark just above.
  
  #### Optimizations for Libfabric/OFI

  Chapel 2.3 also includes several performance improvements for
  `CHPL_COMM=ofi`, which is the Libfabric-based communication layer
  Chapel uses when compiling for HPE Cray Supercomputing EX systems
  and the HPE Slingshot interconnect. All of the improvements
  described in this section relate to the use of non-blocking PUTs and
  GETs to improve `ofi` performance.

  The first optimization noticeably improves remote cache performance
  by pipelining PUTs, as seen {{< sidenote "right" "in the following graph" >}}
  Note that the graphs in this section are performance
  graphs, so higher is better, unlike the execution time graphs of the
  previous section.{{< /sidenote >}}, which measures the HPCC Random
  Access&nbsp;(RA) benchmark on 16&nbsp;nodes of HPE Cray SC EX using
  a GET-update-PUT approach:

  {{< figure src="RA-rmo.jpg" class="fullwide" caption="Impact of non-blocking PUTs on HPCC RA using GETs/PUTs" >}}
  
  We also used non-blocking PUTs to improve the performance of `on`
  statements, because the target locale must do a PUT of a "done"
  indicator back to the initiating locale when the `on`-statement
  completes. As of Chapel 2.3, this PUT no longer blocks the task on
  the target locale, allowing it to service other requests more
  quickly. The resulting performance improvement can be seen in this
  next version of HPCC RA, which uses an `on`-statement to fire off a
  remote task to perform the update on the locale where the target
  element lives:

  {{< figure src="RA-on.jpg" class="fullwide" caption="Impact of non-blocking PUT notifications on HPCC RA using remote tasks" >}}

  Finally, Chapel 2.3 improves the performance of large array
  transfers using non-blocking GETs for `ofi`.  Large transfers that
  exceed the maximum message size of the underlying network fabric
  must be fragmented into smaller GETs. The use of non-blocking GETS
  in such cases allows these smaller GETs to be performed in parallel,
  increasing throughput. The effect can be seen in the improvement to
  the '1/4 mem array' line on this graph:

  {{< figure src="Large-Array-Gets.jpg" class="fullwide" caption="Impact of non-blocking GETs on large array transfers" >}}
  
  While the timings in this section were run on an HPE Cray EX, we
  expect similar performance improvements on other platforms that use
  `CHPL_COMM=ofi`, such as AWS using EFA.
  

  ### New GPU Features

  Readers of this blog will know that a recent focus area for Chapel
  has been to support [vendor-neutral GPU computing]({{< relref
  "gpu-programming-in-chapel" >}}).  GPU improvements continued at
  steady pace in Chapel 2.3, as described in this section.

  This release adds two new features for querying information about
  GPUs. The
  [`.gpuId`](https://chapel-lang.org/docs/2.3/language/spec/locales.html#ChapelLocale.locale.gpuId)
  method on GPU sublocales provides a functionality similar to `.id`
  on locales by returning the ID of a given GPU sublocale within its
  host locale. This enables symmetric idioms between inter-node and
  inter-GPU parallelism:

  ```chapel
  const numGpusPerNode = here.gpus.size;
  coforall loc in Locales do on loc {
    coforall gpu in here.gpus do on gpu {
      const globId = loc.id * numGpusPerNode + gpu.gpuId;
      writeln(globId);
    }
  }
  ```

  Prior to the 2.3 release, we had to write the inner coforall-loop to
  zipper between `here.gpus` and `here.gpus.domain` to obtain IDs,
  which was redundant and different than the outer coforall. Note that
  `gpuId` returns the GPU’s position in the parent locale’s `gpus`
  array, which may differ from the device ID reported by vendor APIs
  when co-locales are used. Chapel 2.3 also has a new
  [`deviceAttributes()`](https://chapel-lang.org/docs/2.3/modules/standard/GPU.html#GPU.deviceAttributes)
  function to query lower-level GPU properties.
  
  Beyond these new queries, Chapel 2.3 makes further improvements to
  the
  [`@gpu.itersPerThread`](https://chapel-lang.org/docs/2.3/modules/standard/GPU.html#GPU.@gpu.itersPerThread)
  attribute introduced in Chapel 2.2. This attribute enables mapping
  multiple iterations of a loop onto a single thread. However, the
  previous support was limited to mapping a contiguous chunk of
  iterations onto a thread. Such a mapping may not be desirable in
  some scenarios, since it may lead to sub-optimal memory access
  patterns. With Chapel 2.3, the `@gpu.itersPerThread` attribute
  accepts a flag to switch to cyclic mapping. With this mapping,
  neighboring threads will receive neighboring iterations, potentially
  resulting in higher memory throughput.  This is illustrated in the
  following example, along with the default blocked mapping:

  ```chapel
  on here.gpus[0] {
    @gpu.itersPerThread(10)
    foreach i in 1..100 {
      // we will get 100/10=10 threads
      // thread 0 will run 1..10
      // thread 1 will run 11..20 ...
    }

    @gpu.itersPerThread(10, cyclic=true)
    foreach i in 1..100 {
      // we will get 100/10 = threads again
      // thread 0 will run i=1, 11, 21 ...
      // thread 1 will run i=2, 12, 22 ...
    }
  }
  ```
  
  In this release cycle, we have also been working on improving the
  internal implementation to enable halting when GPU support is
  enabled, and to provide distributed arrays across GPUs. While
  Chapel&nbsp;2.3 has prototype support for 0-argument `halt()` calls,
  it is still a work in progress. Stay tuned!

  ### Dyno Compiler Improvements

  In recent years, our team has been working hard on an effort named
  _dyno_ to revamp the Chapel compiler.  The goals are to improve
  compile time, support interactive programming tools, and make it
  easier to write programs that process Chapel source code. This
  effort has already produced quite a few results:
  
  * more user-friendly error messages with [`--detailed-errors`](https://chapel-lang.org/docs/usingchapel/man.html#man-detailed-errors)
  * the [`chplcheck`](https://chapel-lang.org/docs/tools/chplcheck/chplcheck.html) linter

  * the [Chapel Language Server
    (CLS)](https://chapel-lang.org/docs/tools/chpl-language-server/chpl-language-server.html),
    which works with editors such as VS Code, Vim, or Emacs to
    provide interactive feedback while programming
  
  The next major milestone for the dyno effort is to finish the new
  incremental type and call resolver. This resolver is already
  available for use in an experimental way from the Chapel Language
  Server. In the 2.3 release, this new resolver has seen significant
  advances in support for promoted expressions, iterators, and
  domains. Stay tuned as we complete the effort and wire up the `chpl`
  compiler to use it in forthcoming releases.
  
  ### For More Information

  If you have questions about Chapel 2.3 or its new features, please
  reach out on Chapel's [Discourse
  group](https://chapel.discourse.group/) or one of our other
  [community forums](https://chapel-lang.org/community.html).  As
  ever, we're interested in feedback on how we can make the Chapel
  language, libraries, implementation, and tools more useful to you.
    
*/
