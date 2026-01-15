// Announcing Chapel 1.31!
// authors: ["Brad Chamberlain"]
// summary: "A summary of highlights from the June 2023 release of Chapel 1.31.0"
// tags: ["GPUs", "Dyno", "Chapel 2.0", "I/O"]
// series: ["Release Announcements"]
// date: 2023-06-22

/*

  The Chapel developer community is happy to announce the release of
  Chapel version 1.31!  To obtain a copy, please refer to the
  [Downloading Chapel](https://chapel-lang.org/download.html) page on
  the Chapel website.

  ### Highlights of Chapel 1.31

  #### GPU Improvements

  Since the 1.30 release, our GPU subteam has continued to improve the
  generality and flexibility of Chapel's support for NVIDIA and AMD
  GPUs.  Most notably, Chapel 1.31 extends Chapel's previous support
  for AMD GPUs to include multi-locale executions, permitting a Chapel
  program to now run across multiple compute nodes utilizing one or
  more AMD GPUs on each.  As a result, the same source code can now
  target GPUs in a vendor-neutral manner using Chapel's high-level
  features such as on-clauses, parallel loops, and its partitioned
  global namespace.  As a trivial example, here is a STREAM
  Triad-style computation that can exercise all of the AMD or NVIDIA
  GPUs and CPUs of your cluster or supercomputer in parallel:

*/

config const n = 1_000_000,
             alpha = 0.01;

coforall loc in Locales {
  on loc {
    cobegin {
      // have one task explicitly spawn off a Triad task per GPU
      coforall gpu in here.gpus do on gpu {
        var A, B, C: [1..n] real;
        A = B + alpha * C;
      }

      // have the other use data parallelism to target all CPU cores
      {
        var A, B, C: [1..n] real;
        A = B + alpha * C;
      }
    }
  }
}

/*

  Next up in our vendor neutrality portfolio: Intel.

  Chapel 1.31 also adds prototype support for [peer-to-peer
  accesses](https://chapel-lang.org/docs/1.31/technotes/gpu.html#device-to-device-communication-support)
  for copying data between connected GPU devices.  And for developers
  who would like to evaluate the eligibility of their Chapel code for
  GPUs without access to physical GPUs or vendor SDKs, we have
  introduced a new [CPU-as-device
  mode](https://chapel-lang.org/docs/1.31/technotes/gpu.html#cpu-as-device-mode).
  This mode uses Chapel's GPU locale model, yet all execution and data
  allocation are performed on the CPU.  As a result, loops can be
  checked, measured, and monitored for GPU eligibility without needing
  access to the GPUs during development.

  In addition, Chapel 1.31 improves the generality of code patterns
  that can be executed on GPUs to include recursion and passing arrays
  by reference.  It also provides a new `--report-gpu` flag that gives
  feedback on which Chapel loops are, or are not, eligible for GPU
  computation.

  For a full rundown of Chapel support for GPUs in 1.31, please refer
  to the [GPU
  Programming](https://chapel-lang.org/docs/1.31/technotes/gpu.html)
  technote as well as the
  [`GPU`](https://chapel-lang.org/docs/1.31/modules/standard/GPU.html)
  and
  [`GpuDiagnostics`](https://chapel-lang.org/docs/1.31/modules/standard/GpuDiagnostics.html)
  modules.


  #### Scope Resolution and Errors by 'Dyno'

  A very significant change for the Chapel compiler that we hope will
  mostly go unnoticed by users, is that the _Dyno_ scope resolver is
  now used by default in the production compiler.  If you're
  unfamiliar with Dyno, it is our recent effort to revamp,
  re-architect, and refactor the Chapel compiler to evolve it from its
  research prototype roots to the production-grade tool that users and
  developers increasingly require.

  While previous releases began making use of Dyno's parser and AST,
  Chapel 1.31 performs scope resolution using Dyno.  Scope resolution
  is the process within the `chpl` compiler of determining what
  module, variable, type, etc. each identifier refers to.  For
  subroutine calls, scope resolution computes which subroutines an
  identifier refers to and the later step of overload resolution will
  choose between these.
  
  In addition to scope resolution, Dyno's new error-reporting
  framework is now being used in production.  This supports clearer
  messages for errors in the front-end that have been converted to the
  new framework.  It also supports a `--detailed-errors` mode for such
  errors, which provides more detail about them and potential ways to
  address them.

  Next up, Dyno is well on its way towards taking over the type
  inference and call resolution steps of compilation, which have
  traditionally been one of the chief sources of slow compilation
  times in the production compiler.  We are cautiously optimistic that
  this will result in overall improvements to compilation time through
  the combination of re-implementation and the use of incremental
  recompilation techniques.


  #### Language, Library, and Compiler Improvements

  As part of our ongoing effort to stabilize core Chapel language and
  library features, Chapel 1.31 contains numerous improvements to
  naming and behaviors designed to support our forthcoming Chapel 2.0
  release.  These changes include a significant revamp of how range
  types are expressed and represented, summarized in the [Chapel
  Evolution](https://chapel-lang.org/docs/1.31/language/evolution.html)
  document.  Beyond that, a number of standard library APIs have been
  improved in terms of naming and behaviors, most notably in the
  [`BigInteger`](https://chapel-lang.org/docs/1.31/modules/standard/BigInteger.html),
  [`CTypes`](https://chapel-lang.org/docs/1.31/modules/standard/CTypes.html),
  [`List`](https://chapel-lang.org/docs/1.31/modules/standard/List.html),
  and
  [`Time`](https://chapel-lang.org/docs/1.31/modules/standard/Time.html)
  modules.  This fall's 1.32.0 release of Chapel is expected to be a
  release candidate for Chapel 2.0, so if you're aware of core
  language or library features that should be changed, the coming
  months are the time to advocate for them!

  Chapel 1.31 also extends the `chpl` compiler to support version 15
  of LLVM as its preferred back-end.  While most of our previous LLVM
  version updates have been reasonably straightforward, this one
  involved significant modifications to the compiler to adapt to
  fundamental changes in LLVM's program representation, and a big
  effort by the team to keep everything working.  Though we've started
  on the job of updating `chpl` to support LLVM 16, it will require
  updates to how our passes are run, so will only be supported in a
  future release.


  #### Prototypical Support for IO Serializers

  Chapel 1.31 also includes a few features that are not yet ready for
  prime-time, yet which may be worth experimenting with for those who
  are interested.  Chief among these is a new prototypical API for
  defining how types should be serialized and deserialized for IO
  operations in a format-independent manner.  To learn more about
  this framework, refer to the [IO Serializers and
  Deserializers](https://chapel-lang.org/docs/1.31/technotes/ioSerializers.html)
  technote.  Or try it out using one of the new package modules that
  leverage this framework to do IO in
  [JSON](https://chapel-lang.org/docs/1.31/modules/packages/Json.html),
  [YAML](https://chapel-lang.org/docs/1.31/modules/packages/Yaml.html),
  [binary](https://chapel-lang.org/docs/1.31/modules/packages/BinaryIO.html),
  or
  [Chapel](https://chapel-lang.org/docs/1.31/modules/packages/ChplFormat.html)
  formats.



  #### And much more...

  Beyond the highlights mentioned here, Chapel 1.31 contains
  numerous improvements to Chapel's features and interfaces,
  including:

  * improved performance for `bigint` operations and `Time` routines
    in multi-locale executions, and for large IO operations in general

  * prototype support for redistributing `Block`-distributed arrays
    and domains

  * numerous improvements in terms of portability, documentation,
    and fixes for user-reported bugs.


  For a more complete list of changes in Chapel 1.31, please refer
  to its
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/1.31/CHANGES.md)
  file.


  ### For More Information

  For questions about any of the changes in this release, please reach
  out to the developer community on [Discourse](https://chapel.discourse.group/).

  As always, we’re interested in feedback on how we can help make the
  Chapel language, libraries, implementation, and tools more useful to
  you in your work.

  Thanks to [everyone who
  contributed](https://github.com/chapel-lang/chapel/blob/release/1.31/CONTRIBUTORS.md)
  to Chapel 1.31!

*/

