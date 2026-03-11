// Announcing Chapel 2.8!
// authors: ["Jade Abraham", "Daniel Fedorin", "Ben Harshbarger", "Brad Chamberlain"]
// summary: "Highlights from the March 2026 release of Chapel 2.8"
// tags: []
// series: ["Release Announcements"]
// date: 2026-03-12
/*

  The Chapel developer community is pleased to announce the release of
  Chapel 2.8!  As with other recent releases, a big focus of this
  version is improvements to Chapel's tools ecosystem.

  As always, you can [download and
  install](https://chapel-lang.org/download/) this new version in a
  {{<sidenote "right" "variety of formats">}}Please note that some
  formats may not yet be available at time of
  publication...{{</sidenote>}}, including Spack, Homebrew, various
  Linux package managers, Docker, and source tarballs.

  This article summarizes a few of the highlights of Chapel 2.8,
  including:

  * 

  In addition to the items above, Chapel 2.8 also includes the
  following improvements, which are not covered in more detail in this
  article (click on the links for more information).

  * Support for [running Chapel on RISC-V
    processors](https://chapel-lang.org/docs/2.8/platforms/riscv.html#using-chapel-on-risc-v)
    using lightweight tasking provided by Qthreads version 1.23 from
    Sandia National Laboratories

  * Support for AMD GPUs running ROCm versions 6.3 or 7

  * Support for LLVM 21 as the Chapel compiler back-end

  * 

  For a much more complete list of changes in Chapel 2.8, see the
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/2.8/CHANGES.md)
  file.  And a big thanks to [everyone who
  contributed](https://github.com/chapel-lang/chapel/blob/release/2.8/CONTRIBUTORS.md)
  to Chapel 2.8!


  ### Chapel Language Server and Linter

  [Since its 2.0 release]({{< relref
  "announcing-chapel-2.0#rich-tooling-support" >}}), Chapel has
  provided two tools that enable users to write code more
  productively: the [Chapel Language Server
  (CLS)](https://chapel-lang.org/docs/2.8/tools/chpl-language-server/chpl-language-server.html)
  and the [`chplcheck`
  linter](https://chapel-lang.org/docs/2.8/tools/chplcheck/chplcheck.html).
  The 2.8 release includes improvements to both of these tools.

  #### CMake Integration

  As of the 2.8 release, Chapel's CMake integration can
  use the
  [`chpl-shim`](https://chapel-lang.org/docs/2.8/tools/chpl-language-server/chpl-language-server.html#configuring-chapel-projects)
  tool (previously written about in [our article on editor
  integration]({{< relref "chapel-lsp#using-cls-in-your-application"
  >}})) to generate a `.cls-commands.json` file for a Chapel
  project. This significantly improves the experience of using CLS
  with CMake-based Chapel projects, since it allows the editor to
  reason natively about the project's source structure.  This new
  integration also enables other patterns, such as source generation:
  generated files in the `build` directory (e.g.) can now be properly
  found and integrated with other files in the project.

  Enabling this integration boils down to using the new
  `CMAKE_EXPORT_CHPL_COMMANDS` environment variable:

  ```bash
  mkdir build
  cmake -B build -DCMAKE_EXPORT_CHPL_COMMANDS=ON
  cmake --build build
  ```

  The `build` directory will then contain a `.cls-commands.json`
  file. A common pattern is to then symbolically link this file to the
  project root:

  ```bash
  ln -s build/.cls-commands.json .cls-commands.json
  ```

  From there, the CLS should be usable as normal. Subsequent builds
  should update the `.cls-commands.json` file if necessary.


  #### Resolution and Inlays

  When we first wrote about the CLS, we covered [language server
  features that relied on resolution]({{< relref
  "chapel-lsp#experimental-features" >}}), dubbing them
  experimental. At that time, the Dyno resolver was in a much
  more primitive state; it was in the [2.3 release]({{< relref
  "announcing-chapel-2.3#dyno-compiler-improvements" >}}) that Dyno
  acquired the ability to resolve domains and promoted expressions,
  and in the [2.4 release]({{< relref
  "announcing-chapel-2.4#dyno-support-for-chapel-features" >}})
  it was able to resolve arrays. However, the Dyno resolver has
  continued to make great strides, and today is capable of resolving a
  substantial (though not complete) portion of the language. As a
  result, the experimental support for resolution-driven features in
  the CLS has been steadily growing more robust.

  In the 2.8 release, we've spent some time tracking down bugs that
  specifically affected the CLS with well-known codebases such as
  [Mason](https://chapel-lang.org/docs/2.8/tools/mason/mason.html). The
  result should be a relatively stable experience when using these
  resolution-driven features. Below is a screenshot of inferred types
  and other information (lighter background; blue font) while editing
  a part of the Mason codebase. Notably, the `execopts.these()` call
  at the end of the block demonstrates a resolved iterator, while
  other hints in this file show off successfully-resolved calls to
  other modules in the Mason source code, as well as correct understanding of
  bundled package types such as `Toml`.

  {{< figure class="fullwide" src="mason-cls-28.png" >}}

  We've also improved the behavior of information displayed in this
  manner ("inlays", in language server terminology). Specifically,
  since CLS presently computes this information upon saving a file, we
  have adjusted the inlays to be invalidated (if necessary) when
  editing a file, until the file is saved.  This avoids pain from
  stale inlays intermingling with source code as it is being modified.

  #### New Linting Checks

  Building on a number of improvements to our compiler's tracking of
  source locations in this release, we've also introduced a number of
  new rules to the `chplcheck` linter. This includes:

  * `BoolComparison`, which flags patterns such as `e == true` (which
    ought to be written as `e` instead).

  * `UnattachedCurly`, which flags code where the curly brace doesn't
    immediately follow the condition of a control flow statement.

  * `ThenKeywordAndBlock`, for patterns fuch as `if e then { ... }`,
    where the `then` is redundant.

  The following animated GIF demonstrates these checks being flagged,
  as well as `chplcheck`'s built-in functionality to automatically fix
  them.

  {{< figure class="fullwide" src="new-rules.gif" >}}


  ### Debugging

  In this release, we continued improving the debugging experience for
  Chapel users.  Chapel 2.8 adds new pretty-printers for common Chapel
  data structures, like `list`, `set`, and `map`, as well as for
  Chapel's distributed arrays.  In addition, this release expands the
  set of expressions that can be evaluated within the debugger

  #### New pretty-printers

  As an example of the new pretty-printing capabilities, consider the
  following program that has a simple bug in it since it tries to
  access a key in a map that doesn't exist:

  ```chapel
  use Map;

  proc getIt(m) {
    var val = m["it"];  // this is an error since 'it' wasn't stored in map 'm'
    return val;
  }

  proc main() {
    var m: map(string, int);
    m["this"] = 22;
    m["or"] = 33;
    m["that"] = 44;
    var val = getIt(m);
    writeln('m["it"] is ', val);
  }
  ```

/*
  If we run this program, it will halt.

  ```
  uncaught KeyNotFoundError: key 'it' not found
    mapDebug.chpl:4: thrown here
    mapDebug.chpl:4: uncaught here
  Stacktrace
  
  ./maopgetIt() at mapDebug.chpl:4
  main() at mapDebug.chpl:13
  ```

  Re-running in a debugger lets us jump to the stack frame where the
  error occurs and inspect the state of the program. With the new
  pretty-printers, we can easily see the contents of the map `m` and
  understand why the error is occurring.


  {{<figure class="fullwide" src="debugMap.png">}}

  These new pretty-printers are useful by themselves, but they are
  built on top of other new debugging improvements

  #### Expression Evaluation

  In this release, we dramatically improved the ability of the
  debugger to reason about Chapel expressions.  For example, consider
  the following program.

  ```chapel
  use List;
  use Random;

  var rs = new randomStream(real, 123456);

  record point {
    var x, y: real;
  }

  proc point.distanceTo(other: point) do
    return sqrt((other.x - this.x)**2 + (other.y - this.y)**2);

  proc main() {
    var points: list(point);
    for 1..10 do
      points.pushBack(new point(rs.next(-10.0, 10.0),
                                rs.next(-10.0, 10.0)));
    writeln("points: ", points);
    for i in 0..<points.size {
      for j in 0..<points.size {
        if i == j then continue;
        var d = points[i].distanceTo(points[j]);
        writef("distance between %? and %? is %n\n",
                points[i], points[j], d);
      }
    }
  }
  ```

  We can run this program in the debugger and set a breakpoint on the
  `distanceTo` method.

  {{<figure class="fullwide" src="breakDistanceTo.png">}}

  Once we hit the breakpoint, we step into the method and inspect both
  `this` and `other`:

  {{<figure class="fullwide" src="inspectVars.png">}}

  We can also perform arbitrary arithmetic with those values:

  {{<figure class="fullwide" src="math.png">}}

  We can even invoke the `.distanceTo()` method directly from the
  debugger. This isn't perfect and has some limitations, but most of
  the time those limitations can be worked around to get the
  information we need.

  {{<figure class="fullwide" src="callMethod.png">}}

  This is a huge improvement over previous releases, where none of the
  above was possible. These new features help make the Chapel
  debugging experience much more like debugging conventional languages
  like C or C++, making it much more useful to run Chapel programs in
  a debugger.

  These new debugging features are already enabling us to track down
  and fix bugs in Chapel code more quickly, and we are excited to hear
  feedback from users about how they are using these new features in
  their own debugging workflows.


  ### Improved Loop-Invariant Code Motion

  Like most compiled languages, Chapel relies on Loop-Invariant Code
  Motion (LICM) as an optimization to avoid executing code redundantly
  within loop bodies.

  {{<details summary="**(\"Hold up... What's Loop-Invariant Code Motion?**\")">}}

  As a trivial example of Loop-Invariant Code Motion, the following
  computation of `halfPi` does not need to be re-evaluated in each of
  the loop's `n` iterations since its value is independent of `i`:

  ```chapel
  forall i in 1..n {
    const halfPi = pi / 2;
    A[i] *= halfPi;
  }
  ```

  As a result, compilers can use LICM to rewrite this loop as follows,
  hoisting that computation out of the loop to avoid the redundant
  work:

  ```chapel
  const halfPi = pi / 2;
  forall i in 1..n {
    A[i] *= halfPi;
  }
  ```

  {{</details>}}

  When compiling Chapel programs, LICM is performed in both the Chapel
  compiler and the standard LLVM or C compiler that makes up its
  back-end.  It's a no-brainer to leverage the latter to avoid
  reinventing the wheel and to benefit from decades of C-level
  compiler investments.  The rationale for implementing the former is
  that there are cases where the Chapel compiler has access to
  semantic information that can benefit LICM, and which can be
  significantly obfuscated, or even lost, when lowering to the C-level
  code that we hand off to the back-end compiler.

  One such case concerns the metadata used for array accesses.  When
  it's known that the array will not be resized within the loop, such
  metadata accesses can typically be hoisted outside of loops to avoid
  referring to the same fields or computing the same subcomputations
  over and over again.  In particular, Chapel's multidimensional,
  sparse, and/or distributed arrays can involve a significant amount
  of metadata compared to the simpler C-style buffers, pointers, and
  offsets that back-end compilers are accustomed to.  Understanding
  the semantics of arrays permits Chapel to optimize such metadata
  accesses.

  In Chapel 2.8, we extended Chapel's existing LICM pass to hoist
  metadata computations for arrays that are declared `const`, knowing
  that they can't change size, shape, or indices.  This work was
  motivated in part by Thitrin Sastarasadhit's [transformers
  study]({{<relref "transformers-from-scratch-in-chapel-and-c++">}})
  that was published on this blog late last year.  Specifically, this
  transformation enables vectorization for key loop kernels that had
  previously been thwarted by these array metadata accesses.

  The following execution time plot, taken from [Chapel's performance
  tracking suite](https://chapel-lang.org/perf/), shows the impact of
  this optimization on one of the motivating kernels from Thitrin's
  article:

  {{<figure class="fullwide" src="LICM-kernel.png">}}

  Specifically, the motivating loop idiom improved by ~7.5% once the
  LICM improvement was added on February 17th, bringing it in-line
  with lower-level ways of writing the kernel that also enabled
  vectorization.  We also saw improvements to other longstanding,
  array-heavy benchmarks such as the following port of Bale Toposort:
  
  {{<figure class="fullwide" src="LICM-toposort.png">}}
  
  
  

  ### New `--system-launcher-flags` option

  Chapel 2.8 also adds a new flag to Chapel executables that utilize
  Slurm-based
  [launchers](https://chapel-lang.org/docs/2.8/usingchapel/launcher.html),
  named `--system-launcher-flags`.  This flag can be used to pass
  additional options to the underlying Slurm commands that get the
  Chapel program running, like `srun`.  This is particularly valuable
  when users need to access Slurm options that are not directly
  supported by Chapel.  In other words, this flag can be considered a
  fallback for accessing features that aren't covered by Chapel's
  standard [launcher flags and environment
  variables](https://chapel-lang.org/docs/2.8/usingchapel/launcher.html#common-slurm-settings).

  As an example, a user doing benchmarking who wants to override the
  default number of reserved specialized cores using Slurm's
  `--core-spec` or `-S` flag would be at a loss using standard Chapel
  options, since they do not support that override.  Prior to Chapel
  2.8, such users would need to either rely on a Slurm environment
  variable to make the request, or else abandon Chapel's launcher and
  write their own Slurm script or command to launch the program, which
  can be tricky to get right.

  However, as of Chapel 2.8, users can run their program with
  `--system-launcher-flags "-S 0"` to have Chapel pass `-S 0` to the
  underlying `srun` command that's invoked on their behalf, saving
  effort and the potential for errors, while also making the
  command-line more explicit.  We anticipate that future Chapel
  releases will extend this capability to support non-Slurm launchers,
  as desired.


  ### Mason Package Manager

  Chapel's package manager,
  [Mason](https://chapel-lang.org/docs/2.8/tools/mason/mason.html),
  has seen a lot of new feature support in recent releases. For
  version 2.8, we made a concerted effort to track down and fix many
  edge cases and bugs, and we are happy to report that Mason is now
  much more robust and reliable. This isn't the most exciting work,
  but it is important for the long-term health of the tool and
  project.

  One exciting new feature for Mason is the improved `mason doc`
  command. This effort involved several improvements to the underlying
  `chpldoc` tool, which is used to generate documentation for Chapel
  modules. The `mason doc` command now generates documentation
  specialized to a given project by default, while also giving users
  the tools to better customize the generated documentation.

  We are really excited to see Chapel users and developers starting to
  create and contribute more packages to Mason. We hope to see the
  Mason registry grow and become a vibrant ecosystem of Chapel
  packages that users can easily discover and use in their own
  projects.


  ### Improvements to the Dyno Compiler Front-End

  As you may have seen in [previous]({{< relref
  "announcing-chapel-2.7#improvements-to-the-dyno-compiler-front-end"
  >}}) [release]({{< relref
  "announcing-chapel-2.6#improvements-to-the-dyno-compiler-front-end"
  >}}) [announcements]({{< relref
  "announcing-chapel-2.5#improvements-to-the-dyno-compiler-front-end"
  >}}), _Dyno_ is the name of our project that is modernizing and
  improving the Chapel compiler. Dyno improves error messages, allows
  incremental type resolution, and enables the development of language
  tooling, [as described above]({{< relref
  "#chapel-language-server-and-linter" >}}).  Our team has been hard
  at work implementing many features of Chapel's type system in Dyno,
  which, among other things, enables tools like CLS to provide more
  accurate and helpful information to users.

  The other current focus within Dyno is taking the information that
  it has computed about the program and generating AST for the
  production compiler, essentially skipping over its historical type
  resolution and analysis phases. This capability is enabled using the
  `--dyno` command-line flag.  Current support is limited to a
  subset of Chapel's language features, but is growing all the time.

  A key milestone for Dyno in Chapel 2.8 is the ability to generate
  executable code for "Hello, world!" style programs. This is a
  significant milestone for Dyno, as it demonstrates the ability to
  compile many language features that the standard library relies
  upon.  It's also a step toward Dyno's goal of replacing the
  front-end of the production compiler.

  As an example, consider the following program, which makes use of
  the `fileWriter` type and its `.writeln()` method:

  {{< file_download fname="converter.chpl" lang="chapel" >}}

  The program above can be {{< sidenote "right" "compiled" >}}
  The `--no-checks` flag is used here to disable runtime checks that
  utilize language features not yet supported by Dyno's code generation.
  {{< /sidenote >}}
  with ``--dyno --no-checks`` to produce an executable that prints the
  following output:

  {{< file_download fname="converter.good" lang="text" >}}

  While a program like this may appear to be trivial, it relies on
  many language features behind the scenes for its
  implementation. Here are just some of the Chapel features that are
  being used by the `IO` module in this example:

    - generic variadic arguments
    - external interoperability
    - owned and shared classes
    - records, classes, and tuples
    - nested records (as used by the serialization framework)
    - reflection
    - locales

  Compiling such a program helps to provide a solid base for supporting
  more standard libraries and language features that build upon these
  basic building blocks.


  ### For More Information

  If you have questions about Chapel 2.8 or any of its new features,
  please reach out on Chapel's [Discord
  channel](https://discord.gg/xu2xg45yqH), [Discourse
  group](https://chapel.discourse.group/), or one of our other
  [community forums](https://chapel-lang.org/forums/).  We're always
  interested in hearing about how we can make the Chapel language,
  libraries, implementation, and tools more useful to you.

*/
