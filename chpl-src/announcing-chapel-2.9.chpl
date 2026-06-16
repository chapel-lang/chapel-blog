// Announcing Chapel 2.9!
// authors: ["David Longnecker", "Daniel Fedorin", "Brad Chamberlain"]
// summary: "Highlights from the June 2026 release of Chapel 2.9"
// tags: []
// series: ["Release Announcements"]
// date: 2026-06-18
/*

  The Chapel developer community is happy to announce the release of
  Chapel 2.9!  As with other recent versions,


  release was improvements to Chapel's tools ecosystem.  As always,
  you can [download and install](https://chapel-lang.org/download/)
  this new version in a {{<sidenote "right" "variety of formats">}}Please
  note that some formats may not yet be available at time of
  publication...{{</sidenote>}}, including Spack, Homebrew, various
  Linux package managers, Docker, and source tarballs.

  This article summarizes several of Chapel 2.9's highlights,
  including:

  * 

  * 

  * 

  * 

  * 

  * 

  Other notable highlights of Chapel 2.9 that aren't covered by this
  article include:

TODO: Mason above or below?

  * Ergonomic improvements to other tools, such as the
    [`chplcheck`](https://chapel-lang.org/docs/2.9/tools/chplcheck/chplcheck.html)
    linter,
    [`chpldoc`](https://chapel-lang.org/docs/2.9/tools/chpldoc/chpldoc.html)
    documentation generator,
    [`chapel-py`](https://chapel-lang.org/docs/2.9/tools/chapel-py/chapel-py.html)
    compiler library, and
    [`c2chapel`](https://chapel-lang.org/docs/2.9/tools/c2chapel/c2chapel.html)
    tool for interoperating with C

  * A parallel implementation of [`scan`
    expressions](https://chapel-lang.org/docs/2.9/language/spec/data-parallelism.html#scan-expressions)
    for array-like expressions like `myArray: int`, `myArray +
    myArray2`, or `[i in 1..n] i`

  * Support for LLVM 22 as the default compiler back-end, LLDB 22 for
    debugging, and CUDA 13 for NVIDIA GPUs

  * Newly released Red Hat Enterprise Linux RPMs [on HPE Cray EX
    systems](https://chapel-lang.org/download/#hpe)

  For a far more complete list of improvements in Chapel 2.9, see its
  entries in
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/2.9/CHANGES.md).
  And a big thanks to [everyone who
  contributed](https://github.com/chapel-lang/chapel/blob/release/2.9/CONTRIBUTORS.md)
  to Chapel 2.9!


  ### Dynamic Loading of Parallel Chapel Libraries

  Chapel 2.5 and 2.6 [introduced a new `DynamicLoading`
  module](https://chapel-lang.org/blog/posts/announcing-chapel-2.6/#dynamic-loading-support)
  that supports loading and calling into dynamic libraries from
  Chapel.  Up until now, this feature could only handle libraries that
  were written in C or that used C-like features.  Notably,
  dynamically loaded Chapel libraries could only use simple C-like
  features rather than any of Chapel's productive features for
  parallelism or distributed memory programming.

  Chapel 2.9 removes this limitation by adding prototypical support
  for dynamically loading Chapel libraries that use parallelism and/or
  multiple locales.  This capability is enabled in part by a new
  compiler flag, `--no-builtin-runtime`.  It permits distinct binaries
  to share a single, dynamically loaded copy of the Chapel runtime,
  which implements communication, parallelism, and memory management
  for Chapel programs.  Previously, each Chapel binary would bundle
  its own copy of the runtime, which led to resource contention and a
  lack of coordination between programs.

  As a simple example, the following Chapel program exports a
  procedure named ``test1`` that uses a task-parallel `coforall` loop
  with an `on`-clause to spin up a task per locale:

  {{< file_download fname="Library.chpl" lang="chapel" >}}

  By compiling the program with the following command-line, we tell
  the `chpl` compiler to create a dynamic library from it:

  ```console
  $ chpl Library.chpl --library --dynamic --no-builtin-runtime
  ```

  {{<details summary="**(Trying this at home?  Be sure to read this first.**\)">}}

  At present, distributed Chapel libraries like the one shown here
  aren't supported for ``CHPL_COMM=ofi``, only ``gasnet`` and
  ``none``.  This feature also requires the runtime and programs to be
  built using position-independent code (PIC), so be sure you've built
  your runtime with ``CHPL_LIB_PIC=pic`` set, and to also use it when
  compiling your programs.  Examples like the one shown here won't
  work correctly otherwise.

  {{</details>}}

  Having created the library, we can then write a separate program
  that loads it and calls `test1`:

  {{< file_download fname="Executable.chpl" lang="chapel" >}}

  We then compile the program, again saying not to bundle the runtime:

  ```console
  $ chpl Executable.chpl --no-builtin-runtime
  ```

  When executed on multiple locales (e.g., ``-nl 4``), the main
  program starts by loading a shared copy of the runtime when
  execution begins.  Next, it loads the user's dynamic library, which
  shares the same copy of the runtime.  It then retrieves the `test1`
  procedure from the library and calls into it, causing our greeting
  message to be printed once per locale in an arbitrary order:

  ```
  Hello from locale 1
  Hello from locale 0
  Hello from locale 3
  Hello from locale 2
  ```

  This feature is still in its early days, and you may encounter bugs
  that break the loaded program or prevent you from running it.  If
  you do, please consider filing any bugs you encounter as [issues on
  the Chapel GitHub
  repo](https://github.com/chapel-lang/chapel/issues/new/choose).  In
  the meantime, we will be working to address known limitations,
  harden the implementation, and eventually port it to support OFI
  communication.


  ### Chapel Language Server and Linter

  [Since our 2.0 release]({{< relref
  "announcing-chapel-2.0#rich-tooling-support" >}}), Chapel has
  provided two key tools that enable users to write code more
  productively: the [Chapel Language Server
  (CLS)](https://chapel-lang.org/docs/2.8/tools/chpl-language-server/chpl-language-server.html)
  and the [`chplcheck`
  linter](https://chapel-lang.org/docs/2.8/tools/chplcheck/chplcheck.html).
  This 2.8 release includes several improvements to both of these
  tools.

  #### Editing, Resolution, and Inlays

  When it comes to the language server, the biggest improvements have once
  again been made to the experimental
  [resolution-based features](https://chapel-lang.org/docs/tools/chpl-language-server/chpl-language-server.html#experimental-resolver-features).
  The first among these improvements has been made by exposing more
  compiler information to the language server, specifically related to error
  messages. The language server can now better interpret several common error
  messages, and to display them to the user in a more helpful way. For example,
  take the following file:

  {{< file_download_min fname="bad-calls.chpl" lang="chapel" >}}

  Prior to Chapel 2.9, the error message would highlight the entire problematic
  expression, often spanning the entire line. Now, the exact argument that causes a function
  call to fail to resolve is highlighted. Similarly, in the `use IO` statement,
  the problematic fragment (attempting to rename a variable in an `except` clause)
  is highlighted specifically.

  {{< foldtable >}}
  | Before | After |
  |--------|------|
  |{{< figure src="error-info-before.png" alt="Error message before; entire lines of code are highlighted">}}|{{< figure src="error-info-after.png" alt="Error message before; highlighted info is more precise">}}|

  In Chapel 2.9, the CLS has also seen improvements to its ability to collect
  generic function instantiations across multiple files in a project. In
  the following example, the a generic function defined in module `A` shows
  instantiations stemming from generic calls in a module `B`:

  {{< figure class="fullwide" src="across-files.png" caption="Instantiations (on the left) shown from calls in a different module (on the right)" alt="Instantiations (on the left) shown from calls in a different module (on the right)">}}

  Another long-awaited resolution-based feature, and the last one we will call
  out in this release announcement, is the ability to infer and display return
  types for functions. In the following program, the CLS is shown inferring
  the return type of a concrete function (`foo`), a common return type for
  a generic function (`bar`), and a per-instantiation return type for
  another generic function (`baz`):

  {{< file_download_min fname="return.chpl" lang="chapel" >}}

  {{< figure src="return-type-inlays.png" caption="CLS inferring return types for concrete and generic functions" alt="return-type-inlays.png">}}


  ### For More Information

  If you have questions about Chapel 2.9 or any of its new features,
  please reach out on Chapel's [Slack
  workspace](https://join.slack.com/t/chapelnetwork/shared_invite/zt-3p459bjlh-0TQRloaBPqkZUe_dWz~C~Q),
  [Discord channel](https://discord.gg/xu2xg45yqH), [Discourse
  group](https://chapel.discourse.group/), or one of our other
  [community forums](https://chapel-lang.org/forums/).  We're always
  interested in hearing more about how we can make the Chapel
  language, libraries, implementation, and tools more useful to you.

*/



short
=====
* RHEL EX RPMs
* LLVM/LLDB 22
* parallel scans
* tools improvements

long
====

* Dynamic Loading
* Daniel CLS
* Mason
  - pkg manager
* unions
