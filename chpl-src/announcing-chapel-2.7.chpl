// Announcing Chapel 2.7!
// authors: ["Jade Abraham", "Engin Kayraklioglu", "Daniel Fedorin", "Ben Harshbarger", "Brad Chamberlain"]
// summary: "Highlights from the December 2025 release of Chapel 2.7"
// tags: ["Release Announcements", "Debugging", "Tools", "Dyno"]
// date: 2025-12-18
/*

  The Chapel developer community is pleased to announce the release of
  Chapel 2.7!  Notably, this is the first version of Chapel to be made
  available since our project [joined the High Performance Software
  Foundation](https://hpsf.io/blog/2025/hpsf-welcomes-chapel/) this
  fall.

  As always, you can [download and
  install](https://chapel-lang.org/download/) this new version in a
  {{<sidenote "right" "variety of formats">}}Please note that some
  formats may not yet be available at time of
  publication...{{</sidenote>}}, including Spack, Docker, Homebrew,
  various Linux package managers, and source tarballs.

  This article introduces some of the highlights of Chapel 2.7,
  including:

  * A new compiler flag supporting [vector libraries](#vector-library)

  * Improvements when [debugging Chapel programs](#debugging-enhancements)

  * [Stack traces](#stack-traces) on fatal errors by default

  * Enhancements to [Mason](#mason), Chapel's package manager

  * Improvements to the capabilities of the [Dyno compiler
    front-end](#improvements-to-the-dyno-compiler-front-end)


  In addition to the above features, Chapel 2.7 also includes
improvements to the pre-built [Linux
packages](https://chapel-lang.org/download/#linux), in terms of
features and flexibility.

  For more information, or a much more complete list of changes in
  Chapel 2.7, see the
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/2.7/CHANGES.md)
  file.  And as always, thanks to [everyone who
  contributed](https://github.com/chapel-lang/chapel/blob/release/2.7/CONTRIBUTORS.md)
  to version 2.7!


  ### Using vector libraries

  One of the nice performance-oriented features added in this release
  improves the vectorization capabilities of the Chapel compiler
  through vector math libraries.  Chapel already does a good job of
  {{<sidenote "right" "vectorizing code">}}Vectorization is turning
  scalar code into vector code to make use modern CPU's SIMD
  capabilities.{{</sidenote>}}, particularly when making use of vector
  math libraries such as Libmvec or SVML to accelerate math-heavy
  code.  However, using such libraries has traditionally not been a
  very user-friendly experience, requiring users to specify low-level
  C/LLVM flags to enable this extra performance.

  In this release, we added `--vector-library`, a new Chapel compiler
  flag that makes it easy to enable vector math libraries in Chapel
  programs. This flag takes one argument providing the name of the
  vector library to use. For example, to use Libmvec on x86 systems,
  you can compile your program like so:

  ```console
  $ chpl --fast --no-ieee-float --vector-library LIBMVEC-X86 myBenchmark.chpl 
  ```

  This makes it easier to vectorize code like the example below, which
  raises each element of an array to a random scalar power. Normally,
  this code would either not be vectorized at all or would require
  low-level tricks to get vectorized performance.  Using
  `--vector-library`, the compiler can automatically make use of
  vector math libraries to enable big performance improvements.

*/

use Random;

config const N = 1000;

proc main() {
  const scalar = (new randomStream(real)).next();
  var Arr, Res: [1..N] real;

  fillRandom(Arr);
  kernel(Res, Arr, scalar);
  writeln(Res);
}

proc kernel(ref Res, Arr, scalar) {
  foreach (r, a) in zip(Res, Arr) {
    r = a ** scalar;
  }
}

/*

  Benchmarking the code above to see how much of an impact
  `--vector-library` would have, we saw more than a
  2<small>$\times$</small> speedup to the `kernel()` call when using
  `--vector-library=LIBMVEC-X86` on a 32-core AMD EPYC 7543P
  processor, as compared to compiling without a vector library.

  The `--vector-library` flag is a new addition to Chapel's
  performance optimization toolkit, making it easier than ever to get
  high-performance vectorized code. We plan to continue improving the
  ergonomics of this flag in future releases by introducing
  platform-independent ways of referring to the libraries without
  having to embed names that are specific to the back-end compiler or
  CPU (like `-X86` in the example above).


  ### Debugging

  A big theme of our last few releases has been improving the ability
  to debug Chapel programs. For this release, we continued this focus
  by making further improvements to the debugging experience.

  #### Multi-locale debugging

  In the Chapel 2.6 release, we introduced a new [prototype parallel
  debugger]({{<relref announcing-chapel-2.6>}}#prototype-parallel-debugger)
  for multi-locale programs. This tool permits users to step through
  their multi-locale executions in a single terminal window, setting
  breakpoints and inspecting variables on any given locale.

  This release adds support for Chapel's {{<sidenote "right"
  "global namespace">}}In Chapel, if a variable is visible within a
  given scope, it is available for use by the programmer even if it is
  stored on a remote locale.{{</sidenote>}} to the debugger.  This
  means that while debugging a particular locale, values stored on
  another locale can be inspected. Combined with the ability to
  pretty-print Chapel types, as introduced in the last release,
  debugging Chapel programs has never been easier.

  As an example of this, consider the following example, which declares
  an array on locale 1 and then accesses it remotely from locale 0:

  {{<file_download fname="debug.chpl" lang="chapel" >}}

  The following screenshots illustate a debugging session for this
  program starting from the point when we hit the initial breakpoint
  on locale 1 (where we already happen to be in locale 1's context).
  We start by printing `myArr`, which prints its values:

  {{<figure class="fullwide" src="firstLocale.jpg">}}

  We then continue execution and hit the next breakpoint.  The
  debugger informs us that it was a task on locale 0 that hit this
  breakpoint by printing `Target 0: …`.  We can then use `on 0` to
  switch the current debugger context to locale 0 and print out
  `myArr` there as well:

  {{<figure class="fullwide" src="otherLocale.png">}}

  Note that on locale 0, `myArr` has a type of `ref(_array(…))`,
  indicating that the array we're printing is actually a reference to
  the array on locale 1.  Notably, we can still print its contents
  despite it being stored remotely.

  We are continuing to improve `chpl-parallel-debug` for future
  releases and welcome feedback on how to make it even better.

  #### Compiler Flags for Debugging

  Another big improvement to the user experience of debugging Chapel
  involves changes to the compiler's flags for debugging.  The
  previous best practice for debugging Chapel involved compiling with
  debug symbols (`-g`) along with several additional flags to disable
  various Chapel optimizations. Optimizations are great for
  performance, but by nature they can make debugging more difficult
  due to their tendency to obscure the correspondence between source
  code and generated code. For example, this can lead to confusing
  behavior when stepping through code or inspecting variables.  Yet,
  knowing which optimizations to disable required a familiarity with
  the Chapel compiler, not to mention lots of flags to be thrown,
  neither of which was ideal.

  To improve this situation, we've added a new compiler flag,
  `--debug-safe-optimizations-only`, which disables a set of
  optimizations that are known to interfere with debugging.  With this
  flag, users can now compile for debugging with 2 flags:


  ```console
  chpl -g --debug-safe-optimizations-only myProgram.chpl
  ```

  However, even this felt {{<sidenote "right" "too verbose">}}We pride
  ourselves on simple and clear flags, like `--fast` to make your code
  go fast!{{</sidenote>}}, so we adjusted the behavior of `--debug` to
  imply `-g` and<br> `--debug-safe-optimizations-only`. This means
  that the preferred debugging configuration can now be achieved with
  just a single flag!

  ```console
  chpl --debug myProgram.chpl
  ```

  #### Improved stack traces

  Another aspect of debugging is being able to diagnose and fix
  execution-time errors.  When a halt occurs in a Chapel program, it
  can be difficult to figure out where the error occurred and what
  caused it.  As an example, consider the following program, which
  prints out parts of an array using different slice arguments:

  {{<file_download fname="outOfBounds.chpl" lang="chapel" >}}

  One of the slices results in an out-of-bounds array access when
  compiled with `--checks` (Chapel's default).  In Chapel 2.6, you
  would get an error like this by default:

  ```console
  outOfBounds.chpl:14: error: halt reached - array index out of bounds
  note: index was 10 but array bounds are -9..9
  ```

  This doesn't provide enough information to figure out which slice is
  causing the halt.  Prior to today's release, there are a few ways
  you might figure this out:

  * Add lots of `writeln()` statements to narrow down where the error
    is occurring.

  * Run the program in a debugger, which will stop execution at the
    point of the halt, permitting a backtrace to be inspected.

  * Rebuild the Chapel runtime and program with stack unwinding
    enabled, causing a stack trace to be printed on halt.

  All of these options require extra work on the part of the user,
  either by changing their program or changing their Chapel
  installation.

  To improve this, in Chapel 2.7, the default build configuration and
  release formats now have stack unwinding support enabled by default.
  As a result, when compiling the program above {{<sidenote "right"
  "with debugging on">}}Note that compiling without debugging will
  also result in a stack trace, simply one with less precise line
  number information.{{</sidenote>}} and running it:

  ```console
  $ chpl --debug outOfBounds.chpl
  $ ./outOfBounds
  ```

  the following stack trace is now printed upon hitting the error:


  ```console
  outOfBounds.chpl:14: error: halt reached - array index out of bounds
  note: index was 10 but array bounds are -9..9
  Stacktrace
  
  halt() at $CHPL_HOME/modules/standard/Errors.chpl:762
  checkAccess() at $CHPL_HOME/modules/internal/ChapelArray.chpl:873
  this() at $CHPL_HOME/modules/internal/ChapelArray.chpl:1002
  this() at $CHPL_HOME/modules/internal/ChapelArray.chpl:1036
  printSlice() at outOfBounds.chpl:14
  main() at outOfBounds.chpl:4
  
  Disable full stacktrace by setting 'CHPL_RT_UNWIND=0'
  ```

  This stack trace shows the call chain that led to the halt, making
  it much easier to identify the source of the error. Specifically, it
  points to the slice on line four, `0.. by 2 # 6`, as the culprit for
  the bug.  By eliminating the need for extra steps to get a stack
  trace, we hope that diagnosing runtime errors in Chapel programs
  becomes easier than ever!


  ### Mason Improvements

  Chapel 2.7 includes a slew of improvements to Mason, Chapel's
  package manager. The first highlight is better integration with
  Chapel's ever-growing tooling support.  In Chapel 2.6, VSCode users
  had to take additional steps to configure the language server so
  that it could recognize a Mason package's structure. Without that
  additional step, users would get errors about the Chapel compiler
  not being able to find a module included in the Mason package, like
  the following::

  {{< figure class="fullwide" src="mason-cls-26.png" >}}

  With Chapel 2.7, the additional step for Mason packages is no longer
  necessary.  Compare the screenshot using Chapel 2.7 below to the one
  above to see the difference!

  {{< figure class="fullwide" src="mason-cls-27.png" >}}

  Another new Mason feature is support for _prerequisites_.  This
  feature supports code in other languages that needs to be compiled
  or bootstrapped in some way before compiling the Chapel code for the
  Mason application or library. A common use case for prerequisites is
  to bundle some C code that a Chapel-based library would call into
  via interoperability. With the Chapel 2.7 version of Mason, package
  implementers can add code in other languages to be compiled
  alongside the Chapel code.

  The initial implementation for prerequisites involves extending
  Mason's standard directory structure to specify prerequisites, how
  to build them, and how to incorporate them into the Chapel
  compiler's command-line.  For example, a Mason package with a
  C-based prerequisite might use a directory structure like this:

  ```
  MyMasonPackage/
  ├── src/
  │   └── MyMasonPackage.chpl
  ├── prereqs/
  │   └── SomePrereq/
  │       └── code.c
  │       └── header.h
  │       └── Makefile
  └── Mason.toml
  ```

  To learn more about Mason's new prerequisites feature, check out the
  new section of Mason's documentation, [Building Code in Other
  Languages](https://chapel-lang.org/docs/main/tools/mason/guide/prereqs.html).

  Meanwhile, we're working on further generalizations to supporting
  prerequisites.  [Issue
  #28174](https://github.com/chapel-lang/chapel/issues/28174) captures
  some of our ideas, and we are interested in receiving your comments
  about the feature there as well.

  Finally, two additional Mason highlights in Chapel 2.7 are that
  Mason performance has improved significantly, and we have started to
  modernize Mason's integration with [Spack](https://spack.io/), a
  popular package manager designed for HPC.


  ### For More Information

  If you have questions about Chapel 2.7 or any of its new features,
  please reach out on Chapel's [Discord
  channel](https://discord.gg/xu2xg45yqH), [Discourse
  group](https://chapel.discourse.group/), or one of our other
  [community forums](https://chapel-lang.org/forums/).  We're also
  always interested in hearing about how we can make the Chapel
  language, libraries, implementation, and tools more useful to you.

*/
