// Announcing Chapel 2.9!
// authors: ["Daniel Fedorin", "Brad Chamberlain"]
// summary: "Highlights from the June 2026 release of Chapel 2.9"
// tags: []
// series: ["Release Announcements"]
// date: 2026-06-01
/*

  The Chapel developer community is pleased to announce the release of
  Chapel 2.9!

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


*/
