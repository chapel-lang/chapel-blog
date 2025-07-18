---
title: "Supercharged Chapel Editor Support"
date: 2024-04-04
tags: ["Tools", "Chapel 2.0", "Dyno"]
series: []
summary: "An introduction to new editor features supported by Chapel."
authors: ["Jade Abraham", "Daniel Fedorin"]
---

With the [2.0 release of Chapel]({{< relref "announcing-chapel-2.0/index.md" >}}),
many areas of the language have seen significant improvement. Several of these
improvements have changed Chapel's compiler and ecosystem, allowing the team to
create a fully-featured _Language Server_ for Chapel.  This brings tons of interactive features to your text editor,
making writing and reading Chapel code easier than ever.

In this article, we show off many of the exciting features of this new tool,
[Chapel Language Server&nbsp;(CLS)](https://chapel-lang.org/docs/2.0/tools/chpl-language-server/chpl-language-server.html).
Although demonstrations throughout the article are made using VSCode, CLS
itself is editor-agnostic. This means that you can configure
{{< sidenote "right" "your editor of choice" >}}
The Chapel team currently actively supports VSCode and NeoVim, but any editor
that supports the Language Server Protocol plugins can use these same features.
If you need support getting CLS in your favorite editor please let us know!
{{< /sidenote >}} to do many of the same things.

### Feature Highlights

Let's walk through one of our example codes,
[`examples/primers/fileIO.chpl`](https://github.com/chapel-lang/chapel/blob/release/2.0/test/release/examples/primers/fileIO.chpl)
and see the Chapel Language Server in action!

#### Go-to-Definition

Reading through this file, we see a procedure named `writeSquareArray` being
called. While we could search through the file manually for anything named
`writeSquareArray`, it is faster to go straight to its definition using
the editor's features:

{{< figure src="gotodef.gif" class="fullwide" caption="Jumping to a symbol's definition" >}}

#### Hover for Documentation

Inside of `writeSquareArray`, we see a file being opened with an `ioMode`
argument. This is a great opportunity to show off more features; we can hover
over it and see the documentation for `ioMode` right inside the editor:

{{< figure src="hover.gif" class="fullwide" caption="Viewing a symbol's declaration and documentation" >}}

Of course, we could also jump straight to its definition in the standard modules
and inspect the implementation directly.

#### Refactoring Code

The next feature we show off is applying code modifications. We can use the
_Rename Symbol_ feature to change all occurrences of a symbol to a new name.
For example, here, we rename `writer` to `myWriter`:

{{< figure src="rename.gif" class="fullwide" caption="Renaming a symbol" >}}

#### Diagnostics

With CLS running in an editor, we can see warnings and errors in real time. The following code produces both a warning and an error:

{{< subfile fname="diagnostics.chpl" lstart=1 lstop=13 lang="Chapel" section="middle" >}}

Without running the compiler, we can see that the editor is already showing us this information:

{{< figure src="diagnostics.png" class="fullwide" caption="Viewing diagnostics in the editor" >}}

#### Resolving Diagnostics

The last of the core features we want to show is a more complex code
modification. Not only can we see diagnostics right in
the editor, but in some cases we can automatically resolve them. Currently, we
have a number of deprecations wired up to support this. Let's see this in action:

{{< figure src="resolveDiagnostics.gif" class="fullwide" caption="Automatically resolving deprecations" >}}

All of these features mean you spend less effort on the mechanics of writing
code and more time thinking about the problem you're trying to solve.

### Using CLS in your application

So far, we have shown the language server working on a single file that is only
using the Chapel standard library. The CLS features we've shown off so far can
also be used with large projects that have complex build systems. To support that,
we provide `chpl-shim`, a utility that inspects the build process to collect
all the information the language server needs. All that is required is to prefix
the compilation command; for example, instead of `chpl ...` we use `chpl-shim chpl ...`.

Let's take [Arkouda](https://github.com/bears-r-us/arkouda#readme), a Python
data analytics package written in Chapel, as an example. After installing all
of the dependencies, Arkouda is built by calling `make`. To gather build
information for CLS, we can invoke:

```bash
$CHPL_HOME/tools/chpl-language-server/chpl-shim make
```

This creates a `.cls-commands.json` file that contains all of the information CLS needs. Now when we open the Arkouda project in our editor, we can use all of the features we've shown off so far.

{{< figure src="arkouda.gif" class="fullwide" caption="CLS in Arkouda" >}}

One thing to watch for in this demo is how fast it is. Arkouda is a large
project at nearly 40,000 lines of Chapel code. You can see this when we jump to
the definition of `NumPyDType`. The first time,
{{< sidenote "right" "it takes a second." >}}
These demos were done using a debug build of the compiler, causing this slight delay. When using a release build, this initial delay is greatly reduced.
{{< /sidenote >}}
The second time, it is instantaneous. This is because the language server is
using the Dyno compiler library, which uses a query system to quickly respond
to incremental changes in files by only recomputing what has actually changed.


{{< details summary="**(Tell me more about Dyno)**" >}}

The Chapel language is currently in the middle of a compiler revamp, a project
we have been calling _Dyno_. Dyno is a compiler library that is used in the
`chpl` compiler while also serving as a resource for other programs like the language
server. This allows tool writers to use the same parsing and resolution logic
as the compiler. For example, `chpldoc`, our documentation generation tool, is built using
the Dyno library. We can also use it to build tools like the Chapel linter—`chplcheck`—and
of course the language server.

Having the compiler as a library is great, but there's much more to Dyno than
that! The Dyno query system enables rapid responses to incremental changes in
files by only recomputing what has actually changed. If we modify one local
variable in a subroutine, we will only re-resolve aspects of that routine's
body that are sensitive to the change. This means that when using tools built
on Dyno, you get real-time feedback as you write code.

{{< /details >}}

### Experimental Features

With Dyno, features based on _type resolution_ are becoming available to tools,
including the Chapel Language Server. Although type resolution is still a work
in progress, we'd like to showcase some advanced features that rely on it.

#### Type Inlays

The first feature we want to show off is _type inlays_. These are hints that
display the (inferred) type of a variable declaration if one is not explicitly
provided. For example, you might have a declaration like this:

{{< subfile fname="somecomplexfunction.chpl" lstart=7 lstop=8 lang="Chapel" section="middle" >}}

What's the type of 'result'? Type inlays make the answer evident at a glance:

{{< figure src="resultTypeInlay.png" class="fullwide" caption="Displaying an inferred variable type" >}}

#### Dead Code

We can show off another feature of CLS using `if`-statements whose
branches are known at compile-time. Since the compiler discards branches that
it knows cannot be taken, the code in those branches never runs. When CLS
detects such code, it displays the dead code as a comment. For
example, consider the following excerpt:

{{< subfile fname="somecomplexfunction.chpl" lstart=16 lstop=24 lang="Chapel" section="middle" >}}

Since we declared `firstParam` to be `1` above, the `else` branch will never
be taken. Because of this, CLS displays that branch using the editor's
comment color, indicating that `thirdParam` is set to `"hello"`.

{{< figure src="deadCode.png" class="fullwide" caption="Identifying dead code in conditionals" >}}

#### Generics

Let's move on to another fun feature: displaying instantiations. Chapel
supports _generic_ procedures. Instead of accepting only one type of expression
for each argument, these procedures allow different types at different callsites. For example, here's
a toy procedure, `assignOneToAnother`, that takes a reference to a variable and
sets that variable to a new value:

{{< subfile fname="somecomplexfunction.chpl" lstart=26 lstop=28 lang="Chapel" section="middle" >}}

Note that we haven't specified the type of `changeMe`, and therefore, any type
can serve as an argument. We did, however, constrain the type of `changeTo`.
Thus, the procedure has to be called with two integers, or two strings, but
not an integer and a string. Having defined our procedure, let's call it with
two different sets of arguments:

{{< subfile fname="somecomplexfunction.chpl" lstart=29 lstop=32 lang="Chapel" section="middle" >}}

Now there are two instantiations of `assignOneToAnother`: one with integer
arguments, and one with string arguments. We can view both of them, and
have the type hints inform us of the types of various intermediate variables
in the procedure's body. Here's an animated demo:

{{< figure src="instantiations1.gif" class="fullwide" caption="Viewing different instantiations of a generic procedure" >}}

Chapel allows compile-time inspection of types too. Generic procedures often
make use of this, by checking if an argument is of a certain type and
changing behavior accordingly. For example, one might see a pattern like
the following:

{{< subfile fname="somecomplexfunction.chpl" lstart=34 lstop=45 lang="Chapel" section="middle" >}}

Here, we have a compile-time procedure that checks if some type allows for
executing an operation more efficiently. In our case, we pretend that
there's an efficient implementation of our operation (computing pi),
called `doEfficientOperation`, that works only with integer arguments. For
all other types of arguments, we fall back to the imaginary "slow" version,
`doSlowOperation`. In this case, to represent the fact that it's "slow", we
wrote it with an addition. We stress that this is a toy example, only meant
to illustrate a common pattern in Chapel code.

Finally, `genericFunction` accepts any argument `x`, and decides whether
it should perform the operation efficiently or slowly. It relies on the
result of calling `typeSupportsEfficientOperation`.

When we view instantiations of this procedure, we see that CLS is smart enough
to figure out the value of the `if`-statement in each version of the procedure,
and it highlights the branch that's taken: `doEfficientOperation` for the `int`
argument, and `doSlowOperation` for the `string` argument:

{{< figure src="instantiations2.gif" class="fullwide" caption="Detecting dead code in different instantiations of a generic function" >}}

#### Call Graphs

The final feature we want to show off is the _call graph_. This feature allows
you to view the incoming and outgoing calls for particular procedures. For
example, perhaps you have found a procedure and want to determine where it
is called from. In the animated example below, we use the call graph
to find where `doEfficientOperation` is used in our test file:

{{< figure src="callGraph.gif" class="fullwide" caption="Viewing calls to a procedure using CLS" >}}

Notice that in this example, although `genericFunction` is called twice,
it only shows up once in the list of callers for `doEfficientOperation`, and
only the `int`-based call to it is shown. This is because CLS detects that
only one of the instantiations of `genericFunction` (namely the one with
integers) calls `genericFunction`, and thus, only the `genericFunction(42)`
results in a call to `doEfficientOperation`.

When developing Chapel code, one might be interested in figuring out why
exactly a procedure has certain instantiations. The instantiations feature can
be used in tandem with the call graph to individually inspect where each
instantiation is called from.

{{< figure src="findingInstantiations.gif" class="fullwide" caption="Finding calls to different instantiations of a procedure" >}}

You can view the file used for these examples here:

{{< file_download_min fname="somecomplexfunction.chpl" lang="Chapel" >}}

### Conclusion

With the Chapel Language Server, Chapel users have gained a powerful new tool
to read and write Chapel code. We have shown off many of the features that CLS
provides, with a glimpse of what's on the horizon.  We hope that you will give
it a try and let us know what you think!

To try CLS, check out our list of supported editors
[here](https://chapel-lang.org/docs/2.0/tools/chpl-language-server/chpl-language-server.html#getting-started).
If you have any questions or feedback, please feel free to reach out to the
Chapel team!
