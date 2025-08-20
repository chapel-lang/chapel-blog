---
title: "10 Myths About Scalable Parallel Programming Languages (Redux),  Part 5: Productivity and Magic Compilers"
date: 2025-08-20
tags: ["Editorial", "Archival Posts / Reprints"]
series: ["10 Myths About Scalable Parallel Programming Languages Redux"]
summary: "The fifth archival post from the 2012 IEEE TCSC blog series with a current reflection on it"
authors: ["Brad Chamberlain"]
---

### Background

In 2012, I wrote a series of eight blog posts entitled "Myths About
Scalable Parallel Programming Languages" for the IEEE Technical
Community on Scalable Computing&nbsp;(TCSC).  In it, I described
discouraging attitudes that our team encountered when talking about
developing Chapel and then gave my personal rebuttals to them.  That
series has generally been unavailable for many years, so for its 13th
anniversary, we're reprinting the original series here on the Chapel
blog, along with new commentary about how well or poorly the ideas
have held up over time.  For a more detailed introduction to both the
original series and these reprints, please see [the first article]({{<
relref 10myths-part1 >}}) in this series.


This month, we're reprinting the fifth article in the original
series, originally published on<br>August 20, 2012.  Comments in the
sidebar and in [the sections that follow the reprint]({{<relref
"#reflections-on-the-original-article">}}) contain current thoughts
and reflections on it.


---

### The Original Article, Reprinted

Myths About Scalable Parallel Programming Languages:<br>
Part 5: Productivity and Magic Compilers
{.big}

This is the fifth in a series of blog articles that I’m writing with
the goal of recounting and responding to some of the misconceptions
about scalable parallel programming languages that our team encounters
when describing our work designing and implementing Chapel
(https://chapel-lang.org).

For more background on Chapel or this series of articles, please refer
to [part 1]({{< relref 10myths-part1
>}}#the-original-article-reprinted); subsequent myths are covered in
parts [2]({{< relref 10myths-part2
>}}#the-original-article-reprinted), [3]({{< relref 10myths-part3
>}}#the-original-article-reprinted), and [4]({{< relref 10myths-part4
>}}#the-original-article-reprinted).

#### Myth #5: Productive Languages Require Magic Compilers.

This article was originally planned as myth #6, using a slightly
different description.  However, comments along these lines came up a
few times {{<sidenote "right" "at a workshop last week">}}Checking the
archives, it looks like this was a DOE exascale workshop named
_Productive Programming Models for Exascale_, held in
Portland.{{</sidenote>}}, so I thought I’d tackle the topic while it’s
fresh in my mind.

To start out, I believe that the term “magic compiler” is fairly cheap
and tacky; a term that’s best avoided in technical conversations.
Most people in the scientific community don’t actually believe in
magic, so suggesting that when it comes to compilers you do—or that
your adversary does—seems pointlessly insulting (which, I suppose, is
arguably the point).  If you’re on the defending side of such a
conversation and want to stoop to a similar level, you can always
point out that many primitive cultures have described that which they
cannot understand as “magic”, and leave it at that.  However, if you
want to elevate the level of discourse, an arguably better term to use
in such contexts is _heroic compilation_—essentially suggesting that
the compiler must go above and beyond the reasonable call of duty to
make a program work well, or perhaps even work at all.

The scalable computing community is probably overly sensitive about
magic compilers/heroic compilation due, in large part, to the failure
of High Performance Fortran (HPF—see [myth #2]({{< relref
10myths-part2 >}}#the-original-article-reprinted)).  HPF was a
particularly challenging language to compile and optimize for
distributed memory machines due to the compiler’s role in identifying
and implementing all communication.  And Chapel arguably has
{{<sidenote "right" "similar challenges ahead of it">}}All these years
later, I'd say that many of these challenges have been met, and that
we've demonstrated how Chapel's design effectively supports the
ability to reason about and optimize communication far better than HPF
did (see [this
paper](https://link.springer.com/chapter/10.1007/978-3-030-99372-6_1)
for some examples).  That said, there are always additional
optimizations to implement, to make the compiler better and save user
effort.{{</sidenote>}}.  However, I would argue that Chapel’s design
is far less dependent on heroic compilation than HPF’s was.


###### High-level Concepts vs. Low-level Control

Before last week’s workshop, my original phrasing for this myth was
going to be “High-level languages unnecessarily tie a programmer’s
hands.”  Like the heroic compilation issue above, this also referred
to HPF.  Specifically, when HPF’s compiler and abstractions failed the
programmer, there was little recourse available other than abandoning
the language.  Such situations can leave users feeling as though their
hands are tied; the high-level language’s abstractions can be helpful
when they work, but they can also end up being overly restrictive when
they don’t.

{{<pullquote>}}
When Chapel's high-level features fail you—whether due to performance
issues or lack of sufficient control for your computation—you can drop
down to the lower-level features as a sort of manual override.
{{</pullquote>}}

I believe that good language design can go a long way toward
addressing both concerns in a productive language—reducing reliance on
heroic compilation while also providing the ability to escape the
higher-level abstractions provided by a language.  In Chapel, our
design follows something we refer to as our _multiresolution
philosophy_ [[1]({{<relref "#bibliography">}})].  The idea is that
rather than supporting only high- or low-level features, Chapel
provides a spectrum of features, some higher-level and more abstract;
others lower-level and more explicit or control-oriented.  Moreover,
Chapel is architected in a layered manner such that higher-level
features are implemented in terms of the lower-level ones.  In this
way, when the high-level features fail you—whether due to performance
issues or lack of sufficient control for your computation—you can
drop down to the lower-level features as a sort of manual override.


As an example, Chapel supports _global arrays_, which support
high-level operations like `forall` loops and promoted operators.
These are examples of Chapel’s data-parallel features, which are
provided to help with programmability and ease-of-use.  All of these
data-parallel features are implemented within the language itself,
using lower-level Chapel features like task-parallelism, locality
control, and base language features such as classes, tuples, and
iterators.  This approach has a few important implications: First,
because both high- and low-level features are implemented using the
same core concepts, it means that they are directly compatible with
one another, permitting users to switch between high- and low-level
features {{<sidenote "right" "as required" -17>}}The
[Arkouda](https://arkouda-www.github.io/) framework for interactive
HPC-scale computing in Python is a Chapel application that
demonstrates this characteristic.  Most of its operations are able to
use high-level, whole-array operations and `forall` loops; but more
complex and time-critical operations—like its custom radix sort
routine—make use of lower-level SPMD-style parallelism and
asynchronous tasking.  More broadly, different Chapel applications have
contained distinct mixes of higher- and lower-level features depending
on their needs.{{</sidenote>}}.  Second, it provides users with the
ability to create their own high-level abstractions in the event that
the language designers {{<sidenote "left"
"didn't anticipate their precise needs" -15>}}Arkouda serves as an example
of this principle as well.  Its initial sort routine induced far too
much fine-grained communication, hurting its overall performance.  To
remedy this, a data aggregator abstraction was written using ~100
lines of Chapel to amortize communication overheads and improve
performance and scalability.  That abstraction has since been promoted
to Chapel's
[CopyAggregation](https://chapel-lang.org/docs/modules/packages/CopyAggregation.html)
package module for others to use.

A second example can be seen in the work done by Akihiro Hayashi et
al. at Georgia Tech to [target GPUs using Chapel
programs](https://chapel-lang.org/CHIUW/2021/Hayashi.pdf) before the
Chapel compiler's [native GPU support]({{<relref
"series/gpu-programming-in-chapel">}}) was completed.  They were able
to achieve this by defining custom iterators and array types with no
modifications to the language or compiler.{{</sidenote>}}.  In Chapel,
this gives the user the ability to define new ways of laying out array
elements in memory or distributing them across
locales [[2, 3]({{<relref "#bibliography">}})]; it also permits users
to define their own custom parallel iterators that determine how many
tasks to use when implementing forall loops, as well as how iterations
should be divided between those tasks [[4]({{<relref
"#bibliography">}})].


###### Multiresolution Languages and Heroic Compilation

Returning to this month’s myth, Chapel’s multiresolution philosophy is
also why I would argue that it relies less on heroic compilation than
HPF.  In HPF, when the compiler failed programmers, they would likely
need to abandon the language.  In Chapel, when the compiler fails you,
you can always abandon the high-level abstractions you were using and
write the code {{<sidenote "right" "using Chapel’s lower levels"
-11>}}Note that these lower-level details can often be wrapped in new
high-level abstractions so that their uses remain clean and readable.
Both the Arkouda aggregators and Georgia Tech GPU work mentioned above
were examples of this.{{</sidenote>}}; in the limit, this can even
include returning to SPMD-style programming and message passing, if
that’s what’s required.  Of course if all you ever want is SPMD
execution and message passing, Chapel has {{<sidenote "right"
"little to offer over MPI">}}This statement doesn't hold up for me
today, if it ever did.  The [CHAMPS]({{<relref 7qs-laurendeau>}})
framework for unstructured computational fluid dynamics is an example
of an SPMD MPI-style Chapel application whose authors felt they got
great benefit by expressing inter-node transfers using array copies
rather than message passing calls.  I also think that many programmers
like the CHAMPS team and [Professor Nelson Luis Diaz]({{<relref
7qs-dias>}}) consider Chapel's base language features to be a
significant improvement over C++—i.e., that having "a more programmable base
language" is nothing to sniff at.  {{</sidenote>}} other than a more
programmable base language.  That said, by also providing higher-level
alternatives, Chapel supports the 90/10 rule: if 90% of your execution
time is spent in 10% of your code, your overall time to solution might
benefit greatly by writing {{<sidenote "left"
"the other 90% of your code">}}Happily, in practice, most Chapel
applications to date have been able to write the 10%
performance-critical sections in Chapel as well.  So while this
argument provides peace-of-mind, few applications have had to rely on
it.{{</sidenote>}} in a productive, high-level language rather than a
low-level unproductive one.

{{<pullquote>}}

If we never create languages that support distributed memory
parallelism, our chances of developing optimizations for scalable
parallel computations remains quite low, implying that end-users will
have to continue shouldering the burden.

{{</pullquote>}}


Meanwhile, time will pass, compilers will get better, and by designing
languages with novel optimization opportunities, we create the
possibility that in the future, users will have new cases in which
work may be taken from their shoulders.  Today’s heroic—or
magic—optimizations can become tomorrow’s standard ones.  Conversely,
if we never strive to design languages that provide more productive
features, we box ourselves into the set of things that today’s
languages and compilers can do well, {{<sidenote "right"
"with no room to grow">}}To be concrete, if we never create languages
that support distributed memory parallelism, our chances of developing
optimizations for scalable parallel computations remains quite low,
implying that end-users will have to continue shouldering the burden
of implementing such optimizations.{{</sidenote>}}.

As a closing example, consider a 27-point stencil on a 3D grid, such
as the ones used in multigrid computations like the NAS MG benchmark
[[5]({{<relref "#bibliography">}})].  As illustrated within the MPI
reference version of NAS MG, such stencils can be manually optimized
in order to re-use numerical sub-computations across adjacent
applications of the stencil rather than re-computing redundant
floating point operations.  However, these optimizations also
typically impact the clarity of the code, making the expression of the
27-point stencil far less clear than it could be.  Here, for example,
is the calculation of the projection stencil in NAS MG, which uses
pairs of temporary vectors (`x1` and `y1`) and scalars (`x2`, and
`y2`) to cache and reuse sums of floating point grid points:

```fortran
     do  j3 = 2,m3j-1
         i3 = 2*j3-d3
       do  j2=2,m2j-1
           i2 = 2*j2-d2
         do j1=2,m1j
            i1 = 2*j1-d1
            x1(i1-1) = r(i1-1,i2-1,i3  ) + r(i1-1,i2+1,i3  )
                     + r(i1-1,i2,  i3-1) + r(i1-1,i2,  i3+1)
            y1(i1-1) = r(i1-1,i2-1,i3-1) + r(i1-1,i2-1,i3+1)
                     + r(i1-1,i2+1,i3-1) + r(i1-1,i2+1,i3+1)
         enddo
         do  j1=2,m1j-1
             i1 = 2*j1-d1
             y2 = r(i1,  i2-1,i3-1) + r(i1,  i2-1,i3+1)
                + r(i1,  i2+1,i3-1) + r(i1,  i2+1,i3+1)
             x2 = r(i1,  i2-1,i3  ) + r(i1,  i2+1,i3  )
                + r(i1,  i2,  i3-1) + r(i1,  i2,  i3+1)
             s(j1,j2,j3) = 0.5D0 * r(i1,i2,i3)
                         + 0.25D0 * ( r(i1-1,i2,i3) + r(i1+1,i2,i3) + x2)
                         + 0.125D0 * ( x1(i1-1) + x1(i1+1) + y2)
                         + 0.0625D0 * ( y1(i1-1) + y1(i1+1) )
            enddo
         enddo
      enddo
```

In our previous work in ZPL, we demonstrated that a user could write
stencils like these using relatively clear, concise code.  For
example, the ZPL equivalent of the projection stencil above appears as
follows:

```zpl
  S := 0.5000 * R +
       + 0.2500 * (R@^dir100[lvl] + R@^dir010[lvl] + R@^dir001[lvl] +
                   R@^dirN00[lvl] + R@^dir0N0[lvl] + R@^dir00N[lvl])
       + 0.1250 * (R@^dir110[lvl] + R@^dir101[lvl] + R@^dir011[lvl] +
                   R@^dir1N0[lvl] + R@^dir10N[lvl] + R@^dir01N[lvl] +
                   R@^dirN10[lvl] + R@^dirN01[lvl] + R@^dir0N1[lvl] +
                   R@^dirNN0[lvl] + R@^dirN0N[lvl] + R@^dir0NN[lvl])
       + 0.0625 * (R@^dir111[lvl] + R@^dir11N[lvl] + R@^dir1N1[lvl] +
                   R@^dir1NN[lvl] + R@^dirN11[lvl] + R@^dirN1N[lvl] +
                   R@^dirNN1[lvl] + R@^dirNNN[lvl]);
```

Moreover, for such computations, the ZPL compiler could optimize the
stencil using techniques similar to the hand-optimized cases [[6,
7]({{<relref "#bibliography">}})].  The result was the best of both
worlds: a clear expression of the computation for the programmer and
other readers of the code; yet with performance competitive with a
manually optimized version.

In spite of these successes, ZPL ultimately suffered a similar fate as
HPF, in this case, arguably for the same reason: when its high-level
abstractions worked for you, things were great; but when you needed to
express something at a lower level or to optimize things manually,
{{<sidenote "right" "your options were limited" -15>}}It was exactly these
experiences in ZPL that motivated Chapel's multiresolution philosophy
and design.  While Chapel's domains and arrays are based on ZPL's,
their design and integration into the lower-level aspects of the
language are a reflection of hard-learned lessons in
ZPL.{{</sidenote>}}.

Like ZPL, Chapel permits stencil operations to be expressed very
elegantly—more elegantly, in fact, as Chapel {{<sidenote "right"
"does not require <small>$O(k)$</small> expressions" -1>}}We'll see
how the stencil above can be written succinctly in Chapel
below.{{</sidenote>}} to write a <small>$k$</small>-point stencil as
ZPL did.  And, ultimately, the Chapel compiler should be able to
implement stencil optimizations at least as well as ZPL did—certain
Chapel features were even designed to help with the analysis required
for the stencil optimization in ZPL.  However, to-date, the Chapel
team {{<sidenote "right" "has not implemented this optimization"
>}}This remains true today.  While stencil computations like these
have received a lot of support within Chapel via its [Stencil
Distribution](https://chapel-lang.org/docs/modules/dists/StencilDist.html)
and related optimizations, this specific optimization has not been
implemented and remains on my wishlist.{{</sidenote>}}, and therefore
performance in Chapel today is much worse than in ZPL or a manually
implemented version.

This is where Chapel’s multiresolution philosophy comes in: users for
whom the stencil computation is not a bottleneck can use the
high-level expression today; users with more stringent performance
requirements for their stencils today can rewrite the stencil manually
using lower levels of Chapel rather than abandoning the language as in
HPF or ZPL.  Meanwhile, once Chapel’s compiler support improves and
the ZPL optimization is implemented, future programmers will benefit.
This then is the approach that we espouse for parallel programming
language design: Provide high-level features for elegance and clarity
whenever possible, along with the ability to drop to lower levels of
the language when required; and be sure to provide ample opportunities
for future compiler optimizations to aid the user (ideally without
requiring any special heroics or magic).

This leads to our conclusion:

#### Counterpoint #5: Well-designed languages should not require heroic compilation to be productive; rather, they should provide productivity through an appropriate layering of abstractions, while also providing opportunities for future compiler optimizations to make that which is merely elegant today efficient tomorrow.

Tune in next time for more myths about scalable parallel programming languages.


#### Bibliography

[1] B. Chamberlain, [Multiresolution Languages for Portable yet
Efficient Parallel
Programming](https://chapel-lang.org/papers/DARPA-RFI-Chapel-web.pdf),
unpublished position paper, October 2007.

[2] B. Chamberlain, S. Deitz, D. Iten, S-E, Choi, [User-Defined
Distributions and Layouts in Chapel: Philosophy and
Framework](https://chapel-lang.org/publications/hotpar10-final.pdf),
2nd USENIX Workshop on Hot Topics in Parallelism, June 2010.

[3] B. Chamberlain, S-E Choi, D. Iten, V. Litvinov, [Authoring
User-Defined Domain Maps in
Chapel](https://chapel-lang.org/publications/cug11-final.pdf), CUG
2011, May 2011.

[4] B. Chamberlain, S-E Choi, S. Deitz, A. Navarro, [User-Defined
Parallel Zippered Iterators in
Chapel](http://pgas11.rice.edu/papers/ChamberlainEtAl-Chapel-Iterators-PGAS11.pdf),
PGAS 2011: Fifth Conference on Partitioned Global Address Space
Programming Models, October 2011.

[5] D. Bailey, T. Harris, W. Saphir, R. van der Wijngaart, A. Woo,
M. Yarrow, [The NAS Parallel Benchmarks
2.0](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1995/nas-95-020.pdf),
Tech Report NAS 95 020, December 1995.

[6] S. Deitz, B. Chamberlain, L. Snyder, [Eliminating Redundancies in
Sum-of-Product Array
Computations](https://research.cs.washington.edu/zpl/papers/data/Deitz01.pdf),
In Proceedings of the ACM Conference on Principles and Practice of
Parallel Programming, 2003.

[7] B. Chamberlain, S. Deitz, L. Snyder, [A Comparative Study of the
NAS MG Benchmark Across Parallel Languages and
Architectures](https://research.cs.washington.edu/zpl/papers/data/Chamberlain00.pdf),
In Proceedings of the ACM Conference on Supercomputing, 2000.


---

### Reflections on the Original Article

For me, this article stands up quite well despite the passing of
thirteen years.  I think there is still a general bias or fear that
productive, high-level parallel languages require magic or heroic
compilers.  I also think that the benchmark results and user
applications that Chapel has supported in the intervening years
validate Chapel's design and multiresolution approach in a way that we
couldn't at the time of the original publication.

In this section, I'll expound on these points a bit more in the
context of Chapel's `forall` loops, and then show the stencil code
from the original article written in Chapel.


#### Chapel's (not so) Magic `forall`
##### Background

In Chapel's early years, one of the language concepts that tended to
be considered most "magical" was its `forall` loop.  Let's look
briefly at why this was (and may still be for some today), as well as
the reality of the feature, which is completely non-magical.

For those unfamiliar with Chapel, in addition to its serial `for`
loop, it supports a task-parallel `coforall` loop in which each
iteration is executed by a distinct task (feel free to think
"thread").  The implementation of both of these is fairly
straightforward to reason about: The `for` loop is implemented more or
less as in most languages, while the `coforall` effectively spawns a
task for each iteration through the loop, having it execute the loop
body for its specific iteration.  The original task does not proceed
until each of these tasks it creates has completed.

Like the `coforall` loop, `forall` is also a parallel loop, but one
that sits somewhere between the extremes of the `coforall`'s "1 task
per iteration" and the `for` loop's "1 task total."  The `forall` loop
is typically used when the number of loop iterations is so
large—and/or the amount of work in the loop body so small—that
spawning a task per iteration would be overkill.  For example, in the
following loop:

```chapel
forall i in 1..1_000_000 do
  A[i] = i;
```

we probably don't want to spawn a million tasks, as a `coforall` loop
would, if we only have 16 processor cores—particularly given how
simple the loop body is.  We'd effectively spend all our time spawning
and destroying tasks rather than doing the computation itself.

In practice, `forall` loops typically create a number of tasks
proportional to the hardware resources on which they're running,
dividing the loop iterations amongst themselves, either statically or
dynamically.  The reason for the wiggle-words here—"typically" and
"either"—is that Chapel defines `forall` loops as invoking the
parallel iterator of the loop's _iterand expression_.

For the loop above, the iterand is the range value `1..1_000_000`, so
the compiler will invoke its default parallel iterator.  The default
parallel iterator for a range is defined to create a number of tasks
equal to the number of idle processor cores on the current locale
(think "compute node"), chunk up the iterations between them as evenly
as possible, and have each task execute its subset.  The range
iterator is written as Chapel code itself, using `coforall` loops
to create the tasks and serial loops to perform each task's work.

##### Relation to this month's Reprint

I'm telling you all of this because it illustrates several points in a
bit more detail than the original article was able to: First, that
Chapel's most {{<sidenote "right" "conceptually abstract" >}}In the
sense that it effectively says "Execute this loop using an appropriate
amount of parallelism."{{</sidenote>}} loop, `forall`, is actually
quite concrete, effectively serving as a sugar for "invoke this
expression's parallel iterator."  The `forall` loop also serves as a
demonstration of Chapel's multiresolution philosophy since the
parallel iterators that `forall`s invoke are themselves implemented in
terms of lower-level, explicit constructs like task-parallel
`coforall` loops.  This is also why Chapel's data-parallel features
that use `forall` or are implemented in terms of it can be mixed
arbitrarily with lower-level task-parallel features like `coforall`—at
the end of the day it all boils down to the same set of features.
Finally, users can create and invoke their own parallel iterators like
the one on ranges for their data structures or as standalone routines,
as mentioned in the original article.

Another reason that `forall` loops may feel magical is that they can
be so different when applied to one data structure versus the next.
While the range's parallel iterator is fairly straightforward, a
`forall` loop over a distributed array will typically result in
multiple tasks being executed on each locale that owns a piece of the
array.  Meanwhile, other [data
structures](https://chapel-lang.org/docs/modules/packages/DistributedBag.html)
and [iterator
routines](https://chapel-lang.org/docs/modules/standard/DynamicIters.html)
might dynamically distribute work across tasks and/or locales.  This
variability across data structures is productive and powerful, in that
each data structure will presumably do something reasonable; but it
can also be subtle given that the parallel iterator and loop can be so
far from one another in the code base—in many cases, the programmer
may never look at the iterator's implementation or documentation, or
even need to.

This last point relates to a final reason that `forall` may be
considered magical, which is that it took us a number of years to
figure out how to define and implement it, particularly for cases
involving _promotion_ or _zippered iteration_, where multiple data
structures or iterators may get traversed simultaneously.  As a
result, the documentation for `forall` loops was late to be created
relative to the rest of the language and may still not be as
well-integrated into the documentation as it ought to be.  Users who
are curious to learn more about the relationship between `forall`
loops, parallel iterators, and particularly parallel zippered
iteration are encouraged to read Chapel's [parallel iterators
primer](https://chapel-lang.org/docs/primers/parIters.html) or our
PGAS 2011 paper, [_User-Defined Parallel Zippered Iterators in
Chapel_](http://pgas11.rice.edu/papers/ChamberlainEtAl-Chapel-Iterators-PGAS11.pdf)
(published less than a year before this original article), or [its
slides](https://chapel-lang.org/presentations/ChapelForPGAS2011.pdf).


#### The Stencil Example in Chapel

Though this article focuses on a stencil example, it rather
maddeningly doesn't show the code in Chapel.  Checking the date of the
article, I believe that this is because at the time it was written, we
were in the midst of making some significant user-requested changes to
the syntax for Chapel's domains and arrays, such that I didn't want to
publish some code only to have it become outdated a few months later.

Making up for that now that the syntax is stable, here's one way of
writing the stencil compactly in Chapel:

{{< subfile fname="stencil-3D.chpl" lang="chapel" lstart=7 lstop=16 >}}

This approach demonstrates the principle mentioned in the original
article about how Chapel supports the ability to write stencils
without requiring a number of expressions proportional to the number
of points in the stencil, as in the Fortran and ZPL codes above.

Of course, Chapel stencils can also be written using loop nests and
explicit indexing as in those languages, but this tends to become
taxing as the stencil's size grows.  For example, the Fast Multipole
Method described [last month]({{< relref 10myths-part4
>}}#the-original-article-reprinted) involves 216-point stencils
(<small>$6\times6\times6$</small>), which are both tedious and
error-prone when written out explicitly.

Note that this stencil idiom in Chapel also happens to be
rank-neutral, permitting it to be run on `S`, `R`, and `weight` arrays
that are 1D, 2D, 3D, or nD.  In this example, I used explicit 3D
declarations of the `weight` array for clarity; but with additional
changes, these can be made rank-neutral as well.

{{<details summary="**Click to see the rank-neutral version of `weight`...**">}}

Here's code to declare the weight indices and values in a rank-neutral
way:

{{< subfile fname="weights-nD.chpl" lang="chapel" lstart=1 lstop=20 >}}

This code works for ranks <small>$\geq2$</small>.  To support 1D
stencils, a bit more care would be required because the `idx` variable
would be an integer rather than a tuple, so would not support
the iteration used to initialize the `weight` array.

{{</details>}}


As alluded to in the original article, Chapel was designed to support
the aforementioned ZPL optimization on closed-form expressions of
stencils like the one above.  The idea would be to declare the
`weight` and `weightInds` constants above as `param`s and then teach
the compiler to recognize patterns like this as being convolutions.
Our hypothesis is that this would simplify the compiler's ability to
assemble and reason about the weight arrays compared to the approach
taken in ZPL.  We've also discussed the idea of introducing an
explicit convolution operator or expression to the language in order
to make such stencils even more straightforward to express and
analyze, but this too remains future work.




#### Wrapping Up

That concludes this month's myth about how well-designed, productive
languages need not rely on magic or heroic compilers to get things
done.  I believe that Chapel's approach of designing the language in a
layered, multiresolution way has paid off well for the project and
Chapel community, giving users the ability to exert more control when
necessary while providing Chapel developers with opportunities to
introduce new abstractions and optimizations as motivated by such
cases.

Next month, we'll revisit the sixth article in this series, which
addresses the myth that high-level languages necessarily result in a
performance hit.
