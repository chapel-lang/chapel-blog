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

  * Significant ergonomic improvements to Mason, Chapel's package
    manager, as well as a new [web-based package
    browser](https://chapel-lang.org/packages/) (use it to find newly
    released packages since Chapel 2.8: `Base64`, `Crypto`, `CVL`
    (Chpl Vector Library), `Dyno`, `Log`, `Parquet`, `Pathlib`,
    `SciChap`, `TemplateStrings`, and `TerminalColors`).

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
    for array-like expressions such as `myArray: int`, `sin(myArray)`,
    or `[i in 1..n] i`

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
  compiling your programs (or use `--lib-pic=pic`).  Examples like the
  one shown here won't work correctly otherwise.

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

  ```terminal
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


  ### Editing Improvements due to CLS
  [Since our 2.0 release]({{< relref
  "announcing-chapel-2.0#rich-tooling-support" >}}), Chapel has
  provided two key tools that enable users to write code more
  productively: the [Chapel Language Server
  (CLS)](https://chapel-lang.org/docs/2.9/tools/chpl-language-server/chpl-language-server.html)
  and the [`chplcheck`](https://chapel-lang.org/docs/2.9/tools/chplcheck/chplcheck.html) linter.
  This 2.9 release includes several improvements to both these
  tools, where we'll focus on CLS here.
  As in Chapel 2.8, the biggest improvements to the language server
  have been made in the experimental [resolution-based
  features](https://chapel-lang.org/docs/tools/chpl-language-server/chpl-language-server.html#experimental-resolver-features).

  #### Error Improvements

  The first case we'll cover improves the quality of compiler errors
  within the editor.  This is the result of exposing more information
  about error messages to the language server, permitting it to better
  interpret several common error messages and display them to the
  user in a more helpful way. For example, consider the following
  file, in which the user has made several mistakes, as noted in
  the comments:

  {{< file_download_min fname="bad-calls.chpl" lang="chapel" >}}

  Prior to Chapel 2.9, the editor would highlight the entire
  problematic context for such errors, often spanning the entire line:

  {{< figure src="error-info-before.png" alt="Error message before; entire lines of code are highlighted">}}

  Now, the error is highlighted much more precisely.  In the `use`
  statement, the problematic fragment that attempted to rename an
  identifier in an `except` clause is specifically highlighted.  And
  so is the exact argument that caused a call to fail to resolve:

  {{< figure src="error-info-after.png" alt="Error message before; highlighted info is more precise">}}

  #### Generic Instantiation Inlays

  In Chapel 2.9, the CLS has also seen improvements to its ability to
  collect generic instantiations across multiple files in a
  project. In the following example, the generic procedure `foo()`
  defined in module `A` displays instantiations stemming from calls
  made in a separate file and module `B`:

  {{< file_download_min fname="A.chpl" lang="chapel" >}}
  {{< file_download_min fname="B.chpl" lang="chapel" >}}

  {{< figure class="fullwide" src="across-files.png" alt="Instantiations (on the left) shown from calls in a different module (on the right)">}}

  In addition, the CLS now displays inlays for declarations within
  generic procedures whose types are independent of the instantiating
  arguments.  For example, if `foo()` above contained the declaration
  `var message = "hi";`, it would be a string regardless of the values
  of generic arguments `t` and `p`, so would be rendered as such in
  the editor.

  #### Inferred Return/Yield Types

  Another long-awaited editor improvement, and the last one we'll call
  out in this release announcement, is the ability to infer and
  display return types for procedures (and yield types for
  iterators). In the following program, the CLS is shown inferring the
  return type of a concrete function (`foo`), an
  instantiation-independent return type for a generic function
  (`bar`), and an instantiation-specific return type for another
  generic function (`baz`):

  {{< file_download_min fname="return.chpl" lang="chapel" >}}

  {{< figure src="return-type-inlays.png" caption="CLS inferring return types for concrete and generic functions" alt="return-type-inlays.png">}}


  ### Union Type Improvements

  Though Chapel has long supported union types, they have
  unfortunately been stuck in a half-baked state for years.  Motivated
  by a recent user request, they took a big leap forward in
  Chapel 2.8, perhaps reaching a 4/5-baked state. ☺


  #### Union Basics

  Introducing some of the features added in this release, let's start
  with a basic union declaration that declares three fields, `x`, `y`,
  and `z`, where the former two are integers and the third is a `real`
  floating point value.

*/

  union u {
    var x: int;
    var y: int;
    var z: real;
  }

/*

  Chapel's unions carry the concept of an _active field_, such that
  when a value is stored in a given field, only that field may be read
  until another field is written.  For example, if we store into `y`,
  we can read from `y`, but not from `x` or `z`:

*/

  config const testErrors = false;

  var myU, myU2: u;
  myU.y = 45;
  writeln(myU.y);    // prints '45'
  if testErrors {
    writeln(myU.x);  // error: halt reached - illegal union access: attempted
                     // to access field 'x' but 'y' is currently active
    writeln(myU.z);  // error: halt reached - illegal union access: attempted
                     // to access field 'z' but 'y' is currently active
  }

/*

  Similarly, if the union is written out, the active field is
  displayed.  For example,

*/

  writeln("myU is: ", myU);

/*

  produces:

  ```terminal
  myU is: (y = 45)
  ```  

  And that's about where Chapel's support for unions has been stuck
  for many years.  It was a classic chicken-and-egg problem in which
  Chapel users weren't using unions because they weren't very capable,
  but they also weren't being improved because users {{< sidenote
  "right" "weren't using them" >}}In addition, we were probably
  letting the quest for the perfect design be the enemy of one that
  would've been good enough.{{</sidenote>}}


  #### Active Field Queries

  In Chapel 2.9, we broke this cycle where a key element was
  introducing the ability to query which field is active in a given
  union, using 0-based numbering of its fields.  For example, if we
  were to write:

*/

  writeln("The active field is #", myU.getActiveIndex());

/*

  we'd see:

  ```terminal
  The active field is #1
  ```

  From there, safe code can be written to choose between the active
  fields using conditionals, or patterns like:

*/

  select myU.getActiveIndex() {
    when 0 do writeln("x is active: ", myU.x);
    when 1 do writeln("y is active: ", myU.y);
    when 2 do writeln("z is active: ", myU.z);
    otherwise do halt("got an unexpected index");
  }

/*

  Chapel 2.9 also introduces a stylized way of performing a `select`
  directly on a `union` expression to determine its active field.  You
  can read about this feature in the [language
  specification](https://chapel-lang.org/docs/2.9/language/spec/unions.html#union-pattern-matching),
  but please note that the current syntax is subject to change and an
  active area of discussion at the time of the release.

  #### Active Field Visitors

  Another way of identifying active fields is to use a visitor pattern
  in which a procedure is supplied for each field, taking that field's
  name and type as arguments,  For example, the following call:

*/

  myU.visit(proc(x: int)  { writeln("x is ", x); },
            proc(y: int)  { writeln("y is ", y); },
            proc(z: real) { writeln("z is ", z); });

/*

  results in:

  ```terminal
   y is 45
   ```

  Note that while anonymous procedures are used above, traditional
  declared procedures can be used as well.  For example:

*/

  myU.visit(foo, bar, baz);

  proc foo(x: int) { writeln("In foo, x is: ", x); }
  proc bar(y: int) { writeln("In bar, y is: ", y); }
  proc baz(z: real) { writeln("In baz, z is: ", z); }

/*

  would generate:

  ```terminal
  In bar, y is: 45
  ```


   #### Comparison Operators

   In addition, Chapel now provides default comparison operators
   between unions of the same type, which check that the same field is
   active in both values and that the stored values are equal.  As an
   example:

*/

  myU2.y = 78;
  writeln(myU == myU2);  // false, since the active fields aren't equal
  myU2.y = 45;
  writeln(myU == myU2);  // true, since the same fields are active and equal
  myU2.x = 45;
  writeln(myU == myU2);  // false, since different fields are active
  writeln(myU != myU2);  // true, since different fields are active

/*

  produces:

  ```terminal
  false
  true
  false
  true
  ```

  As with default comparison operators on records, these defaults can
  be overridden by a user.  For example, the following overloads
  consider two of our union values to be equal if each has one of `x`
  or `y` set and the values match:

*/

  { // open a new scope to limit these overloads to the contained code
    operator u.==(a: u, b: u) {
      const aIdx = a.getActiveIndex(),
            bIdx = b.getActiveIndex();

      if aIdx == 0 && bIdx == 1 {
        return a.x == b.y;
      } else if aIdx == 1 && bIdx == 0 {
        return a.y == b.x;
      }
      return false;
    }

    operator u.!=(a: u, b: u) {
      return !(a == b);
    }

    writeln("Using my overload, ", myU, " == ", myU2, " => ", myU == myU2);
    writeln("Using my overload, ", myU, " != ", myU2, " => ", myU != myU2);
  }

/*

  To read more about unions in Chapel, please see their [chapter in
  the language
  specification](https://chapel-lang.org/docs/2.9/language/spec/unions.html),
  and be sure to share your feedback with us!


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
