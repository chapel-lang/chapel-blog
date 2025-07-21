---
title: "10 Myths About Scalable Parallel Programming Languages (Redux),  Part 4: Syntax Matters"
date: 2025-07-23
tags: ["Editorial", "Archival Posts / Reprints"]
series: ["10 Myths About Scalable Parallel Programming Languages Redux"]
summary: "The fourth archival post from the 2012 IEEE TCSC blog series with a current reflection on it"
authors: ["Brad Chamberlain"]
---

### Background

In 2012, I wrote a series of eight posts entitled "Myths About
Scalable Parallel Programming Languages" for the IEEE Technical
Community on Scalable Computing&nbsp;(TCSC) blog.  In it, I described
discouraging attitudes that our team encountered when talking about
developing a language like Chapel, and I gave my personal rebuttal to
them.  That series has generally been unavailable for many years, so
for its 13th anniversary, we're reprinting the original series here on
the Chapel blog, along with new commentary about how well or poorly
the ideas have held up over time.  For a more detailed introduction to
both the original series and this updated one, please see [the first
article]({{< relref 10myths-part1 >}}) in this series.


This month, we're reprinting the fourth article in the original
series, originally published on July 23, 2012.  Comments in the
sidebar and in [sections that follow the reprint]({{<relref
"#reflections-on-the-original-article">}}) reflect current thoughts
and reflections on it:


---

### The Original Article, Reprinted

Myths About Scalable Parallel Programming Languages:<br>
Part 4: Syntax Matters
{.big}

This is the fourth in a series of blog articles that I’m writing with
the goal of listing and responding to some of the assumptions about
developing scalable parallel programming languages that our team
encounters when talking about our work designing and implementing
Chapel (https://chapel-lang.org).

For more background on Chapel or this series of articles, please refer
to parts [1]({{< relref 10myths-part1
>}}#the-original-article-reprinted), [2]({{< relref 10myths-part2
>}}#the-original-article-reprinted), and [3]({{< relref 10myths-part3
>}}#the-original-article-reprinted).

#### Myth #4: Syntax doesn’t matter.

This myth is somewhat related to last month’s.  In many cases,
attempts to improve on existing syntax are belittled within the
computer science community for being shallow, or merely sugary,
contributions.  A common attitude is “if it doesn’t give me improved
semantic power, it’s not worth my time.”  In this article, I want to
challenge this notion.  While most of our programming languages are
Turing complete, there’s a good reason that we don’t code in terms of
{{<sidenote "right" "tape reads/writes/shifts">}}In case it's not
obvious, I was referring to programming an abstract [Turing
Machine](https://en.wikipedia.org/wiki/Turing_machine)
here.{{</sidenote>}} or lambda calculus—namely, because syntax
matters.

A few years back, I’d frequently run into a close colleague, and our
conversations about programming models like Chapel would inevitably
reach a point where she would say “syntax matters!”  And I would
vehemently agree, saying, “yes, syntax does matter!”  It took several
iterations of this exchange until I finally realized that we were
saying very different things in spite of our apparent agreement.

By her statement, she meant, “programmers care about syntax and won’t
use new languages that don’t extend those with which they’re already
familiar.”  A common illustration of this opinion is seen in users who
clamor for new and better ways of programming existing and emerging
large-scale machines, yet don’t want you to change a single thing
about their favorite language.  This was essentially the theme of
[last month’s article]({{< relref 10myths-part3
>}}#the-original-article-reprinted), so I won’t repeat those arguments
here.

In contrast, when I said “yes, syntax matters!” what I was saying is
that I believe syntax can markedly improve the readability,
writeability, clarity, and maintainability of a program; and that the
benefits of an improved syntax can easily be worth the effort that it
may take a C, Java, or Fortran programmer to adjust to its novelty.
Moreover, I believe that a well-designed syntax can often make a novel
language easier to learn, as compared to sticking with an established
syntax merely for the sake of familiarity.

As I mentioned last month, in Chapel’s design, we have generally
{{<sidenote "right" "followed C’s lead syntactically">}}Re-reading
this today, it's interesting to me that I characterized Chapel as
being so C-oriented when writing this series.  Today, I tend to
describe Chapel as taking ideas and syntax from a number of languages
without necessarily placing special emphasis on C.  Maybe because
Python and other languages have become so much more
prominent?{{</sidenote>}}, but have also felt free to depart from it
in cases where we believe the benefits outweigh the learning curve of
the departure.  One very obvious case is our declaration syntax, which
tends to take more of a Modula-style, keyword-based, left-to-right
approach rather than adopting C’s “inside-out” declaration style.  As
an example, let’s consider the creation of a _skyline array_—an array
of arrays in which the sizes of the inner arrays vary from element to
element of the outer array.  As a particularly simple example, let’s
consider declaring an array of arrays that represents a triangular
index space.  In C, we might declare such an array as follows:

```c
float* tri[n];

for (i=0; i<n; i++) {
  tri[i] = (float*)malloc((i+1)*sizeof(float));
}
```

Using Chapel's declaration syntax, here is how a
similar triangular array could be declared:

```chapel
var A: [i in 1..n] [1..i] real;
```

For those unfamiliar with Chapel, this declaration says “declare a new
variable (`var`) named `A` that is (`:`) an array (`[…]`) over the
index set <small>$1…n$</small>, referring to those indices as `i` for
the remainder of the type expression.  Each element is also an array,
over the index set <small>$1…i$</small>, of real floating point
variables (`real`).  Once you learn to read `:` as “is of type” and
square brackets as array type specifiers, the declaration is fairly
{{<sidenote "right" "easy to understand">}}Regrettably, despite
this support for skyline array types being part of Chapel's syntax
since its inception, it has not yet been implemented.  While Chapel
supports arrays of arrays, like<br> `var A: [1..n] [1..m] real;`,
currently, the inner arrays of such nestings must share the same index
set.  Thus, it is not yet possible to declare array-of-array types in
which the inner array's indices are parameterized based on the outer
array index.  As I'll demonstrate later in this article, there are
workarounds that can be used in the meantime, which further support
the point of this example.{{</sidenote>}}.

So, does this declaration syntax provide any new semantic power over
what we could do in C?  No, in both cases, the result is a fairly
straightforward {{<sidenote "left" "array of arrays">}}A current
colleague, reading this for the first time, asserts that C doesn't
really have proper arrays.  I'd agree with that, both today and when I
wrote the original article, but didn't necessarily want to get into
that debate with C enthusiasts in the original article, so gave it the
benefit of the doubt.{{</sidenote>}}.  Does it require a learning
curve for the C programmer?  Sure.  But the result is something that
is more concise while also arguably being more readable and elegant.
For this reason, we believe that the syntactic divergence from C will
ultimately benefit programmers more than adhering to C would.

These benefits become even more significant when moving to
higher-dimensional and more complex array-of-array data structures.
One of the early computations we studied when designing Chapel was a
Fast Multipole Method (FMM) benchmark that was developed by Boeing for
DARPA’s Data-Intensive Systems (DIS) program of the late 1990’s/early
2000’s [1].  The primary data structure in this mini-application is a
collection of signature functions stored using a hierarchy of 3D
sparse arrays. Each signature function is a 2D discretization of a
spherical function in which the elements are 3-element vectors of
complex values.  In this data structure, the granularity of the 3D
arrays, their sparsity patterns, and the size of the 2D
discretizations all vary based on the level in the hierarchy (and, in
the case of the sparsity patterns, the input dataset).  The
declaration of a hierarchy of signature functions ends up looking as
follows using Chapel’s declaration syntax:

```chapel
var OSgFn: [lvl in 1..nLvls] [SpsCubes[lvl]] [SgFns[lvl]] [1..3] complex;
```

In this declaration, _SpsCubes_ is a 1D array of 3D sparse, strided
_domains_ (index sets) while _SgFns_ is a 1D array of 2D domains—I’ve
omitted these supporting declarations for {{<sidenote "right"
"reasons of space" -4>}}Since space is not as much of a concern in
this reprint series as it was in the original article, I've added the
supporting declarations in the discussion sections that follow this
reprint.{{</sidenote>}}.  Thus, the resulting declaration creates a 1D
array of sparse, strided 3D arrays of 2D arrays of 3-element vectors
of complex values.  I would argue that even a novice Chapel programmer
who reads these declarations could {{<sidenote "right" "easily"
4>}}Hmm, "easily" seems like an overstatement in retrospect—this is by
no means a trivial variable declaration.  But it's definitely far
easier to figure out than the original reference version
was.{{</sidenote>}} figure this out.  In contrast, the C version of
this data structure was based on 1D arrays with lots of indirect
indexing, making the conceptual view of the data structure virtually
incomprehensible.  In fact, I’d wager that if a programmer was handed
both codes and asked to draw the data structure on a whiteboard, that
a beginning Chapel programmer could do so within a few minutes while
expert C programmers would likely require days to reach the same
conclusion from the C version, if they ever could.

As evidence of this conjecture, after writing the FMM computation in
an early draft of Chapel, I showed the code to the Boeing engineer who
co-wrote the C and walked him through it to introduce him to Chapel
and make sure I had captured everything correctly.  It was the first
time he had been exposed to Chapel, and every once in awhile he would
fall silent, clearly thinking about something.  I was worried that he
was having trouble following all of the new concepts and syntax I was
throwing at him.  Instead, when he spoke, he was pointing out bugs
that I had introduced into the algorithm—for example, errors in which
I wasn’t performing the right transformations at the finest levels of
the hierarchy.  In contrast, when he had taught me the FMM computation
a few weeks prior, we used the whiteboard exclusively, never even
bothering to look at the C code because it was so unclear as to not be
the slightest bit illuminating.  Syntax matters.

As one last example, consider the following Chapel expression, which
refers to a subset of an array’s values using a slicing operator:

```chapel
A[2..n-1, j..]
```

This expression evaluates to a sub-array of _A_’s values, from rows 2
through _n_–1 and columns _j_ through _A_’s upper bound.  Consider
writing the same expression using a class library-based approach in
C++:

```c
A.slice(new Range(2, n-1), new HalfBoundedRange(j, LOWER))
```

Again, these two expressions are semantically equivalent, but I would
argue that syntactic support for ranges, multidimensional arrays, and
slicing results in a far more productive expression than a more
minimalist OOP design.  An expert C++ programmer could potentially
utilize more advanced operator overloading and macros to make this
expression less verbose and more concise but, as I argued in [article
1]({{< relref 10myths-part1 >}}#the-original-article-reprinted),
exposing these concepts in the language syntax and semantics benefits
not only the programmer and readers, but also the compiler’s ability
to analyze and optimize the program.

   {{<quote person="Benjamin Lee Whorf">}}
“Language shapes the way we think, and determines what we think about.”
{{</quote>}}

Though Benjamin Lee Whorf was a linguist who studied human, rather
than computational, languages, I believe that his conjecture applies
to programming as well as natural languages.  In particular, I would
argue that a programming language with improved syntax (and semantics)
permits users to spend more time working on the computations that they
are writing and {{<sidenote "right" "the problems they are solving">}}
I think our [recent interview with Scott Bachman]({{<relref
7qs-bachman>}})) is a good example of this principle.  He talks about
how, in translating his computation from Matlab to Chapel, he obtained
a 10,000x speedup, noting that some of this was algorithmic and
enabled by Chapel.{{</sidenote>}} rather than on lower-level details
that can be abstracted by languages and implemented by compilers.

#### Counterpoint #4: Syntax does matter and can greatly impact a programmer’s productivity and creativity in a language as well as their ability to read, maintain, and modify code written in that language.

Tune in next time for more myths about scalable parallel programming
languages.

#### Bibliography

[1] Atlantic Aerospace Electronics Corp., [Data-Intensive Benchmark
Suite: Analysis and Specification (version
1.0)](http://www.ai.mit.edu/projects/aries/Documents/DIS_Benchmarks_v1.pdf),
June 1999.


---

### Reflections on the Original Article


#### Syntax and Scalable Parallel Computing

Re-reading this article today, it's interesting to me that the
examples I focused on when arguing that syntax matters dealt only with
patterns that were largely independent of the scalable parallel
computing context for which Chapel was originally developed.  Perhaps
this was due to the fact that scalable parallel computing is
traditionally done in languages like Fortran, C, and C++ using
libraries like MPI or directive-based approaches like OpenMP to
express the parallelism and locality considerations required at scale.
And since those languages were traditionally sequential and
constrained to a single process, perhaps focusing only on local
computations made sense to me at the time.

However, if we think of common `notations for scalable parallel
computing—like MPI or OpenMP—as being pseudo-languages in and of
themselves, then perhaps I should've also compared Chapel's syntax to
the library calls and directives used in such systems.

Googling "hybrid MPI OpenMP hello world", the first hit I get is the
following program by Joseph Steinberg at [Stack
Overflow](https://mpitutorial.com/tutorials/mpi-hello-world/):

{{< file_download fname=hello.c lang="c" >}}

Contrast it with the equivalent Chapel program:

{{< file_download fname=hello.chpl lang="chapel" >}}

The Chapel program is notably shorter and arguably easier to read by
virtue of it being a language designed for parallel computing and
scalability.  Specifically, syntactic elements like `here` to refer to
the locale (system resources) on which we're currently running,
`coforall` loops to create parallel tasks, and `on` clauses to specify
where tasks should execute result in a much more succinct expression
of the computation.

In addition, the Chapel program's syntax is subtly benefitting from
its post-SPMD programming model by having the program start as a
single task running on locale 0 rather than requiring the programmer
to write a `main()` procedure that is intended to be run once per
process.  It's also benefitting from Chapel's support of a global
address space, by having arbitrary locales write to a single console
output stream associated with locale 0.  Such benefits would become
even more apparent for a more complex program that did any sort of
data transfer between the distinct processes executing the MPI or
Chapel program.

Similar comparisons could be made between Chapel and other HPC
programming notations like CUDA, HIP, SYCL, Kokkos, etc., but that
would warrant an entire article of its own.  Suffice it to say that I
believe that when a language contains features and syntax in support
of specifying parallelism and locality, it will benefit programmers
who are trying to express parallel computations at scale, whether
simple or complex.


#### Skyline Array Examples

As mentioned in the sidebar above, the original article's initial
examples illustrating how Chapel's left-to-right declaration syntax
supports intuitive skyline arrays, rely on a Chapel feature that has
not been implemented to date, in which an inner array's indices can be
parameterized using the index of an outer array.

In practice, when users need this ability in Chapel as it stands
today, they often wrap the inner arrays in a record which acts
array-like.  Here's a very simple example of how this can be done to
create the triangular array atype from the original article:

{{< file_download fname=skyline-record.chpl lang="chapel" >}}

Even though such workarounds

are sufficient, it's regrettable to me that we haven't yet implemented
the ability to declare `A` as `var A: [i in 1..n] [1..i] real;`,
obviating the need for such helper records.  While this current lack
of support undermines the practicality of the original article's point
("Look how easy it is to declare skyline arrays in Chapel!"), the
workaround also emphasizes the article's argument—that better syntax
can support the pattern more directly and attractively.  {{<sidenote
"right" "directly and attractively">}}Current Chapel programmers
needing skyline arrays should also note that Chapel currently supports
the ability to create certain skyline arrays in type-inferred
settings.  For example, [this program](code/skyline-value.chpl) writes
the triangular array example using this approach.{{</sidenote>}}.

For the more complex Fast Multipole Method example, here are the
supporting declarations for the `OSgFn` variable that I omitted from
the original article due to space constraints:

```chapel
// the number of levels in the FMM hierarchy and the size of the finest level
config const nLvls = 10,
             n = 1024;

// arrays of domains representing the dense problem space at each level of the
// hierarchy and the sparse subset of elements from that level that we'll compute on
const DnsCubes = [lvl in 1..nLvls] {1..n, 1..n, 1..n} by 2**lvl,
      SpsCubes:  [lvl in 1..nLvls] sparse subdomain(DnsCubes[lvl])
              = computeSpsElts(lvl);

// an array of domains representing the discretization of the signature function
// at each level of the hierarchy
const SgFns = [lvl in 1..nLvls] {1..sgFnSize(lvl), 1..2*sgFnSize(lvl)};

// the array representing the complete set of outer signature functions:
// - a 1D array over the levels of the hierarchy
// - of sparse 3D arrays representing the elements at that level
// - of dense 2D arrays representing an element's discretized signature function
// - of 3-element vectors
// - of complex values
var OSgFn: [lvl in 1..nLvls] [SpsCubes[lvl]] [SgFns[lvl]] [1..3] complex;
```

Note that in this code, only the declarations of `SpsCubes` and
`OSgFn` are unsupported in Chapel today since they are the only cases
that rely on using an array type's indices to parameterize its
elements' indices.


#### Wrapping Up

That concludes this month's myth about whether syntax matters when
designing scalable parallel programming languages, where I believe
that it does matter and can significantly improve how clearly a
program is expressed and how programmers think about their code.  Next
month, we'll revisit the fifth article in this series, which addresses
the concept that productive languages require a magic compiler.  See
you then!
