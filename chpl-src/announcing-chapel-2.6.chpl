// Announcing Chapel 2.6!
// authors: ["David Longnecker", "Jade Abraham", "Lydia Duncan", "Daniel Fedorin", "Ben Harshbarger", "Brad Chamberlain"]
// summary: "Highlights from the September 2025 release of Chapel 2.6"
// tags: ["Release Announcements"]
// date: 2025-09-18
/*

  The Chapel community is pleased to announce the release of Chapel
  2.6!  As usual, you can [download and
  install](https://chapel-lang.org/download/) this new version in a
  {{<sidenote "right" "variety of formats">}}Note that some formats
  may not be immediately available on the day of the
  release...{{</sidenote>}}, including Spack, Docker, Homebrew,
  various Linux package managers, and good-old source tarballs.

  In this article, we'll introduce some of the highlights of Chapel
  2.6, including:

  * Chapel's new module for [dynamically loading
    libraries](#dynamic-loading-support) and calling into them

  * ...

  * Improvements to the capabilities of the [Dyno
    front-end](#improvements-to-the-dyno-compiler-front-end)

  In addition to the above features, which are covered in more detail
  in the sections below, other highlights of Chapel 2.6 include:

  * 

  For a much more complete list of changes in Chapel 2.6, see the
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/2.6/CHANGES.md)
  file.  And huge thanks to [everyone who
  contributed](https://github.com/chapel-lang/chapel/blob/release/2.6/CONTRIBUTORS.md)
  to version 2.6!

  ### Dynamic Loading Support

  This release of Chapel offers improved support for calling into
  dynamically loaded libraries.  This feature was introduced in a
  prototypical form for the 2.5 release, but in 2.6 it is now
  supported by all compiler back-ends and has improved stability.

  To use this feature, you must first have a _shared library_ (using
  Linux terminology) that you wish to dynamically load.  As a simple
  example, we'll compile and call into this simple library:

  {{<file_download fname="MyAdd.c" lang="C">}}

  The compiler invocation to create a dynamic library should look
  something like the following, where details may vary depending on
  your C compiler and platform:


  ```console
   $ clang -shared -fPIC -o libMyAdd.so MyAdd.c
  ```


  Once your library is compiled, you can write a program to load it
  and call `myAdd()` with just a few lines of Chapel code:

*/

 // UseMyAdd.chpl
 use DynamicLoading;

 const lib = binary.load('./libMyAdd.so'),
       add = lib.retrieve('myAdd', proc(x: int, y: int): int);

 const n = add(2, 2);
 writeln(n);

/*

  Note that although `bin.retrieve()` was only called on `Locales[0]`,
  the retrieved procedure stored in `add` can be invoked on any
  locale:

*/

on Locales.last {
  const n = add(here.id, here.id);
  writeln(n);
}

/*

  In order to use dynamic loading in Chapel at present, the
  `useProcedurePointers` `config param` must be set to true during
  Chapel compilation. This requirement will be relaxed in future
  releases.  For example, to compile this example and run it on four
  locales, you could use:

  ```console
   $ chpl -suseProcedurePointers=true UseMyAdd.chpl
   $ ./UseMyAdd -nl 4
   4
   6
  ```

  In addition to supporting traditional shared libraries like this
  sample C library, this feature also supports loading and calling
  into dynamic Chapel libraries whose exported routines are pure and
  C-like (e.g., ones that don't rely on Chapel's runtime or modules).
  In future releases, we plan to expand this support to support
  arbitrary Chapel code.


  ### Debugging Improvements

  Debugging Chapel programs gets even better in version 2.6 with
  better debug information and new pretty-printers.  Historically,
  debugging Chapel programs has meant interacting with the generated C
  code.  This meant that when inspecting Chapel variables, you would
  see the internal C representation of those data structures.  In this
  release, we added pretty-printers for LLDB that make it possible to
  view Chapel data structures using formats that are much more
  intuitive and user-oriented.  This improvement can be seen through a
  sample debugging session involving arrays.

  In the following session, we'll debug the following simple Chapel
  program:

  {{<file_download fname="example.chpl" lang="Chapel">}}

  We have used the `Debugger.breakpoint` {{<sidenote "right"
  "pseudo-statement">}}Actually, a parentheses-less
  procedure...{{</sidenote>}} to automatically stop execution at the
  place of interest in our program when running within a debugger.
  Upon hitting it, we then print out the contents of `myArr`:

  {{< figure class="fullwide" src="debug-old.png" >}}

  What we see is a bunch of internal C pointers that are used to
  implement Chapel arrays.  This isn't very helpful to the typical
  user, since it looks nothing like the logical array they'd expect.

  Now let's look at the exact same debugging session using the new
  pretty-printers added in Chapel 2.6:

  {{< figure class="fullwide" src="debug.png" >}}

  Now we see the contents of the array printed in a much more familiar
  and useful way, and the implementation details we don't care about
  {{<sidenote "right" " are hidden">}}If these details are important
  to you, you can still see them by printing the raw data structure
  using `v -R`.{{</sidenote>}}. This is just one example of the new
  pretty-printers, which cover a wide variety of built-in Chapel
  types, including strings, tuples, ranges, and domains. These new
  pretty-printers are available by default as long as you are using
  LLDB with Python support enabled.

  We also made some great improvements to the debug information that
  the Chapel compiler generates. The best example of this is with
  enum's. The debugger now has enough information to print out the
  names of the enum values instead of the underlying integer
  value. This makes it much easier to understand what is going on in
  your program. These improvements also lay the groundwork for
  additional improvements in the future.

  #### Prototype Parallel Debugger

  The Chapel 2.6 release also includes a new tool,
  `chpl-parallel-dbg`. This tool enables vastly improved debugging of
  multilocale Chapel programs, which has been a longstanding
  challenge. This tool works by launching a debugger on each locale of
  a Chapel program, and then connecting them all together with a
  single interface.

  The following session demonstrates that we are able to debug a
  multilocale Chapel program running on two locales, stepping through
  breakpoints on the distinct locales.

  {{< figure class="fullwide" src="parallel-dbg.png" >}}


  This new tool is still a work in progress, but it's already a huge
  step forward for debugging multilocale Chapel programs.  To learn
  more about it or try it yourself, see [its
  documentation](https://chapel-lang.org/docs/2.6/usingchapel/debugging/multilocale.html#chpl-parallel-dbg).
  We are excited to continue improving this tool in future releases.


  ### Testing Improvements for Mason and VSCode

  This release also includes many significant improvements to `mason`,
  [Chapel's package
  manager](https://chapel-lang.org/docs/2.6/tools/mason/mason.html),
  primarily focused on improving the developer experience when
  testing.  We fixed many bugs with mason itself and added some new
  testing features.  For example, suppose we have a simple program
  defining some unit tests:

  {{<file_download fname="myTest.chpl" lang="Chapel">}}


  This can be run, standalone, using:

  ```console
   $ chpl myTest.chpl
   $ ./myTest
  ```

  However, using `mason` we can just run:

  ```console
   $ mason test myTest.chpl
  ```

  and it will handle compilation and execution, while also generating
  a nice report for us:

  ```text
  
  ----------------------------------------------------------------------
  Ran 2 tests in 18.6117 seconds
  
  OK (passed = 2 )
  ```


  Chapel 2.6 also adds the ability to selectively run tests by name.
  For example, this command:

  ```console
   $ mason test myTest.chpl --filter myTest1
  ```

  will only run the `myTest1` test.  This is particularly useful when
  you are working on a specific test and don't want to run the entire
  suite.

  We also integrated testing into VSCode, so that you can run (and in
  the future, debug) tests directly from the editor!

  {{< figure class="fullwide" src="mason-test.png" >}}

  This creates a much smoother workflow for developing and testing
  Chapel code from the comfort of a GUI.


  ### Documentation Improvements

  Each Chapel release typically includes a handful of documentation
  improvements, usually motivated by the features being added or
  improved during that release cycle.  This release cycle saw a larger
  than normal set of documentation improvements, due to _documentation
  week_.  This was a dedicated week focused on improving documentation
  and documentation-adjacent aspects of the project.  We frequently
  find it healthy to dedicate a week shortly after each release to
  focus on some housekeeping task.  Instead of juggling these
  important, ongoing efforts with other priorities, it allows us to
  make a rapid progress in a short period of time, and also feels like
  a nice break from normal work.  Past dedicated weeks have focused
  specifically on cleaning up nightly testing or resolving user
  issues, and for this release it made sense to focus on
  documentation.

  During documentation week, we resolved and closed 23 outstanding
  issues.  We fixed bugs with our `chpldoc` documentation tool and
  added the ability to search our online documentation for compiler
  flags (like [this
  search](https://chapel-lang.org/docs/2.6/search.html?q=--fast&check_keywords=yes&area=default)
  for `--fast`).  As part of refactoring our [multilocale
  documentation](https://chapel-lang.org/docs/2.6/usingchapel/multilocale.html),
  we added or extended pages on using the [Elastic Fabric Adapter
  (EFA)](https://chapel-lang.org/docs/2.6/platforms/networks/efa.html)
  network interface for
  [AWS](https://chapel-lang.org/docs/2.6/platforms/aws.html#readme-aws),
  [Ethernet
  clusters](https://chapel-lang.org/docs/2.6/platforms/networks/ethernet.html),
  and [GASNet's SMP
  conduit](https://chapel-lang.org/docs/2.6/platforms/comm-layers/gasnet.html#readme-gasnet-smp)
  for running multiple locales on shared memory.  Additionally, this
  release saw the introduction of documentation on [sanitizer
  tools](https://chapel-lang.org/docs/2.6/usingchapel/debugging/sanitizers.html),
  and general improvements to our [debugging
  documentation](https://chapel-lang.org/docs/2.6/usingchapel/debugging.html).

  We also made extensive progress in updating code examples in
  documentation to support nightly testing.  Our enthusiasm for this
  effort carried over into subsequent weeks, such that for version
  2.6, we ultimately added testing for examples in 45 libraries and 9
  technotes!  As a result, we were able to notice and fix many
  examples that had gotten out-of-date due to improvements to the
  language.

  As a result of all these efforts, Chapel's online documentation is
  now more searchable, more accurate, and more robust to future
  changes, and `chpldoc` itself is better than ever!


  ### Dyno Improvements


  ### For More Information

  If you have questions about Chapel 2.6 or any of its new features,
  please reach out on Chapel's [Discord
  channel](https://discord.gg/xu2xg45yqH), [Discourse
  group](https://chapel.discourse.group/), or one of our other
  [community forums](https://chapel-lang.org/community/).  In
  addition, we're always interested in hearing about how we can make
  the Chapel language, libraries, implementation, and tools more
  useful to you.

*/
