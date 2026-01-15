// Announcing Chapel 1.29.0!
// authors: ["Brad Chamberlain"]
// summary: "A summary of highlights from the December 2022 release of Chapel 1.29.0"
// tags: ["Optimizations", "Libraries", "Chapel 2.0", "Dyno", "Language Features"]
// series: ["Release Announcements"]
// date: 2022-12-15

/*

  Today, the Chapel developer community is pleased to announce the
  release of version 1.29.0 of Chapel!  To obtain a copy, please refer
  to the [Downloading Chapel](https://chapel-lang.org/download.html)
  page on the Chapel website.

  ### Highlights of Chapel 1.29.0

  #### Compilation Times

  This version of Chapel includes a change to how the `chpl` compiler
  is built, causing it to use `jemalloc` by default on all platforms
  other than Mac and Cygwin.  We've found this to result in a
  significant compile-time savings on average, as can be seen on
  October&nbsp;10th in our [nightly performance graph tracking average
  compilation
  times](https://chapel-lang.org/perf/comp-default/?startdate=2022/09/06&enddate=2022/12/07&graphs=averagetotalcompilationtime)
  across the Chapel test suite.

  #### Optimized Performance

  In terms of the performance of Chapel programs themselves, version
  1.29.0 includes improvements to the performance and scalability of
  [creating distributed domains and
  arrays](https://chapel-lang.org/perf/16-node-cs-hdr/?startdate=2022/10/09&enddate=2022/12/14&configs=ofi&graphs=creatingdistributeddomains,creatingdistributedarrays1elementperlocale).
  In practice, these improvements have been shown to improve execution
  time of user applications that create and destroy arrays frequently,
  such as
  [Arkouda](https://github.com/Bears-R-Us/arkouda/blob/master/README.md).

  #### Library Stabilization

  A large number of the changes in Chapel 1.29.0 involve continued
  improvements to our standard library modules in terms of renamings,
  behavior improvements, and the like as part of our preparation for
  the forthcoming Chapel 2.0 release.  The standard [IO
  module](https://chapel-lang.org/docs/1.29/modules/standard/IO.html)
  in particular has undergone some fairly significant improvements and
  changes, including:

  * new `readAll()`, `readBinary()`, and `writeBinary()` routines
  * new `fileReader` and `fileWriter` types that replace the previous `channel` type
  * an improved interpretation of range-based `region` arguments in IO routines
  
  as well as numerous other naming improvements to routines and
  deprecations of stale functionality.

  #### Better Error Messages via 'dyno'

  Within the compiler's code base, we have continued making good
  strides with our 'dyno' project, whose goal is to dramatically
  revamp and modernize Chapel's compilation architecture to improve
  compilation times, support separate compilation, etc.  Most of these
  changes are not yet visible to the typical end-user, though one nice
  one is: A new error-reporting framework has been developed that is
  now used for all parser errors in the production compiler.

  As a result of this change, parse errors now have both a (default)
  compact message as well as a more detailed one designed to help
  users cope with the error.  To opt in to the latter, compile with
  the experimental `--detailed-errors` flag.  For example, given the
  erroneous program:

*/

record R {
  var x: int;
}
var x = new R;

/*

  the default error message is:

  ```
  $ chpl newR.chpl 
  newR.chpl:4: syntax error: 'new' expression is missing its argument list
  ```

  Meanwhile, recompiling with the new flag gives:

  ```
  $ chpl newR.chpl --detailed-errors
  ─── syntax in newR.chpl:4 [NewWithoutArgs] ───
    'new' expression is missing its argument list.
    'new' expression used here:
        |
      4 | var x = new R;
        |
    Perhaps you intended to write 'new R()' instead?
  ```

  #### Overload Resolution

  Chapel 1.29.0 continues the improvements to overload selection
  started in Chapel 1.28.0 by preferring procedures that are generic
  over those that require an implicit conversion to resolve.  For
  example, consider these procedure overloads:

  ```chapel
  proc f(x)       { writeln("In generic version"); }
  proc f(x: real) { writeln("In 'real' version"); }

  ```

*/

/*

  In Chapel 1.28.0, a call like `f(42)` would have preferred the
  `real` version, but now prefers the generic version, considering it
  a more precise match.  This behavior makes Chapel's overload
  selection more similar to C++ as well as more self-consistent with
  other Chapel cases involving generics.

  #### Notable Bug Fixes

  A number of user-identified bugs were fixed in this release, including:
  * an issue in which param `NaN` and infinity values wouldn't implicitly convert to `real(32)`
  * broken virtual method calls with `ref` arguments or return intents
  * internal errors stemming from certain module-qualified types and conditionals within loops
  * a subtle issue regarding remote variable accesses within `export` procedures

  ### Experimental Features

  Turning to experimental features, Chapel 1.29.0 introduces a new
  'weak' class reference concept for use when working with `shared`
  class variables.  Though the details of the syntax and interface are
  still being finalized, this would be a great time to experiment with
  the feature and offer feedback.  See the
  ['WeakPointer'](https://chapel-lang.org/docs/1.29/builtins/WeakPointer.html)
  page for details.

  The `chpl` compiler now also supports a prototype capability to
  capture the generated assembly for a given routine.  See
  '[Inspecting the Generated
  Code](https://chapel-lang.org/docs/1.29/technotes/llvm.html#inspecting-the-generated-code)'
  in the LLVM technical note for more information.

  In other news, this release includes very experimental support for
  running Chapel programs on AMD GPUs and for dedicating a core to
  handling the Chapel runtime's active messages on Slingshot-11
  systems.

  ### For More Information

  For a more complete list of changes in Chapel 1.29.0, see its
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/1.29/CHANGES.md)
  file.  For questions about any of the changes in this release,
  please reach out to the team on
  [Discourse](https://chapel.discourse.group/).

  As always, we’re interested in feedback on how we can help make the
  Chapel language, libraries, implementation, and tools more useful to
  you in your work.

  Thanks to [everyone who
  contributed](https://github.com/chapel-lang/chapel/blob/release/1.29/CONTRIBUTORS.md)
  to Chapel 1.29.0!

*/

