---
title: "Using the Chapel Compiler to Develop Language Tooling"
date: 2025-02-04
tags: ["Tools", "How-To", "Dyno"]
authors: ["Daniel Fedorin"]
summary: "A demonstration of using Chapel's compiler library to develop custom language tooling"
---

Despite its name, the Chapel compiler isn't just for compiling Chapel programs.
As a benefit of an ongoing rewrite --- an effort the team
has nicknamed _Dyno_ --- Chapel's front-end is being redesigned to be more
modular and re-usable. This direction has allowed the team to separate
Chapel's documentation tool, [`chpldoc`](https://chapel-lang.org/docs/tools/chpldoc/chpldoc.html),
from the compiler and make it a standalone tool. In addition,
[as we've written about before]({{< relref "chapel-lsp" >}}), we used the new
front-end to develop a language server, [`chpl-language-server`](https://chapel-lang.org/docs/tools/chpl-language-server/chpl-language-server.html), and a linter, [`chplcheck`](https://chapel-lang.org/docs/tools/chplcheck/chplcheck.html).

The new front-end is not just for use by the core Chapel team; by using the
new compiler library, __anyone can develop their own tools that interact with
Chapel's source code__. In this post, I'll tell you how you can do that,
and give other examples of what can be done. The library is written in C++,
but I find that its [Python bindings](https://chapel-lang.org/docs/tools/chapel-py/chapel-py.html)
are an excellent way to get started and iterate on language tooling.

### Getting Started

The process for installing the Python bindings to the compiler is
[well-documented elsewhere](https://chapel-lang.org/docs/tools/chapel-py/chapel-py.html#installation),
and may well change after I write this post as the bindings become
more mature, so I will not go over it here.

Let's start with something simple. The Chapel convention is that record types should
have names that start with a lowercase letter (more specifically, Chapel
records should be in `camelCase`). Let's write a script that finds all record
declarations in a given file, and makes sure that they follow this convention.
The full code is below; I will explain it in detail in subsequent paragraphs.

{{< file_download fname="records.py" lang="python" >}}

Let's break this piece of code down and go piece-by-piece. At the top, we have
some imports. For the most part, these are the standard library. The only
one specific to the Chapel compiler --- as you might have guessed --- is
the following:

```python
from chapel import *
```

For convenience, I import the entire module.

Next up, I define a function that
checks if a string is in `camelCase`. Its definition isn't so important
to this post, but feel free to expand the explanation below if you're interested.

{{< details summary="**(Click here to see how `is_camel_case` works)**" >}}
The `is_camel_case` function uses a [regular expression](https://docs.python.org/3/library/re.html#regular-expression-syntax)
to check if a string is in the desired format.
This expression might look a little daunting. All it does, however, is specify that the first character should
be a lowercase letter (`[a-z]`), after which can follow any number or lowercase
letters (`+` means "one or more"). After that, any number of chunks can follow
that start with an uppercase letter (`[A-Z]`).

A special exception is made for words made up of _only_ uppercase letters,
to allow for acronyms such as `GPU`.

The regular expression below is precisely the one used by the Chapel linter,
`chplcheck`!

```python
def is_camel_case(name: str):
    return re.fullmatch(r"([a-z]+([A-Z][a-z]*|\d+)*|[A-Z]+)?", name)
```
{{< /details >}}

Finally, we get to the code that makes use of the compiler front-end. At the
core of Dyno is the `Context` object. I will go into more detail about this
later. For now, it's sufficient to understand that the `Context` keeps track
of all of the compiler state, including its configuration, the source code
being compiled, and any information that has been extracted from it. With
the context in hand, we can parse whatever file the user has given us on
the command line:

```python
context = Context()
modules = context.parse(sys.argv[1])
```

A Chapel file is a collection of [modules](https://chapel-lang.org/docs/language/spec/modules.html).
When the file is parsed, the Chapel compiler will return a list of these modules.
All that's left is to look at all the records in the given file, and check
if their names are in `camelCase`. If they are not, we print a message.

```python
for module in modules:
    for record, _ in each_matching(module, Record):
        if not is_camel_case(record.name()):
            print("Record name is not in camel case:", record.name())
```

The `each_matching` function is provided by the `chapel` module; it takes
as arguments a pattern and a place to search for that pattern. In our case,
the pattern is simply `Record` (representing record declarations in the source
code), and the place is the `module` object. For each piece of code that
matches the pattern, the function will return a tuple containing the matching
object. It also returns a second value, which we ignore here; this value
is used when the pattern is more complex and we want to extract more information
from the matching object. The program is traversed recursively by `each_matching`,
so it would return nested records as well.

Running the script on the following Chapel file:

{{< file_download fname="record-naming.chpl" lang="chapel" >}}

I get the following output:

```console
Record name is not in camel case: NotFine
```

What I presented here is a very simplified implementation of what goes on
in the `chplcheck` linter! In just 14 lines, we were able to get started
on developing language tooling.

### Abstract Syntax Trees

The Chapel compiler, like most others, for the most part does not work with
the textual representation of the code. Instead, through a process called
_parsing_, the compiler converts the source code into a tree representation;
specifically, an [abstract syntax tree (AST)](https://en.wikipedia.org/wiki/Abstract_syntax_tree).
ASTs naturally encode the precedence of operators, nesting of expressions,
and other syntactic information that is harder to retrieve from the program
text.

As an example, take a look at the following program and its AST
representation.

{{< sidebyside >}}
{{< side weight="0.5" >}}
{{< file_download fname="one-two-three.chpl" lang="chapel" >}}
{{< /side >}}
{{% side %}}
{{< figure src="ast.png" alt="A tree corresponding to the expression 1+2*3" class="fullwide" >}}
{{% /side %}}
{{< /sidebyside >}}

All Chapel code is eventually contained within a module. Thus, a `Module` node
is at the root of the syntax tree. Each node has children that represent
other pieces of code contained within it. Since the module in the above program
contains two statements, these two statements are children of this module.

The first statement is a variable declaration. This is represented using a
`Variable` node. The node contains the name of the
variable being declared, `x`. The only child of this node is the expression
that is being used to initialize `x`, which is `1+2*3`. Because multiplication
has a higher precedence than addition, that expression is interpreted as
`1+(2*3)`. So, the multiplication is "contained" within the addition, and
the multiplication node (`OpCall *`) is a child of the addition node<br> (`OpCall +`).

The second is a call to `writeln` with the variable `x`. This is represented by
a function call node. The children of this call are the "called expression"
(in this case, the `writeln` procedure) and the arguments being passed
(in this case, the variable `x`).

Each type of node in the tree can be used as a pattern. The ones we've seen
so far are `Record`, `Module`, `Variable`, `OpCall`, `IntLiteral`, `FnCall`,
and `Identifier`. To drive the point home, we can print the value of each
integer literal and each binary operation in the program.

{{< file_download fname="ops.py" lang="python" >}}

```console
Found an operation: +
Found an operation: *
Found a literal: 1
Found a literal: 2
Found a literal: 3
```

The types of nodes in the Chapel AST form a Python class hierarchy. For instance,
both the `FnCall` and the `OpCall` nodes inherit from a `Call` node. If
you wanted to match all calls, using the `Call` node as a pattern would
match both function and operator calls. Similarly, all loops that have index
variables (e.g., `for`, `foreach`, `forall`) inherit from an `IndexableLoop`
base class. I've included the entire list of available classes, organized
in a tree, below. Because it is quite large, I've collapsed it to avoid taking
up too much vertical space; you can click the sentence below to expand it.

{{< details summary="**(Click here to see the Dyno class hierarchy)**" >}}

```
AstNode
├── AnonFormal
├── As
├── Array
├── Attribute
├── AttributeGroup
├── Break
├── Catch
├── Cobegin
├── Conditional
├── Comment
├── Continue
├── Delete
├── Domain
├── Dot
├── EmptyStmt
├── ErroneousExpression
├── ExternBlock
├── FunctionSignature
├── Identifier
├── Implements
├── Import
├── Include
├── Init
├── Label
├── Let
├── New
├── Range
├── Require
├── Return
├── Select
├── Throw
├── Try
├── Use
├── VisibilityClause
├── When
├── WithClause
├── Yield
├── SimpleBlockLike
│   ├── Begin
│   ├── Block
│   ├── Defer
│   ├── Local
│   ├── Manage
│   ├── On
│   ├── Serial
│   └── Sync
├── Loop
│   ├── DoWhile
│   ├── While
│   └── IndexableLoop
│       ├── BracketLoop
│       ├── Coforall
│       ├── For
│       ├── Forall
│       └── Foreach
├── Literal
│   ├── BoolLiteral
│   ├── ImagLiteral
│   ├── IntLiteral
│   ├── RealLiteral
│   ├── UintLiteral
│   └── StringLikeLiteral
│       ├── BytesLiteral
│       ├── CStringLiteral
│       └── StringLiteral
├── Call
│   ├── FnCall
│   ├── OpCall
│   ├── PrimCall
│   ├── Reduce
│   ├── Scan
│   ├── Tuple
│   └── Zip
└── Decl
    ├── MultiDecl
    ├── TupleDecl
    ├── ForwardingDecl
    └── NamedDecl
        ├── EnumElement
        ├── Function
        ├── Interface
        ├── Module
        ├── TypeQuery
        ├── ReduceIntent
        ├── VarLikeDecl
        │   ├── Formal
        │   ├── TaskVar
        │   ├── VarArgFormal
        │   └── Variable
        └── TypeDecl
            ├── Enum
            └── AggregateDecl
                ├── Class
                ├── Record
                └── Union
```
{{< /details >}}

The exact class hierarchy may differ depending on the version of Chapel.
I used the following script to generate the formatted version above,
which can be used to get an up-to-date version.

{{< file_download_min fname="hierarchy.py" lang="python" >}}

When writing Chapel tooling, the AST nodes are one of the primary ways in
which a programmer interacts with a Chapel program. The various methods provided
by AST node classes, as well as other available features, are documented in
the auto-generated [`chapel` module documentation](https://chapel-lang.org/docs/tools/chapel-py/chapel-py.html#module-chapel)
(in particular, the documentation for classes, including AST node classes, starts with [`AggregateDecl` here](https://chapel-lang.org/docs/tools/chapel-py/chapel-py.html#chapel.AggregateDecl)).
The Python bindings also generate a `.pyi` file which contains the same information,
and can be used for Python type checking and autocompletion in editors.

### More Patterns and the `chapel.replace` Module
I've mentioned before that AST nodes can be used as patterns. However,
not all patterns are just AST nodes. The `chapel` module supports writing
more complicated patterns, which can help find more specific pieces of code.
For this section, we'll implement a somewhat limited and impractical version
of a common transformation: constant folding. This transformation replaces
operations on known values with their result. Thus, a program like:

```Chapel
var x = 1+2;
```

Might be transformed into:

```Chapel
var x = 3;
```

I would like to stress that this transformation will be limited --- we will simplify
`1+2*3` into `1+6`, not `7`, and we will only handle integers --- and impractical, in the sense
that the Chapel compiler already performs constant folding as a part of
compiling a program (so transforming a source file in this way will not
have any advantages). However, implementing this transformation will allow us
to play with more sorts of patterns.

Another form of pattern in Chapel's API is a list. When the pattern is
a list, the first element will be matched against AST nodes, whereas the
subsequent elements will be matched against the children of the matched node.
Thus, `[OpCall, IntLiteral, IntLiteral]` is a pattern that matches any
binary operation whose operands are integer literals. The expression `2*3`
will match this pattern, but `1+2*3`, as a whole, will not. Running the following
Python code:

```Python
for module in modules:
    for op, _ in each_matching(module, [OpCall, IntLiteral, IntLiteral]):
        print("Found an operation:", op.op())
```

on our previous example file, `one-two-three.chpl`, produces the following output, which excludes the addition:

```Console
Found an operation: *
```

A powerful feature of the pattern API is being able to store parts of the matched
AST into a dictionary. Specifically, replacing `IntLiteral` with `("?x", IntLiteral)`
will still match the same type of node, but will store the match into
key `"x"` of the dictionary. This can be used to conveniently retrieve child AST nodes
that are nested deeper in the tree. We can adjust our pattern to do this:

```Python
for module in modules:
    pattern = [OpCall, ("?lhs", IntLiteral), ("?rhs", IntLiteral)]
    for op, vars in each_matching(module, pattern):
        print("Found an operation:", op.op())
        print("Left operand:", vars["lhs"].text())
        print("Right operand:", vars["rhs"].text())
```

Note that the variable we previously ignored --- the second element of the
tuple yielded by `each_matching` --- is now stored into the dictionary variable
`vars`. Running the script above produces:

```Console
Found an operation: *
Left operand: 2
Right operand: 3
```

Given this information, we can work on simplification. For the time being,
let's just implement the four basic arithmetic operations: addition, subtraction,
multiplication, and division.

```Python
def simplify(opnode, lhs, rhs):
  op = opnode.op()
  lhs_val = int(lhs.text())
  rhs_val = int(rhs.text())

  if op == "+":
    return lhs_val + rhs_val
  elif op == "-":
    return lhs_val - rhs_val
  elif op == "*":
    return lhs_val * rhs_val
  elif op == "/":
    return lhs_val // rhs_val
  else:
    return None

for module in modules:
    pattern = [OpCall, ("?lhs", IntLiteral), ("?rhs", IntLiteral)]
    for op, vars in each_matching(module, pattern):
        result = simplify(op, vars["lhs"], vars["rhs"])
        if result is not None:
            (first_line, _) = op.location().start()
            print("I would simplify an expression on line", first_line, "to", result)
```

Running it on the example above, `one-two-three.chpl`, the script produces:

```Console
I would simplify an expression on line 1 to 6
```

To actually perform the simplification, we will use the [`chapel.replace`
module](https://chapel-lang.org/docs/tools/chapel-py/chapel-py.html#chapel-replace).
This module is specifically provided to help modify Chapel programs via their ASTs.
The core feature of this module is the `run` function, which takes a Python
function that finds nodes to replace and then takes over the execution
of the Python program to transform it into a command-line replacer. To
make use of this, all we need to do is turn the outer loop over modules into
a function. Instead of calling `print`, this function should yield the
node-to-replace, as well as the new textual value to replace it with.

```Python {hl_lines="1 5"}
def simple_constant_fold(rc, module):
    for op, vars in each_matching(module, [OpCall, ("?lhs", IntLiteral), ("?rhs", IntLiteral)]):
        result = simplify(op, vars["lhs"], vars["rhs"])
        if result is not None:
            yield (op, str(result))

run(simple_constant_fold)
```

Running this file as follows:

```bash
python fold.py one-two-three.chpl
```

Produces:

```Chapel
var x = 1+6;
writeln(x);
```

The following is the complete script we developed in this section:

{{< file_download_min fname="fold.py" lang="python" >}}

### Using Semantic Information
So far, all of the things we've done with our Python scripts have been syntactic:
they looked solely at the structure of the program, without needing to
make sense of the program's meaning.

What does it mean to look at the program's meaning? For an example, take a look
at the following program:

```Chapel
use IO;

writeln(ioMode : string);
```

This is a valid Chapel program, and it prints `ioMode`. Where did
`ioMode` come from, though? There certainly isn't a definition of that
type in this snippet. The answer is that `ioMode` has been
brought in through the `use IO` statement at the top of the program. If we
were to write a version of the program that was only slightly different,
it would not compile:

```Chapel
use IO except ioMode;

writeln(ioMode : string); // error: ioMode is not defined
```

To understand whether or not an identifier like `ioMode` is valid in a given
scope, we need to understand what the surrounding statements
--- such as `use IO` --- actually do, and how they affect the program.
This is what I mean by the "meaning" of the program. In the field of programming
languages, the "meaning" of a program is often referred to as its _semantics_.

{{% pullquote %}}
A major advantage of using the Chapel compiler library to develop language tooling
is that it can be queried for semantic information, which would be
very hard to replicate in a standalone tool.
{{% /pullquote %}}

Following the semantics can be tricky. In the first example, even though `ioMode` doesn't occur in
the `use` statement, it's brought into scope from the `IO` module. In the
second example, even though `ioMode` is explicitly mentioned, it's excluded,
and therefore not in scope. A major advantage of using the Chapel compiler
library to develop language tooling is that it can be queried for semantic
information, which would be very hard to replicate in a standalone tool.

To show this off, let's write a script which I will dub "docbot". It will
read a Chapel program, find all references to standard variables and types,
and print out links to their documentation on the Chapel website. We start
out as before, except that this time, I configure `context`'s search paths.
{{< sidenote "right" "This enables it to find the standard library modules." -8 >}}
When using semantic information, it's important to enable Dyno to access
the standard modules. This is true in part because the standard modules define
a number of essential Chapel procedures (e.g., `writeln`).
More importantly, many Chapel features (ranges,
arrays, tuples) are defined using module code. When querying type information
in particular, these features will be inscrutable without the standard modules.
{{< /sidenote >}}
The empty lists I use as arguments indicate that I am not overriding any
of the default search paths.

{{< subfile fname="docbot.py" lang="python" lstart=1 lstop=6 section="first" >}}

For this program, the "secret ingredient" will be the [`to_node`](https://chapel-lang.org/docs/tools/chapel-py/chapel-py.html#chapel.Identifier.to_node)
method. This method, defined on `Identifier` and `Dot` nodes (which represent
something like `x.y`),
{{< sidenote "right" "finds what the node refers to" >}}
One caveat to using `to_node` is that it does not perform call resolution.
Chapel supports [function overloading](https://chapel-lang.org/docs/language/spec/procedures.html#function-and-operator-overloading), which means that without type information,
it's not always possible to determine what the `foo` in
`foo(x)` refers to. Type checking is far more complicated than
name resolution (hence, slower), and is still an active area of work within
Dyno.

It's possible to use type resolution to retrieve refers-to information,
but this is not done by `to_node`, and doing so is prone
to running into limitations of Dyno's current implementation.
{{< /sidenote >}} and returns the AST
node of that definition. The following Chapel program is commented with
some examples:

```chapel {linenos="table"}
record someRecord {}
var myNumber = 42;

// calling to_node on 'someRecord' will return the declaration on line 1
writeln(new someRecord());

// calling to_node on 'myNumber' will return the declaration on line 2
writeln(myNumber);

// calling to_node on 'IO' will return the AST node for the IO module.
use IO;
```

The `to_node` method uses the exact same process as the Chapel compiler
when performing name resolution. This has two important consequences:

1. You do not have to handle any of it yourself. There's no need to worry
   about scopes, shadowing, `use`s and `import`s, or any of the other complexities of name resolution.
2. The information you get will always match what the Chapel compiler would
   see. This guarantees correctness, in the sense of matching the reference
   implementation.


To implement "docbot", we once again iterate over all the
modules, and for each node that's an `Identifier` or a `Dot` node, we use
`to_node` to compute what the node refers to. All that's left then is to
print the associated link, as well as the line that it occurs on.

{{< subfile fname="docbot.py" lang="python" lstart=42 lstop=50 section="last" >}}

I've glossed over finding the documentation links for the referenced definitions.
There is a way to do this, but it's not particularly critical for the point of
this demonstration. As a result, I will relegate its explanation to the [appendix](#appendix-building-documentation-urls);
it's sufficient to take for granted a function `find_doc_link`, which, given
an AST node of a standard library definition, generates a link to its documentation.

The above example uses a `set` pattern, which is used to match _either_ of
its arguments. Thus, `set([Identifier, Dot])` will match either an `Identifier`
or a `Dot` node.

Running this script on the following Chapel program:

{{< file_download fname="list-io.chpl" lang="chapel" >}}

Results in the following output:

```Console
On line 1, URL: https://chapel-lang.org/docs/modules/standard/IO.html
On line 1, URL: https://chapel-lang.org/docs/modules/standard/List.html
On line 3, URL: https://chapel-lang.org/docs/modules/standard/List.html#List.list
On line 4, URL: https://chapel-lang.org/docs/modules/standard/IO.html#IO.ioMode.r
On line 4, URL: https://chapel-lang.org/docs/modules/standard/IO.html#IO.ioMode
```

All of these links work and take us to the Chapel docs!

You can view or download the complete `docbot.py` script below.

{{< file_download_min fname="docbot.py" lang="python" >}}

To go further with semantic information, you might use the following methods:

* [`type`](https://chapel-lang.org/docs/tools/chapel-py/chapel-py.html#chapel.AstNode.type)
  can be used to trigger type resolution and figure out what type a given
  node has. This can be invoked on any AST node, though only expression-like
  nodes will return a meaningful result.
* [`resolve`](https://chapel-lang.org/docs/tools/chapel-py/chapel-py.html#chapel.AstNode.resolve)
  gives you access to more of the resolution information. In addition to including
  the `type` above, it also includes the results of function resolution, if
  any, which make it possible to inspect what overloads were selected when
  resolving calls.
* [`resolve_via`](https://chapel-lang.org/docs/tools/chapel-py/chapel-py.html#chapel.AstNode.resolve_via)
  can be used to perform resolution within generic instantiations. This
  method is used to implement the ["generic views"]({{< relref "chapel-lsp#generics" >}})
  in the Chapel Language Server.

### Next Steps

I hope this article has given you a taste of what the Chapel front-end library
can do. The Dyno effort is not just a project to improve or rewrite the code
of the Chapel compiler; its goals also include allowing others to leverage
the compiler for their own purposes. The Python bindings are a great way
to get started with this, though the full API is also available in C++.
Please see the [`chpldoc` source code](https://github.com/chapel-lang/chapel/blob/main/tools/chpldoc/chpldoc.cpp)
for an example of using the C++ API, and the
[`chpl-language-server`](https://github.com/chapel-lang/chapel/tree/main/tools/chpl-language-server) or
[`chplcheck`](https://github.com/chapel-lang/chapel/tree/main/tools/chplcheck)
source code for larger examples of using the Python API.

### Appendix: Building Documentation URLs

This appendix describes how "docbot" generates URLs to documentation.
One thing to know is that the [Chapel documentation of the standard modules](https://chapel-lang.org/docs/modules/standard.html)
is organized by module. Thus, the `IO` module will have its own page, as would
the `List` module, and so on. If we find that an `Identifier` refers
to some declaration, we will need to find which module it comes from.

{{< subfile fname="docbot.py" lang="python" lstart=8 lstop=12 section="middle" >}}

The [`parent_symbol` method](https://chapel-lang.org/docs/tools/chapel-py/chapel-py.html#chapel.AstNode.parent_symbol)
finds the symbol --- function declaration, module,
record, etc. --- inside which the given node is being defined. We simply keep
traversing the AST upwards until we find a module (as I mentioned before,
all Chapel code is contained within some module).

There are two more helper functions I ended up using. One of these is `build_url`,
which builds the name of the HTML file corresponding to a particular module.
This name is not _just_ the module name, because some modules can be nested
inside of others (e.g., we might have `OuterModule.InnerModule.html`). Thus,
this function traverses upwards through the AST to build a fully-qualified module
path.

{{< subfile fname="docbot.py" lang="python" lstart=15 lstop=20 section="middle" >}}

The last bit is finding the right definition within its module's page. Chapel
provides HTML IDs for each definition. For a module-level variable or type declaration,
the ID is just its name. For something like an element of an enumeration (e.g.,
the `r` in `ioMode`), the ID is fully qualified (i.e.,&nbsp;`ioMode.r`). The
`build_anchor` function takes care of getting this piece.

{{< subfile fname="docbot.py" lang="python" lstart=22 lstop=35 section="middle" >}}

Finally, `find_doc_link` puts all of this together:

{{< subfile fname="docbot.py" lang="python" lstart=37 lstop=40 section="middle" >}}
