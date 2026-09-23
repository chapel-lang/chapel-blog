// Announcing Chapel 2.10!
// authors: ["Anna Rift", "Jade Abraham", "Brad Chamberlain"]
// summary: "Highlights from the September 2026 release of Chapel 2.10"
// tags: ["Language Features"]
// series: ["Release Announcements"]
// date: 2026-09-24
/*

  The Chapel developer community is pleased to announce the release of
  Chapel 2.10!  This fall's release focuses on wrapping up some loose
  threads from recent releases while also positioning Chapel testing
  to be in a good state as we transition from having fully funded
  dedicated staff members to entering more of a community open-source
  development mode.  As always, you can [download and
  install](https://chapel-lang.org/download/) the new release in a
  {{<sidenote "right" "variety of formats">}}Please note that some
  release formats may not yet be available at time of
  publication.{{</sidenote>}}, including Spack, Homebrew, various
  Linux package managers, Docker, and source tarballs.

  This article summarizes some of Chapel 2.10's highlights, including:

  * Continued improvements to Chapel's [union
    types](#union-type-improvements), bringing them to a complete and
    usable state.

  * Conversion of traditional Chapel testing from using HPE-internal
    processes and resources to testing using GitHub Actions for better
    access and visibility by community developers.

  * Improvements to thrown errors in terms of being able to inspect
    their stack traces.

  Other notable highlights of Chapel 2.10 that aren't covered in this
  article include:

  * The closing of many loopholes in which the Chapel compiler or its
    generated executables were relying on undefined behaviors in
    C/C++.

  * Ergonomic improvements and bug fixes when using the
    `DynamicLoading` module and dynamically loaded versions of the
    runtime.

  * Improvements to the inlays displayed by `chpl-language-server`
    (CLS)in VSCode and other editors.

  * The addition of missing operators and queries on `imag` and
    `complex` values.

  * The resolution of 7 user issues, including both that were opened
    over the summer since the release of Chapel 2.9.

  For a far more complete list of improvements in Chapel 2.10, see the
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/2.10/CHANGES.md)
  file.  And a big thanks to [everyone who
  contributed](https://github.com/chapel-lang/chapel/blob/release/2.10/CONTRIBUTORS.md)
  to Chapel 2.10!


  ### Union Type Improvements

  Chapel 2.10 continues the improvements to union types that we began
  in Chapel 2.9, bringing unions to a state where we consider them to
  be complete and productive.  As mentioned in the [2.9 release
  announcement]({{< relref "announcing-chapel-2.9/#union-type-improvements" >}}), this work was motivated by recent user comments and
  requests.

  #### Union Initializers

  One of the most practical, but least flashy, improvements to unions
  in Chapel 2.10 is vastly improved support for initializers.  In
  earlier versions of Chapel, unions only supported 0-argument
  initializers by default and user initializers were neither
  particularly full-featured nor safe.  Chapel 2.10 brings support for
  union initializers on par with records for both compiler- and
  user-generated initializers.

  As an example, consider the following union type declaration:

*/

  union u {
    var w: int;
    var x: int;
    var y: real;
    var z: string;
  }

/*

  Previously, the compiler would only generate a 0-argument
  initializer for such a union type, providing the ability to create
  `u` values in an inactive state.  As of Chapel 2.10, the compiler
  also generates a 1-argument initializer per field that can be used
  to initialize the corresponding field, making it active.  As an
  example, the compiler-generated initializers for `u` above would
  effectively look like this:

  ```chapel
  proc u.init() {
  }

  proc u.init(w: int) {
    this.w = w;
  }

  proc u.init(x: int) {
    this.x = x;
  }

  proc u.init(y: real) {
    this.y = y;
  }

  proc u.init(z: string) {
    this.z = z;
  }
  ```

  Given these compiler-generated initializers, users can create union
  values with any active field (or none), as follows:

*/

  var u0 = new u(),
      uw = new u(w=78),
      ux = new u(x=45),
      uy = new u(y=33.3),
      uz = new u(z="hi");

  writeln((u0, uw, ux, uy, uz));

/*

  In addition, as you'd expect, for field types that are unambiguous,
  a value may be passed in without using Chapel's argument-matching
  syntax:

*/

  var ureal = new u(33.3333),
      ustring = new u("hello");

  writeln((ureal, ustring));

/*

  User-defined initializers for unions have also been significantly
  improved in Chapel 2.10, primarily by resolving longstanding memory
  safety bugs and overzealous compiler optimizations from earlier
  versions of Chapel.  As with records, user-defined union
  initializers can now initialize and assign fields, invoke sibling
  initializers using `[this.]init(...);`, and signal object completion
  with `init this;`.  Union types also now correctly support
  `postinit()` calls.  As a result of these improvements, union value
  construction can now be considered full-featured in Chapel.


  #### Active Field Pattern Matching

  One of the most attractive features for unions in 2.10 is a new
  `union select` statement that supports taking actions on a union
  expression based on which field is currently active.  This new
  feature can be considered a baby step toward more general
  pattern-matching support that we'd like to explore adding to future
  versions of Chapel.

  As an example, consider the following union method, written to
  double (by some definition) a union's active field:

*/  

  proc ref u.double() {
    union select this {
      when w do w *= 2;
      when x do x *= 2;
      when y do y *= 2.0;
      when z do z += z;
      otherwise {
        const fieldID = this.getActiveIndex();
        if fieldID != -1 then
          halt("unexpected active field in 'u.double()': ", fieldID);
      }
    }
  }

/*

  Each `when` clause of a `union select` statement like the above
  checks to see whether the named field is active.  If it is, the
  field's name serves as a reference to the field for the scope of the
  clause.  This identifier serves as a `const ref` to the field for
  union expressions that are immutable and a `ref` for those that can
  be modified.

  Note that the `otherwise` clause may be matched by unions without an
  active field, such as default-initialized union values like `u0` in
  the code above.  In this `union select` example, the `otherwise
  clause was written defensively, to guard against the possibility
  that new fields are added to the union type later without adding
  support for them to this method.

  The following demonstrates calls to this method and the resulting
  effects on the union values:

*/

  u0.double();
  uw.double();
  ux.double();
  uy.double();
  uz.double();

  writeln((u0, uw, ux, uy, uz));

/*

  Chapel 2.10 also adds support for traditional equality-based
  `select` statements on union expressions, leveraging the support for
  equality between union values added in Chapel 2.9.

  As a result of all the improvements to unions in this release and
  2.9, we now consider unions to be feature-complete in Chapel 2.10.
  That said, we do not yet consider unions to be a stable language
  feature, so hope to receive feedback from users to hear how they
  work in your codes and what additional improvements or features
  might further improve productivity in your code bases.


  ### Call Stacks for Thrown Errors

  Chapel 2.10 has some nice quaility of life improvements for error
  handling.  Error classes now track the call stack leading to the
  error, permitting a thrown `Error` object to report rich diagnostic
  information.  Consider the following example of using a `Parser`
  helper module to parse a file:

  {{< file_download_min fname="Parser.chpl" lang="chapel" >}}

  {{< file_download fname="uncaught-error.chpl" lang="chapel" >}}

  This call to `p.next()` will throw a `ParseError` if the input
  file's line format is invalid, as on line 3 or 7 of the following
  input file:

  {{< file_download fname="input.txt" lang="text" >}}

  Because this error is not caught by the code, it causes the program
  to halt.  Prior to Chapel 2.10, the resulting error message would
  say where the error was thrown and where it was uncaught:

  ```console
  (name = Alfred, id = 10)
  ====
  (name = Bobby, id = 11)
  ====
  uncaught ParseError: Invalid line format: Candice12
    Parser.chpl:36: thrown here
    uncaught-error.chpl:5: uncaught here
  ```

  However, all information about the call stack between those
  endpoints was lost.

  As of Chapel 2.10, uncaught errors now print a stack trace by
  default, showing the calls that led to the error:

  {{< console fname="uncaught-error.good" >}}

  This allows users to trace through the complete sequence of calls
  that led to the error.


  Furthermore, prior to Chapel 2.10, if a user tried to catch the
  error and print a custom error message, they lost access to the line
  information that Chapel printed by default.  Chapel 2.10 addresses
  this by adding the ability to manually inspect the stack trace. As a
  result, code can catch errors to handle them gracefully, without
  losing access to call stack information.

  This is done using a new `.stacktrace()` iterator supported on
  `Error` classes that yields a sequence of `(file, linenum)` tuples
  representing the call stack leading up to the error, starting from
  the point where the error was thrown. The following example rewrites
  the previous version to catch the error, print a custom error message
  including the stack trace, and then continuing to read the remaining
  lines rather than halting:

  {{< file_download fname="caught-error.chpl" lang="chapel" >}}

  Here is the output generated when running on the `input.txt` file
  above:

  {{< console fname="caught-error.good" >}}

  This new feature gives users better information when writing and
  debugging Chapel programs.


  ### Expanded GitHub Actions Testing

  For most of the Chapel project's history, its build, test, and
  release processes have primarily been run on internal company
  resources, first at Cray Inc. and then more recently at HPE.  Since
  Chapel 2.10 will be the last release [in the foreseeable future]({{<
  relref "cff" >}}) where most developers work on Chapel as their
  full-time role at HPE, we wanted to reduce our reliance on these
  corporate resources going forward.  Beyond supporting project
  continuity, moving these build processes and configurations outside
  the firewall also has the benefit of opening them up to inspection
  by, or contributions from, the broader open-source community.  This
  effectively gives Chapel community developers access to testing
  results that they used to have to rely on HPE developers to provide
  manually.

  For these reasons, in the lead-up to Chapel 2.10 we've undertaken an
  effort to move as much of our CI as possible into GitHub Actions (GA),
  running against the public
  [chapel-lang/chapel](https://github.com/chapel-lang/chapel)
  repository.  Configuration files live in the
  [`.github/workflows`](https://github.com/chapel-lang/chapel/tree/main/.github/workflows)
  folder, and are tracked in git like any other file in the
  project. We've long had some basic, quick checks in GA, but it is
  now responsible for more of our test coverage including
  longer-running processes. These include, but are not limited to:

  * Parallel runs of the full test suite on a few core configurations
  * Docker image and Linux package builds
  * Documentation builds and pushes
  * Several linting and formatting checks
  * Tarball builds and testing

  Some of these checks run on each commit pushed to a PR ('Core'),
  some when a PR is merged ('Extended'), and some nightly on the main
  development branch ('Nightly'). The idea is to have the
  shortest-running checks in the fastest feedback loop to catch many
  issues as quickly as possible, then longer-running checks providing
  more coverage running less frequently to avoid exhausting
  resources. The 'Extended' checks run in the merge queue, a GitHub
  feature that we've recently enabled which causes merged PRs to be
  held in a queue and tested before automatically proceeding with the
  merge.  In the case of a failure, such PRs are kicked back to the
  user.  'Nightly' checks report their results to a new, public
  [Nightly
  Testing](https://chapel.discourse.group/t/about-the-nightly-testing-category/51764)
  category in Chapel's Discourse community, where failures can be
  discussed and addressed by developers.

  These changes are very new, and shift a lot of work previously done
  in our internal daily "triage" of the previous night's testing to an
  earlier stage of the development process. They are intended to
  improve developer productivity and the long-term maintainability of
  the project, but may be an impediment in some cases as we work out
  the kinks. Anyone with commit access to the repo is able to override
  checks, so false positive failures won't prevent merging, and users
  are welcome to file issues against the CI (as well as PRs against
  workflow configurations). For more information, see the new [GitHub
  Actions](https://chapel-lang.org/docs/2.10/developer/bestPractices/ContributorInfo.html#get-github-actions-tests-passing)
  section of the Contributor Info documentation.


  ### For More Information

  If you have questions about Chapel 2.10 or any of its new features,
  please reach out on Chapel's [Slack
  workspace](https://join.slack.com/t/chapelnetwork/shared_invite/zt-3p459bjlh-0TQRloaBPqkZUe_dWz~C~Q),
  [Discourse group](https://chapel.discourse.group/), [Discord
  channel](https://discord.gg/xu2xg45yqH), or one of our other
  [community forums](https://chapel-lang.org/forums/).  We're always
  interested in hearing more about how we can make the Chapel
  language, libraries, implementation, and tools more useful to you.

*/
