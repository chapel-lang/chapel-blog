---
title: "10 Myths About Scalable Parallel Programming Languages (Redux),  Part 1: Productivity and Performance"
richtitle: "10 Myths About Scalable Parallel Programming Languages (Redux)<br>  Part 1: Productivity and Performance"
date: 2025-04-30
tags: ["Editorial", "Archival Posts / Reprints", "Sparse Arrays"]
series: ["10 Myths About Scalable Parallel Programming Languages Redux"]
summary: "An archival post from the IEEE TCSC blog in 2012, with a current reflection on it"
authors: ["Brad Chamberlain"]
---

### Introduction to this Series

In March 2012, I was invited by Yong Chen, who at that time was the
Newsletter Editor for the IEEE Technical Community on Scalable
Computing (TCSC), to write a short post about Chapel to be published
on the organization's blog.  In considering the invitation, I came up
with a theme that I liked, which was to address a number of skeptical
reactions about developing new programming languages for
high-performance computing (HPC) that our team frequently encountered,
and that I felt were off-base.  The idea was to push back on those
assertions and offer a counter-narrative.  I came up with an initial
list of such attitudes, named the article "Myths about Scalable
Parallel Programming Languages", and started writing.

However, as is often the case, I drastically underestimated how
succinctly I could make my points.  By the time I'd addressed the
first myth, I'd already exhausted my word count budget.  As a result,
the original article turned into a series of eight that were published
between April and November of 2012 and ended up addressing ten myths.
I don't recall whether I had any sense of how large the series'
audience was, but I did receive appreciative comments from readers and
IEEE leadership.

Over time, the IEEE TCSC blog fell into disrepair, and with it, the
series {{< sidenote "right" "became unavailable to the public" >}}
Well, almost.  In writing this, I've learned that 7/8 of the series
[can be found](https://web.archive.org/web/20160308062654/https://www.ieeetcsc.org/activities/blog/myths_about_scalable_parallel_programming_languages_part1) on the [Internet
Archive Wayback Machine](https://web.archive.org/).{{< /sidenote >}}.  Ever since we launched
this blog for Chapel, I've thought about re-publishing the original
series here for archival purposes, while also taking the opportunity
to consider how well or poorly it has held up over time.  Would our
current team still agree with my original arguments?  Has Chapel now
demonstrated things that I was only speculating about at the time?
Can I even bear to re-read my own writing?  After recently noting that
the 13-year anniversary of the first article was approaching, I
decided that this was as good a time as any to begin.

To that end, welcome to _10 Myths About Scalable Parallel Programming
Languages (Redux)_, a new series that will re-publish the original
articles along with commentary that provides a current perspective on
the material.  In reproducing this series, I am striving to keep the
content as similar as possible to what was originally published on the
IEEE TCSC blog, updated to use the Chapel blog's formatting
conventions.  Along the way, I intend to fix any typographical issues,
and to update broken hyperlinks to refer to a file's current location
or a reasonable modern-day equivalent.  Most importantly, I'll
decorate the original articles with side-notes, detail sections, and
a closing discussion to capture some current thoughts and updates.

In kicking off this endeavor, I'd like to thank Yong Chen, Pavan
Balaji, Xian-He Sun, and IEEE TCSC for providing the motivation and
platform that enabled me to write the original series.

And with that introduction, here is the first article from the series,
originally published on April 30, 2012:

---

### The Original Article, Reprinted

Myths About Scalable Parallel Programming Languages:<br>
Part 1: Productivity and Performance
{.big}




I work on a language designed for scalable computing named Chapel.
For readers unfamiliar with it, Chapel is an emerging parallel
programming language whose design and development are being led by {{<
sidenote "right" "Cray Inc." -3 >}}(and now by Hewlett Packard
Enterprise){{< /sidenote >}} (https://chapel-lang.org) as part of the
[DARPA High Productivity Computing Systems program
(HPCS)](https://www.nitrd.gov/nitrdgroups/images/a/a2/High_Productivity_Computing_Systemsl_DARPA.pdf).

Chapel has the goal of improving the productivity of parallel
programmers, particularly those interested in large-scale computing.
Much has been written previously about Chapel’s motivations, themes,
features, and history [1, 2, 3], including descriptions of some of its
more advanced concepts [4, 5].  For those hearing about Chapel for the
first time but not ready to track down previous work, some terms to
give you a feel for its design include: “general-purpose parallelism”,
“open-source”, “portable”, "{{< sidenote "right" "dynamic" -8 >}}I
can't quite recall why I chose this adjective, as it's not one I would
naturally reach for today.  My best guess is that I meant that Chapel
supports dynamic parallelism—the arbitrary creation of new tasks by
other tasks.  However, it seems like I could've made that clearer to
avoid potential confusion with "dynamically typed", which Chapel is
not.{{< /sidenote >}}", “locality-aware”, “elegant”,
“work-in-progress”, “customizable”, “multiresolution”, and (keeping in
mind that I’m biased) "{{< sidenote "right" "it rocks!" 9 >}}The
article I originally submitted ended this list with "kick-ass."
instead, but my editors seemed to think that this might be too profane
for IEEE.  For similar reasons, we ended up dropping some hip-hop
lyrics that I originally used to kick off the article (the lyrics
themselves were not profane, but others in the song were).  {{<
/sidenote >}}"

Because most computer scientists use programming languages of one form
or another, we tend to have strong opinions about them: we complain
about the languages we hate; we vacillate between championing and
complaining about the ones we like; and we argue endlessly about why
every new language is doomed to failure.  Despite this general
atmosphere of pessimism around new languages, many of us have a desire
to move beyond today’s hodge-podge of parallel languages and
notations.  Sometimes this is motivated by a lack in productivity or
capability; other times by the challenges posed by next-generation
processor architectures; sometimes we just want parallel programming
to be as nice as desktop programming. But whatever the reasons, and
however long the odds, we feel there is a need to continue striving to
improve the state of the art in scalable parallel languages.

In this series of blog articles (of which this is the first), rather
than rehash aspects of Chapel that are well-covered elsewhere, I
thought I’d cover some of the myths about scalable parallel
programming languages that our team frequently encounters and counter
them based on our experiences with Chapel and other parallel
languages.


#### Myth #1: Productivity is at odds with performance

When most people hear that we are working on a language designed with
productivity as its goal, they assume that performance will be
sacrificed—that raising the level of abstraction will necessarily hurt
performance.  And there certainly is precedent for this opinion.

For starters, the very wording of this statement bothers me because it
suggests that the term “productivity” somehow does not encompass
performance.  If we think of productivity as being related to “time to
solution” (or “solutions”), then for most use cases, performance
really needs to be part of the definition.  In the specific case of
Chapel, the HPCS program at its outset defined productivity to include
performance, combined with programmability, portability, and
robustness.  To that end, in designing Chapel, we worked very hard to
select high-level features that we believed would help performance, or
at least not hurt it.  (Full disclosure: it should be mentioned that
in many cases, {{< sidenote "right" "today’s Chapel compiler" -13 >}}
Happily, the performance generated by the Chapel compiler today is in
_much_ better shape than when this article was originally
published.  Chapel frequently [competes with](https://chapel-lang.org/fast/) typical C, C++, and
Fortran programs; it has [scaled](https://chapel-lang.org/scalable/) to thousands of compute
nodes, millions of cores, and over a thousand GPUs; and it has even
out-scaled MPI and SHMEM for specific parallel computations and
architectures.  Importantly, all of these results have relied on its [productive features](https://chapel-lang.org/productive/).
All that said, there is still plenty of room for further improvement,
particularly as hardware itself is always improving and changing. {{<
/sidenote >}} does not yet produce the performance that it was
designed to; recall the “work-in-progress” mention above).

{{< pullquote >}}

The more clearly a programmer’s intentions can be described in a
language, the more semantic information the compiler has available
when optimizing the code

{{< /pullquote >}}


Consider that one of the main goals of a programming language is to
permit users to communicate algorithms to a compiler (or interpreter)
such that they can be implemented on the target hardware, correctly
and efficiently.  This means that the more clearly a programmer’s
intentions can be described in a language, the more {{< sidenote "left"
"semantic information the compiler has available when optimizing the code" >}}Stay
tuned... We'll call out examples of such optimizations that we've
implemented in Chapel since the original article was written in the
discussion section at the end.{{< /sidenote >}}.  For that reason, a
productivity-oriented language designer should select concepts and
abstractions that will aid the compiler’s analysis and optimization
(or at least do no harm), rather than ones that would handicap it.

###### Enabling optimization through improved abstractions

As an example, consider sparse matrix computations, such as the very
simple operation of assigning a sparse matrix to a dense one.  As a
compiler writer, there are a number of interesting optimizations that
I can apply to such operations—such as using _loop splitting_ to
specialize zippered operations like this assignment—to take advantage
of the semantic knowledge that large portions of the iteration space
will contain identical (“zero”) values.  Yet if the compiler doesn’t
know about the sparse arrays, it cannot apply these optimizations.

Consider implementing the sparse matrix of this example using the
[Compressed Sparse
Row](https://en.wikipedia.org/wiki/Sparse_matrix#Compressed_sparse_row_(CSR,_CRS_or_Yale_format))
storage format.  When using C or Fortran, programmers will typically
use 1D arrays to store the nonzero values, column indices, and row
start values.  They will also typically index into these arrays using
values stored in the other ones.  This is a pattern known as _indirect
indexing_, and it poses significant challenges to compiler
optimization.  By using these low-level concepts, the programmer has
failed to express important semantic information about the array
values that could be used to optimize the scalar code—such as the fact
that the row start indices will refer to disjoint subsets of the
column index and value arrays.  Worse, the code fails to impart to the
compiler—not to mention human readers—any clear indication that a
sparse array is being used.

{{< details summary="**(What does CSR and indirect indexing look like?)**" >}}

I must have been taking my word-count budget very literally when
writing this original article because I think the above paragraph
screams for a code illustration.  Here's how a typical CSR
implementation might be represented, using Chapel syntax:

```chapel
config const numRows = ...,       // the logical number of rows in the matrix
             numCols = ...,       // the logical number of columns
             numNonzeroes = ...;  // the total number of non-zero entries

config type eltType = real;       // the type of the non-zero entries

// a dense vector storing the non-zero matrix elements
var nonzeroes: [1..numNonzeroes] eltType;

const rowStart: [1..numRows+1] int = ...,   // the index where each row starts
      colIdx: [1..numNonzeroes] int = ...;  // the column index of each nonzero
```

And here's how a typical serial loop over the data structure might
look, say to set all of the non-zero elements to a function of their
row and column indices:

```chapel
for r in 1..numRows do
  for i in rowStart[r]..<rowStart[r+1] do
    nonzeroes[i] = r*1000 + colIdx[i];
```

The indirect indexing that the original article mentions appears in
this example by virtue of the fact that the `i` index used to access
the `nonzeroes` and `colIdx` arrays comes from an array itself, making
it difficult, if not impossible, for a compiler to reason about.

That said, reading this article 13 years later, my inner critic notes
that languages that support explicit parallelism can still help the
compiler accelerate the code even without it having an understanding
of the relationship between `rowStart`, `nonzeroes`, and `colIdx`.
Specifically, writing the loop nest above using parallel loops doesn't
tell the compiler that the `i` loops will be consecutive and disjoint,
but it does indicate that they can and should be executed in parallel:

```chapel
forall r in 1..numRows do
  forall i in rowStart[r]..<rowStart[r+1] do
    nonzeroes[i] = r*1000 + colIdx[i];
```

At the same time, I still strongly believe that an explicit
representation of sparsity in a language improves productivity, as
we'll see in the next details section.

{{< /details >}}

A C++ or Java programmer would probably take the raw arrays and loop
patterns above and wrap them in a class in order to abstract the
underlying data structures away from their uses, providing a cleaner
interface for accessing and iterating over the sparse array.  With
good naming choices, this OOP-based approach can go a long way toward
making the code more programmable and comprehensible to a human
reader.  Yet for the compiler, it does little to help, and often
hurts, by adding more code framework to sort through in analyzing the
computation (including the potential for dynamic dispatch issues if
the class is part of a larger matrix class hierarchy).  Such examples
of higher-level programming are arguably a large part of why the HPC
community tends to conflate productivity with poor performance.

{{< pullquote >}}

The end-user gets improved programmability while the compiler gets
more semantic information to use in performance optimizations—a
win-win situation.

{{< /pullquote >}}

Now, imagine a language that supports sparse matrices or arrays
directly, like Matlab, ZPL, or Chapel.  Such languages provide similar
productivity benefits to the user as the OOP approach, and often
improve upon it, due to the opportunity to support a specialized
syntax.  They also hand the compiler a nice piece of semantic
information: _This array has a nontrivial number of identical entries._
As a result, your favorite compiler team can shift their focus from
heroically wrestling with optimizing indirect indices and unraveling
method calls toward issues that are more closely related to the
semantics that the programmer wanted to express anyway.  Thus, the
end-user gets improved programmability while the compiler gets more
semantic information to use in performance optimizations—a win-win
situation.

{{< details summary="**(What do Chapel's sparse features look like?)**" >}}

Here is the computation from the previous details section written
using Chapel's sparse features:

```chapel
config const numRows = ...,       // the logical number of rows in the matrix
             numCols = ...,       // the logical number of columns
             numNonzeroes = ...;  // the total number of non-zero entries

config type eltType = real;       // the type of the non-zero entries

// the logical and sparse indices representing the matrix
const Dom = {1..numRows, 1..numCols},
      SpsDom: sparse subdomain(Dom) = ...;

var SpsMat: [SpsDom] eltType;  // the sparse matrix itself

forall (r,c) in SpsDom do
  SpsMat[r,c] = r*1000 + c;
```

{{< /details >}}

###### Performance-Neutral Productivity Features

In other cases, productivity features can be completely neutral with
respect to execution performance.  As an example, Chapel supports
static type inference, which permits users to optionally elide the
types of variables, as well as function arguments and return types.
The compiler analyzes the program to determine the types in such
cases.  This feature permits programmers to prototype algorithms more
quickly, while also making them more flexible with respect to type
changes over time.  As an example, the following two Chapel programs
are equivalent:

**Listing 1: Inferred types**

{{< subfile fname="inferred.chpl" lang="chapel" lstart=1 lstop=6 >}}

**Listing 2: Specified types**

{{< subfile fname="specified.chpl" lang="chapel" lstart=1 lstop=6 >}}


Depending on personal preference, you might consider either code to be
more productive than the other.  The code in Listing 1 is arguably
easier to write, but could be considered more difficult to read since
the declarations don’t explicitly name their types.  As a result, a
human reader must perform the same inference steps that the compiler
would in order to determine that `pi` and `pi2` are `real` floating
point values, and that `square()` takes and returns `real` values (for
this callsite, anyway).  Meanwhile, the version in Listing 2 makes the
types clearer, but would require more work to change if the user
wanted to move from 64-bit `real`s to a different bit-width or type
(such as complex values).

Users may initially fear that the inferred types of Listing 1 make it
expensive. The type-free code resembles a scripting language,
suggesting that Chapel might use dynamic types with their
corresponding execution-time overheads.  But each Chapel variable has
a single fixed type for its lifetime, which is determined at
compile-time.  This means there is no execution-time overhead compared
to the version in Listing 2 or a traditional compiled language like C
or Fortran.

Many other Chapel features have similar productivity benefits without
imposing execution-time costs, such as its support for inlined
iterator functions.  Such features make code authoring and maintenance
far more productive and flexible without resulting in an
implementation that differs from what a programmer would get in a
traditional language.

This leads us to our conclusion:

##### Counterpoint #1: A smart selection of language features can improve programmer productivity while also having positive or neutral impacts on performance.

Tune in next time for more myths about scalable parallel programming languages.


#### References

[1] B. L. Chamberlain, D. Callahan, H. P. Zima, [Parallel
Programmability and the Chapel
Language](https://hpc.sagepub.com/content/21/3/291.abstract),
_International Journal of High Performance Computing Applications_,
August 2007, 21(3): 291–312.

[2] Chapel Team, Cray Inc., [Chapel Language Specification (version
0.91)](https://chapel-lang.org/spec/spec-0.91.pdf), {{< sidenote
"right" "April 19, 2012" >}}A current version of the language spec can
be found [here](https://chapel-lang.org/docs/language/spec/){{< /sidenote >}}.

[3] B. L. Chamberlain, [Chapel (Cray Inc. HPCS
Language)](https://link.springer.com/referenceworkentry/10.1007/978-0-387-09766-4_54),
_Encyclopedia of Parallel Computing_, David Padua (editor), pp. 249–256,
Springer US, 2011.

[4] B. L. Chamberlain, S.-E. Choi, S. J. Deitz, A. Navarro,
[User-Defined Parallel Zippered Iterators in
Chapel](http://pgas11.rice.edu/papers/ChamberlainEtAl-Chapel-Iterators-PGAS11.pdf),
_PGAS 2011: Fifth Conference on Partitioned Global Address Space
Programming Models_, October 2011.

[5] B. L. Chamberlain, S.-E. Choi, S. J. Deitz, D. Iten, V. Litvinov,
[Authoring User-Defined Domain Maps in
Chapel](https://chapel-lang.org/publications/cug11-final.pdf), _CUG
2011_, May 2011.


#### Acknowledgments

Thanks to the members of the Chapel team, past and present, for the
many interesting discussions that have helped inform this article’s
contents.  This material is based upon work supported by the Defense
Advanced Research Projects Agency under its Agreement
No. HR0011-07-9-0001. Any opinions, findings and conclusions or
recommendations expressed in this material are those of the author and
do not necessarily reflect the views of the Defense Advanced Research
Projects Agency.

---

### Reflections on the Original Article

By and large, I think that the premise of this first article in the
"10 myths" series holds up.  I definitely still believe that
thoughtful, intelligent curation of features can result in a
programming language that is easier for humans to read and write,
while also enabling good performance and simplifying performance
optimizations.

#### The Sparse Example

Ironically, despite this article's partial focus on optimizing sparse
matrix computations, that set of features has not received as much
attention in Chapel's implementation and optimization efforts as I had
probably been anticipating they would in 2012.  Specifically, some of
our key focus areas since then have been on improving traditional
sequential language features such as OOP, optimizing performance and
scalability for dense computations, targeting GPUs, and modernizing
our compiler.  Meanwhile the sparse subset of the language has largely
been neglected.  However, I was happy to have the opportunity to make
some improvements to the sparse support [in the past
year](https://chapel-lang.org/blog/posts/announcing-chapel-2.3/#sparse-computations),
and hope to do more going forward.

Curious about the status of the specific example of sparse-to-dense
assignment mentioned in the article, I found that while we do not
support this pattern today, I was able to add support for it in a
subroutine whose body is two lines of Chapel code as:

{{< subfile fname="assign-sparse-to-dense.chpl" lang="chapel" lstart=63 lstop=64 >}}

Then, to implement the loop-splitting optimization mentioned above, I
changed it into the following pair of lines that assigns `A` the {{<
sidenote "right" "\"zero\"" >}}Chapel's sparse matrices support
arbitrary "zero" values, so we call this value the _IRV_, or
_implicitly replicated value_ for short in Chapel to avoid any
implication that it needs to have the value "0".{{< /sidenote >}}
values first, followed by a loop that only copies over the non-zero
elements:

{{< subfile fname="assign-sparse-to-dense.chpl" lang="chapel" lstart=66 lstop=68 >}}

This rewrite has the benefit of avoiding $O(n^2)$ sparse random access
operations, which are expensive by nature.  On my M1 Mac, this
resulted in a ~3x improvement when assigning a 100,000 x 100,000
tridiagonal sparse matrix and a ~24x improvement for a 10,000 x 10,000
case.  Now I need to follow up by opening a PR that adds this as an
official assignment operator between sparse and dense arrays.  In the
meantime, my full code can be seen here:

{{< file_download_min fname="assign-sparse-to-dense.chpl" lang="chpl" >}}


Despite our lack of focus on sparse computations since the original
article, we _have_ implemented several other compiler optimizations in
the intervening years that have benefited from Chapel's high-level
representation of things like parallelism and index sets.  Key
examples include a compiler optimization for unordered/asynchronous
operations within `forall` loops (see 'Unordered Compiler
Optimizations' in [the release notes for Chapel
1.19](https://chapel-lang.org/releaseNotes/1.19/05-benchmark-opts.pdf))
and [a pair of
optimizations](https://link.springer.com/chapter/10.1007/978-3-030-99372-6_1)
for reducing overheads when computing with distributed arrays.

#### The Type Inference Example

I was pleased to find that the examples demonstrating type inference
from the original article continue to work today without changes,
though I was somewhat amused by my imprecise representation of $\pi$.
Re-reading today, I do wonder how many modern programmers would find
the explicitly-typed version "clearer", as I suggested back then,
particularly given the continued growth in popularity of Python and
uptake of `auto` declarations in C++.  In retrospect, maybe I
should've used other characterizations of why it might be considered
more productive, like being more precise or less prone to errors.  For
example, `square("pi");` would have unintended consequences in the
type-inferred case, since `*` isn't supported between strings by
default.

In retrospect, it also seems a bit pedantic that I used `real(64)` as
the type in the explicit version rather than `real`, which is defined
to be 64 bits in Chapel—almost like I was trying to go out of my way
to make it more verbose.  That said, I can also think of users who
tend to prefer that additional level of explicitness in their code.

### Wrapping Up

All in all, I think the premise of the original article holds up and
that, by and large, the features we had designed for Chapel in 2012
have largely stood the test of time in terms of providing the
programmability and support for performance and optimization that we
intended.  Specifically, [users have indicated their appreciation of
many of Chapel's features]({{< relref
"series/7-questions-for-chapel-users" >}}), and I have a hard time
thinking of any of its unique ones that feel inherently problematic
from the perspective of obtaining performance.

Tune in next month when we'll revisit the second article in this
series, which wrestles with the question of what past parallel
language failures imply for future attempts.

