// Announcing Chapel 2.1!
// authors: ["Brad Chamberlain"]
// summary: "A summary of highlights from the June 2024 release of Chapel 2.1"
// tags: ["Release Announcements"]
// date: 2024-06-27
// weight: 90

/*

  The Chapel developer community is pleased to announce the release of
  version 2.1 of Chapel!  This release builds on March's [milestone
  2.0 release]({{< relref "announcing-chapel-2.0/index.md" >}}) by
  significantly expanding Chapel's installation options and improving
  support for AWS. It also adds powerful new features like remote
  variable declarations and language support for GPU reductions.  In
  this post, I'll provide an overview of these advances and
  summarize a few other highlights.

  ### Installation/Portability Improvements

  A big theme of the Chapel project since completing the 2.0 release
  has been thinking expansively about {{< sidenote "right"
  "nurturing and growing the Chapel community" >}}For those
  interested, I introduced this theme and ran through some of our
  recent efforts here in my "State of the Chapel Project" talk at 
  [ChapelCon '24]({{< relref "chapelcon24" >}}) whose
  [slides](https://chapel-lang.org/chapelcon/2024/chamberlain-sop.pdf) and
  [video](https://www.youtube.com/watch?v=nfxJ-tOsgrY&amp;list=PLuqM5RJ2KYFi2yV4sFLc6QeRYpS35UeKl&amp;index=2&amp;pp=iAQB)
  are available online. {{< /sidenote >}}.  One effort we've kicked
  off as a result of this seeks to improve and diversify the options
  for installing Chapel on a given system.

  Specifically, where we have traditionally supported Chapel system
  installations through source builds, Homebrew, Docker, and the
  HPE/Cray module systems, in Chapel 2.1, we've added new installation
  options and improved some of the existing ones.  Here are some of
  the highlights:

  #### Spack

  The first---and to me, most exciting---new installation option is a
  full-fledged [Chapel Spack
  package](https://packages.spack.io/package.html?name=chapel).  If
  you're not familiar with
  [Spack](https://github.com/spack/spack#readme), think of it as the
  package manager of choice for HPC systems---though it works great on
  laptops and workstations as well!  Spack's development was led by
  HPC experts at LLNL, and was designed with a supercomputer's needs
  and configurations in mind, where traditional package managers have
  typically fallen short.

  If you've built Chapel from source, you're likely aware of the wide
  variety of knobs and configuration options that can be used to
  customize the installation.  The Chapel Spack package exposes these
  options as Spack _variants_, while also leveraging Chapel's existing
  logic to pick reasonable defaults for a given system or network.

  To get started with Chapel in Spack, refer to its new [Installing
  via Spack](https://chapel-lang.org/install-spack.html) webpage.  And
  thanks very much to Dan Bonachea&nbsp;(LBNL) and Peter
  Scheibel&nbsp;(LLNL) for their considerable help in reviewing,
  testing, and improving this new Chapel package during its
  development.
  
  #### Linux Packages

  If you manage a Linux system and prefer using its native package
  manager, for Chapel 2.1, we've started releasing Chapel as RPMs and
  Debian (`.deb`) packages.  This simplifies installation on popular
  Linux systems such as Ubuntu, Debian, Fedora, and RHEL by only
  requiring a download and a single `dnf install` or `apt install`
  command to get started.

  Currently, these packages are being made available in single-locale
  formats for those wanting to run on their Linux laptop or
  workstation.  For many flavors of Linux, we're also releasing
  multi-locale versions that support running on commodity clusters.

  Our multi-locale packages are currently built using Chapel's
  GASNet-EX/UDP configuration for portability.  This permits these
  packages to run on any network that supports TCP/IP, such as
  Ethernet.  In the future, we plan to add additional packages to
  support high-performance networks like InfiniBand.  We also
  anticipate supporting more package managers over time.  If there are
  specific configurations that you would like to see prioritized,
  please let us know!

  To learn more about this installation option, see our new
  [Installing Chapel using Linux Package
  Managers](https://chapel-lang.org/install-pkg.html) page.
 
  
  #### Homebrew

  Homebrew is a package manager that we've supported for some time
  now, and an important one due to its popularity in the Mac OS X
  community.  In Chapel 2.1, we've improved our Homebrew formula
  to use the preferred single-locale configuration, leveraging
  [Qthreads](https://www.sandia.gov/qthreads/) from Sandia National
  Labs, [hwloc](https://www.open-mpi.org/projects/hwloc/) from the
  OpenMPI community, and [jemalloc](https://jemalloc.net/).  These
  changes should result in performance boosts and better utilization
  of desktop hardware, particularly for workstations that have a mix
  of performance and efficiency cores.

  To leverage these improvements, see [Installing Chapel using
  Homebrew](https://chapel-lang.org/install-homebrew.html).

  #### AWS EFA

  Another aspect of deploying Chapel that we've been working on for
  version 2.1 is getting it running well on cloud providers, such as
  AWS (Amazon Web Services).  Specifically, we've made a lot of great
  progress improving Chapel execution using AWS's Elastic Fabric
  Adapter&nbsp;(EFA) network interface, in terms of both stability and
  correctness.  In future releases, we plan to support pre-packaged
  installations of Chapel for AWS/EFA, but in the meantime, we've
  updated our [Using Chapel on Amazon Web
  Services](https://chapel-lang.org/docs/2.1/platforms/aws.html)
  documentation to reflect current best practices.

  ### Remote Variable Declarations

  Chapel 2.1 provides a prototype implementation of a feature that's
  been planned since Chapel's inception, yet never implemented.  The
  idea is to prefix a variable declaration with a traditional
  `on`-clause to have the variable be allocated on a specific locale:

*/

  on Locales.last var x = 42;
  writeln("I'm running on locale ", here.id,
          ", but x is stored on ", x.locale.id);

/*

  The benefit of this feature is that it permits a variable to be
  stored anywhere on the system, yet without having its lifetime be
  bound to the lexical scope that a traditional `on`-clause would
  introduce:

*/

  on Locales.last {
    var x = 42;
    writeln("I'm running on locale ", here.id,
            ", and x is too (", x.locale.id,
            "), but only for this on-clause's scope");
  }

  
/*

  Until now, Chapel's classes were the only other way to decouple a
  variable's location from its scope, but that approach requires more
  code and effort to declare the class and manage its lifetime.  For
  simple cases like the one above, it ends up feeling like overkill.

  This new remote variable feature is particularly important for
  programming GPUs with Chapel since the top-level control logic can
  run on the CPU while declaring variables that are allocated in GPU
  memory and used across multiple GPU kernel launches.

  To learn more about this feature, refer to the [Remote Variable
  Declarations](https://chapel-lang.org/docs/2.1/technotes/remote.html)
  tech note in Chapel's documentation.

  ### GPU Reductions

  Speaking of GPUs, Chapel 2.1 continues to advance Chapel's support
  for GPU programming through a number of feature improvements and bug
  fixes.

  As a specific example, in Chapel 2.0, computing a reduction of an
  array to a scalar using a GPU required calling to library routines
  like `gpuSumReduce(myGpuArray)`.  For Chapel 2.1, we have extended
  Chapel's `reduce` expressions and intents so that traditional Chapel
  patterns like:

  ```chapel
  var sum = + reduce myGpuArray;
  ```

  or:

  ```chapel
  var sum: real;
  forall i in 1..n with (+ reduce sum) do ...
  ```

  can now be used to execute the reduction on a GPU.

  For more information about Chapel on GPUs, please refer to our
  ongoing [GPU Programming in
  Chapel]({{< relref "gpu-programming-in-chapel" >}})
  blog series or the [GPU
  Programming](https://chapel-lang.org/docs/2.1/technotes/gpu.html)
  tech note.

  ### Other Chapel 2.1 Highlights

  In addition to the items called out above, Chapel 2.1 contains many
  other improvements in terms of features, performance, documentation,
  and bug fixes, many of which have been motivated by user feedback or
  requests.  Here are a few highlights:

  * We have added the ability to automatically resolve warnings in
    Chapel's linter, along with a number of new warnings for various
    coding issues.  We also added the ability to list what rules are
    available and which are enabled.  For more information, see, the
    [`chplcheck`](https://chapel-lang.org/docs/2.1/tools/chplcheck/chplcheck.html)
    documentation.

  * The LSP-based Chapel Language Server (CLS) has advanced in a
    number of ways that improve the user experience, such as reasoning
    about `use` and `import` statements, as well as providing better
    error information in hover-based messages.  Further information
    can be found on the
    [`chpl-language-server`](https://chapel-lang.org/docs/2.1/tools/chpl-language-server/chpl-language-server.html) page.
    
  * We've added a new
    [Image](https://chapel-lang.org/docs/2.1/modules/packages/Image.html)
    package module that contains initial support for writing out image
    files.

  * We've also extended package modules like
    [ConcurrentMap](https://chapel-lang.org/docs/2.1/modules/packages/ConcurrentMap.html)
    and
    [EpochManager](https://chapel-lang.org/docs/2.1/modules/packages/EpochManager.html)
    to support Arm processors through portability improvements to the
    [AtomicObjects](https://chapel-lang.org/docs/2.1/modules/packages/AtomicObjects.html)
    package.

  For a more complete list of changes in this release, please refer to
  its
  [CHANGES.md](https://github.com/chapel-lang/chapel/blob/release/2.1/CHANGES.md)
  file.  And thanks to [everyone who
  contributed](https://github.com/chapel-lang/chapel/blob/release/2.1/CONTRIBUTORS.md)
  to Chapel 2.1!

  ### For More Information

  If you have questions about the release or its new features, please
  reach out on Chapel's [Discourse
  community](https://chapel.discourse.group/) or one of our other
  [community forums](https://chapel-lang.org/community.html).  As
  always, we're interested in feedback on how we can make the Chapel
  language, libraries, implementation, and tools more useful to you.
  
*/
