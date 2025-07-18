// Announcing Chapel 1.32!
// authors: ["Brad Chamberlain"]
// summary: "A summary of highlights from the September 2023 release of Chapel 1.32.0"
// featured: false
// tags: ["Release Announcements", "Chapel 2.0"]
// date: 2023-09-28

/*

  The Chapel developer community is excited to announce the release of
  Chapel version 1.32!  To obtain a copy, please refer to the
  [Downloading Chapel](https://chapel-lang.org/download.html) page on
  the Chapel website.

  ### Highlights of Chapel 1.32

  #### Chapel 2.0 Release Candidate

  The main highlight of Chapel 1.32 is that it is a release candidate
  for our forthcoming Chapel 2.0 release!  If you're not familiar with
  the concept of Chapel 2.0, it is intended to be a release that
  declares a core subset of the language and library features as
  'stable'.  These features are ones that we intend to support in
  their current form going forward, such that code relying on them
  will not break across releases.  Meanwhile, other features will be
  considered 'unstable', implying that they are ones where we are
  still learning from user experiences and refining interfaces before
  considering them to be stabilized.  Unstable features may continue
  evolving after the 2.0 release, either by improving them until they
  too are stable, or replacing them with other, more stable features.

  Chapel 1.32 being a 2.0 release candidate means that this is a key
  time for Chapel users to give us feedback about aspects of our
  design that they would like to see change prior to the 2.0 release.
  Users may also want to compile their programs with the
  `--warn-unstable` flag in order to identify any unstable features
  that they are currently relying upon.  Reliance on such features
  could motivate you to advocate for stabilizing those features sooner,
  or you could simply view it as an opportunity to be aware that those
  features may continue to evolve over time.  We are generally
  interested in hearing about which unstable features user code is
  currently relying upon, to help with our own prioritization efforts.

  Users with feedback about 2.0 readiness or the stability of current
  features are encouraged to share it with us on [Chapel's Discourse
  user forum](https://chapel.discourse.group/c/users/) or as a [GitHub
  issue](https://github.com/chapel-lang/chapel/issues).

  As part of the team's push to make this a worthy Chapel 2.0 release
  candidate, Chapel 1.32 contains a large number of improvements to
  the language, compiler, and libraries.  Some of these changes
  include:

  * new warnings to encourage a programming style in which generic
    types are more clearly visible in a program's source code

  * a change in the default intent for arrays and record receivers
    (i.e., `this`) to `const` for greater uniformity with other types

  * revised definitions of the compiler's interpretation of `const`
    intents and default return/yield intents

  * significant improvements to ranges, domains, and distributions,
    including converting distribution types to records, obviating the
    need for the `dmap` type

  * major improvements to the `IO`, `Math`, `BigInteger`, and `Time`
    modules, including a new IO serialization framework for specifying
    how to read and write types to files orthogonally from the file's
    format (see [below](#io-serialization-framework) for more detail)

  For more information about these changes, and many others not
  summarized here, refer to the
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/1.32/CHANGES.md)
  file, [documentation](https://chapel-lang.org/docs/1.32/) for Chapel
  1.32, or forthcoming [release note
  slides](https://chapel-lang.org/releaseNotes.html).

  #### GPU Improvements

  Version 1.32 includes significant improvements to Chapel's support
  for vendor-neutral GPU programming, both in terms of performance and
  capabilities.

  Key performance improvements include:

  * compiler optimizations to reduce the number of pointer
    dereferences when accessing arrays within GPU kernels

  * switching the default memory allocation scheme for arrays to
    'array_on_device' mode, in which an array's data is stored
    directly on the GPU rather than in managed memory

  * a reduction in overheads when invoking math routines within GPU
    kernels by eliminating unnecessary boilerplate wrapper code

  * using per-task GPU streams, which can enable
    communication-computation overlap to improve performance

  The non-trivial impact of these optimizations can be seen in the
  following graphs, which show the improvements that have occurred in
  a Chapel port of the SHOC Sort benchmark on both NVIDIA and AMD
  GPUs.  Note that the second graph includes data transfer times while
  the first does not.

  {{< figure src="SHOC-sort-combined.png" title="" class="fullwide" >}}

  Chapel's support for AMD effectively reaches feature parity with
  NVIDIA in this release, largely due to the addition of a number of
  math routines that had not been supported for AMD in
  Chapel&nbsp;1.31.  In addition, the Chapel compiler's `--savec` flag
  can now be used to inspect the assembly code generated when
  targeting AMD GPUs.

  Meanwhile, when targeting NVIDIA GPUs, Chapel 1.32 adds support for
  generating multi-architecture binaries by setting `CHPL_GPU_ARCH` to
  a comma-separated list of target architectures.

  See the latest [GPU
  Programming](https://chapel-lang.org/docs/1.32/technotes/gpu.html)
  technical note for additional details about these changes and
  Chapel's overall support for GPUs in 1.32.


  #### Support for Co-Locales

  Since its inception, Chapel has preferred to represent each compute
  node as a single top-level locale, using multitasking to implement
  any intra-node parallelism.  This approach has been beneficial in
  many problem domains where running a process per core could result
  in larger memory requirements or poor surface-to-volume effects due
  to the amount of {{< sidenote "right" "SPMD" -8
  >}}SPMD = Single Program, Multiple Data, a static and coarse-grained
  style of parallelism in which multiple copies of the same program
  are executed, e.g. one per processor core {{< /sidenote >}}
  parallelism.

  However, as modern compute nodes have begun to support multiple {{<
  sidenote "right" "NICs," >}}NICs = Network Interface
  Chips, which permit processes to communicate with remote nodes {{<
  /sidenote >}} this traditional approach has faced challenges.
  Specifically, it is unduly complicated to have a single locale (UNIX
  process) leverage multiple NICs effectively; yet using just one NIC
  leaves potential performance benefits on the floor by not exercising
  the network to its full capacity.

  To address this, Chapel 1.32 introduces user-facing support for
  _co-locales_, in which multiple locales can be mapped to a single
  compute node.  Using co-locales can lead to performance improvements
  by making better use of the network and/or reducing the number of
  memory references that cross between sockets.  For example, the
  following charts show improvements to a pair of benchmarks when run
  using two locales per node on a dual-NIC HPE Cray EX system using
  Slingshot 11:

  {{< figure src="co-locales-perf.png" title="" >}}

  Current support is limited to running a locale per socket on a given
  compute node, and is also limited to certain platforms and
  configurations:

  * HPE Cray EX platforms with Slingshot 11 when using `CHPL_COMM=ofi`

  * InfiniBand-based systems when using `CHPL_COMM=gasnet` with
    `CHPL_COMM_SUBSTRATE=ibv`

  * Configurations using `CHPL_LAUNCHER=slurm-srun` or `pbs-gasnetrun_ibv`

  To opt-in to using co-locales, specify the number of locales for your
  Chapel program using a product of nodes and locales per node.  For
  example, the following invocation:

  ```bash
  $ ./myChapelProgram -nl 8x2
  ```

  says to run the Chapel program on 8 nodes with 2 locales per node,
  for a total of 16 locales.

  For more information on using co-locales with Chapel, please refer
  to [the online
  documentation](https://chapel-lang.org/docs/1.32/usingchapel/multilocale.html#co-locales).



  #### IO Serialization Framework

  The IO serialization framework [that was prototyped in Chapel
  1.31](https://chapel-lang.org/blog/posts/announcing-chapel-1.31/#prototypical-support-for-io-serializers)
  is now used by default for calls like `writeln()` and `read()`, and
  it is also available for use with types written by end-users.

  As an illustration, consider the following example that prints an
  array in a couple of different formats:

*/

use IO, JSON;

var A = [1, 2, 3, 4];

writeln(A);             // prints '1 2 3 4'  // hugo-tag="normal-print"

var jsonWriter = stdout.withSerializer(jsonSerializer);  // hugo-tag="json-stdout"
jsonWriter.writeln(A);  // prints '[1, 2, 3, 4]'  // hugo-tag="json-print"

/*

  Line {{< get_line_anchor tag="normal-print" >}} uses a normal
  `writeln()` to print the array of integers to the standard console
  output&nbsp;(`stdout`) using Chapel's traditional format---one element
  at a time, separated by spaces.  Then, in line
  {{< get_line_anchor tag="json-stdout" >}}, we create a variant of `stdout`
  that uses the [JSON serializer](https://chapel-lang.org/docs/1.32/modules/standard/JSON.html)
  for all `write()`s called on it.  The result is that when we write
  the array to this output stream in line {{< get_line_anchor tag="json-print" >}},
  it is printed using standard JSON formatting.  Other current serializers support
  [binary](https://chapel-lang.org/docs/1.32/modules/standard/IO.html#IO.binarySerializer),
  [YAML](https://chapel-lang.org/docs/1.32/modules/packages/YAML.html),
  and [Chapel
  syntax](https://chapel-lang.org/docs/1.32/modules/packages/ChplFormat.html)
  as alternate formats.

  The new serialization framework also includes deserializers, which
  support reading values back in from the given format.  And most
  importantly, users can now define their own methods specifying how
  their types should be written or read.  This can be done in a
  format-neutral manner for simplicity, or in a way that's sensitive
  to the output format when needed.  For more information on defining
  these methods, please refer to [their online
  documentation](https://chapel-lang.org/docs/1.32/modules/standard/ChapelIO.html#the-serialize-and-deserialize-methods).


  #### Improved ARM64 Support

  Thanks to our colleagues on the
  [Qthreads](https://www.sandia.gov/qthreads/) team at Sandia National
  Laboratories, support for ARM64 chips is significantly improved in
  Chapel 1.32.  Specifically, this release bundles version 1.19 of
  Qthreads, in which task creation and switching have been
  re-implemented using assembly code for ARM64 chips.  This can
  dramatically reduce multitasking overheads when using Chapel's
  preferred `CHPL_TASKS=qthreads` mode.


  As a simple illustration, the following table shows the impact of
  this fast task switching on a 16-node run of
  [Bale](https://github.com/jdevinney/bale) Index Gather using various
  implementation strategies:

  {{< alttable >}}

  | Approach                | w/out fast tasks | with fast tasks  | improvement |
  |-------------------------|-----------------:|-----------------:|:-----------:|
  | ordered                 |   70.7 MB/s/node |   84.7 MB/s/node |       1.20x |
  | ordered, oversubscribed |   86.3 MB/s/node |  140.4 MB/s/node |       1.63x |
  | unordered               |  147.5 MB/s/node |  152.3 MB/s/node |       1.03x |
  | aggregated              | 1352.0 MB/s/node | 1448.5 MB/s/node |       1.07x |


  In addition, Qthreads 1.19 also improved portability for ARM64-based
  platforms.  This enables the use of `CHPL_TASKS=qthreads` on a wider
  variety of systems, such as M1/M2 Macs, where it is now the default.


  #### And much more...

  Beyond the highlights mentioned here, Chapel 1.32 contains numerous
  other improvements to Chapel's features and interfaces, such as:

  * initial support for array allocations that will throw if the
    system is out of memory

  * a more robust set of types and routines for dealing with C pointer
    types, particularly with respect to `const`-ness

  * initial support for interface declarations, to opt-in to special
    methods like the serialization methods mentioned above

  * features for power users to better understand the vectorization
    and transformation of their Chapel programs

  * support for selecting between processor types on chips with
    heterogeneous processing units

  For a more complete list of changes in Chapel 1.32, please refer
  to its
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/1.32/CHANGES.md)
  file.


  ### For More Information

  For questions about any of the changes in this release, please reach
  out to the developer community on [Discourse](https://chapel.discourse.group/).

  As always, we’re interested in feedback on how we can help make the
  Chapel language, libraries, implementation, and tools more useful to
  you in your work.

  And always, thanks to [everyone who
  contributed](https://github.com/chapel-lang/chapel/blob/release/1.32/CONTRIBUTORS.md)
  to the Chapel 1.32 release!

*/

