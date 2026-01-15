---
title: "10 Myths About Scalable Parallel Programming Languages (Redux),  Part 3: New Languages vs. Language Extensions"
date: 2025-06-25
tags: ["Editorial", "Archival Posts / Reprints", "GPUs"]
series: ["10 Myths About Scalable Parallel Programming Languages Redux"]
summary: "A third archival post from the 2012 IEEE TCSC blog series, with a current reflection on it"
authors: ["Brad Chamberlain"]
---

### Background

In 2012, I wrote a series of eight posts for the IEEE Technical
Community on Scalable Computing&nbsp;(TCSC) blog entitled "Myths About
Scalable Parallel Programming Languages."  In it, I described
discouraging attitudes that our team encountered when talking about
developing a language like Chapel, and also gave my personal
perspective and rebuttal to them.  That series has been generally
unavailable for many years, so on this, its 13th anniversary, I
thought it'd be interesting to reprint the original series along with
new commentary reflecting on how well or poorly the ideas have held up
over time.  For a more detailed introduction to both the original
series and this updated one, please see [the first article]({{< relref
10myths-part1 >}}) in the series.


This month, we're reprinting the third article in the TCSC series,
originally published on June 25, 2012.  Comments in the sidebar and
[sections that follow the article]({{<relref
"#reflections-on-the-original-article">}}) provide some thoughts and
reflections on it:


---

### The Original Article, Reprinted

Myths About Scalable Parallel Programming Languages:<br>
Part 3: New Languages vs. Language Extensions
{.big}

This is the third in a series of blog articles that I’m writing with
the goal of summarizing and responding to some of the assumptions
about scalable parallel programming languages that our team encounters
when talking about our work designing and implementing Chapel
(https://chapel-lang.org).

For more background on Chapel or this series of articles, please refer
to parts [1]({{< relref 10myths-part1 >}}#the-original-article-reprinted)
and [2]({{< relref 10myths-part2 >}}#the-original-article-reprinted).

#### Myth #3: Programmers won’t switch to new languages.  To be successful, a new language must be an extension of an existing language.

This is another statement that we frequently hear when describing our
work on Chapel (which, if it’s not obvious from context, does not
extend an existing language).  This objection is fairly easy for me to
shrug off because similar comments were made during the 1990’s—before
{{<sidenote "right" "Java and Python">}}Not to mention JavaScript and
C#.  And since this article's original publication, also Go, Rust,
Swift, and Julia.{{</sidenote>}} rose to the level of prominence that
they enjoy today.  The adoption of these languages (with other
promising languages in the wings) proves that while it’s a long shot
for any new language to gain widespread adoption, it’s certainly not
impossible.  In our view, distributed scalable parallel computing is
different enough from traditional serial and multithreaded desktop
computing to warrant a new language.  Moreover, working in a brand-new
language can be liberating from a design perspective.  Even if an
attempt at a new language is not ultimately adopted, its features may
go on to influence the next generation of languages, be they novel or
extension-based.


###### Extending Existing Languages

Proponents of this opinion typically suggest that by extending an
existing language, you improve your chances of co-opting an extant
user community while potentially leveraging compilers, tools, and user
code for that language.  For modest language changes and extensions,
or for research projects, this can certainly be a prudent and viable
approach.  But extending a language can also be overly restrictive if
you are trying to pursue an aggressive goal like general, scalable
parallel programming.  And it can lead to compromises that limit the
potential impact or attractiveness of your language, preventing you
from getting past the tipping point that’s required for adoption.
Let’s start by considering some of the pitfalls of extending an
existing language and then move on to discuss strategies for
increasing a language’s chances of adoption.

For me, the main problem with extending existing languages is that
they tend to carry baggage.  For example, when considering scalable
parallel programming, perhaps the most obvious languages to extend are
Fortran, C, and C++.  Fortran, though durable, reflects design decisions
that often seem antiquated by modern language design standards.  Put
simply, it fails to reflect features and sensibilities that I believe
are increasingly required to appeal to a broad swath of modern
programmers, such as graduating students.  That’s not to say that
Fortran is past its expiration date, but I do believe it bears scars
reflecting decades of revisions while lacking other crucial features
and niceties.  C and C++ emerged from more of a systems programming
setting and betray this through concepts like pointer-array
equivalence and lack of rich support for multidimensional arrays.
Arguably these choices have prevented C/C++ from completely
supplanting Fortran in the scientific community.  They also make C/C++
a difficult starting point for languages designed for large-scale
scientific computation.  In our work on Chapel, if there had been a
well-established language with rich support for {{<sidenote "right" "arrays">}}Specifically, multidimensional arrays.{{</sidenote>}},
object-oriented programming, generic programming, iterator functions,
and type inference, with an open-source compiler, I suspect we would
have considered extending it.  But seeing no strong contenders, we
decided instead to build our ideal base language from scratch
(borrowing liberally from other languages of course).

<u>Supersets of Subsets</u>

Proponents of extension-based approaches might argue that I’m taking
the concept of extension too literally.  For example, they might argue
that one could create a C-based language in which potentially
troublesome concepts like pointer-array equivalence are removed and
multidimensional arrays are added.  And they’d be right, {{<sidenote
"right" "you could">}}As I understand it, Mojo arguably does this with
Python.{{</sidenote>}}.

This approach of extending a language by removing features from it,
modifying other features, and adding new ones is often referred to as
creating “a superset of a subset of a language.”  And it’s a
completely viable approach, though I believe it often negates the
benefits of extending an existing language.  If the argument for
building on an existing language is to co-opt its users and code base,
the decision to change its traditional rules can lead to more
confusion and incompatibility than benefit.  An example of this issue
can be seen in hardware design languages that use a C syntax for
familiarity.  Many of these languages impose a hardware-based dataflow
interpretation of the program’s variables and statements, thereby
abandoning the traditional semantics of C.  In such cases, the benefit
of using familiar C syntax is undermined by the nontraditional
interpretation of that syntax.  In the limit, the original language
becomes unrecognizable.  As a colleague’s anonymous reviewer once
quoted, “[even] a washing machine is a superset of a subset of C.”

In my opinion, a language’s semantics are where a new user’s effort
tends to be focused, not its syntax.  An unnecessarily foreign or
obfuscated syntax can be troublesome, sure, but given any reasonable
syntax, a beginner’s intellectual effort will tend to be focused on
learning the language’s concepts and rules for execution more than its
formatting.  I believe that programmers will often stumble less when
learning new syntax than when trying to get their heads around what
changes to a familiar language your superset of a subset involves.
And frankly, I find it’s often simpler to switch gears when moving
between languages if they look more distinct than similar—it provides
visual cues to help your brain switch modes of thought.

<u>Standards Committees</u>

Another downside to extending an existing language is the potential
need to work with its standards committee.  Standards committees are,
by nature, conservative and wary of change, and for good reason: it’s
important that they not compromise an established language’s utility
and backwards compatibility by chasing after new and speculative
directions.  Yet this conservatism can also make it difficult to
incorporate ground-breaking new concepts because of the need to proceed
{{<sidenote "right" "in a cautious, stepwise manner">}}I'm not sure
this section holds up as well as the others.  While I still don't
really relish the idea of extending existing languages or wrestling
with standards committees, even with a brand-new language like Chapel,
once we hit a certain level of [user adoption]({{<relref
7-questions-for-chapel-users>}}) and our [2.0 release]({{<relref
announcing-chapel-2.0>}}), we had to similarly start being more
cautious in our changes as well.  That said, it was definitely
liberating and empowering to start from the position of not being
beholden to a historically sequential language.  More on this
below.{{</sidenote>}}.  In my experience, good concepts have sometimes
been prevented from realizing their full potential due to the concerns
of standards committees—or even individual members of the
committee—thus neutering the concept in ways that have marginalized
its potential impact.

{{<pullquote>}}

If you design ground-breaking new concepts that would suit an existing
language, it’s likely that its community will take note regardless of
whether you’ve extended their language.

{{</pullquote>}}

Clearly, a language can be extended without engaging its standards
committee; but if your ultimate goal is to advocate that your features
be added to the language, restricting yourself to a subset of the
language is likely to be as much of a barrier as if you started a new
language from scratch.  If you design ground-breaking new concepts that
would suit an existing language, it’s likely that its community will
take note regardless of whether you’ve extended their language
vs. another.  So starting with a new language is not much of a
liability here either.


###### Designing New Languages

If you are going to design a new language, here are some things that
can lower barriers to adoption.

<u>Clear syntax</u>

The first thing is to adopt a clear, familiar syntax.  A good
illustration of this concept comes from a colleague of mine who said
“New languages won’t succeed unless they are extensions to existing
languages” and then immediately cited the example of Java’s success as
an extension of C++.  Of course, Java isn’t an extension to C++, but
it’s syntactically similar enough that it lowers barriers to adoption
and even tricks some people (like my colleague) into thinking of it as
an extension to a language they already know.

At the same time, a language designer should feel free to deviate from
familiar syntax in cases that improve power or clarity.  In the case
of Chapel, we follow C’s syntactic lead in many respects, considering
it to have syntactic components that have influenced many popular
languages.  But we chose to abandon C’s declaration syntax in favor of
a more Modula-like keyword-based approach, more in the vein of Python,
Ruby, or Scala.  Part of our motivation for doing so was the belief
that left-to-right declarations are easier to read and write than
C-style “inside-out” declarations; part of it was because we believed
it supported type inference more cleanly; and part of it was to more
naturally support very rich array-of-arrays data structures.  We
believe that the net effect is a syntax that is {{<sidenote "right"
"sufficiently familiar and C-like">}}Interestingly, Fortran and Python
programmers have also described Chapel as seeming familiar and
Fortran-like / Pythonic, despite their significant differences from
C.{{</sidenote>}} while providing benefits over C, along with clear
visual cues that a programmer is using Chapel rather than C.




<u>Interoperability</u>

Perhaps the most important thing a new language can do for adoption is
to interoperate with existing languages used by its target community.
I believe that part of the reason people want new languages to extend
existing ones is to avoid having to throw existing code away.  But if
your new language is a superset of a subset of a language—or even a
proper superset—it remains likely that you will need to rewrite
existing code in order to fit the new language.  For example, most
serial algorithms need to be rewritten in order to make them into good
scalable, parallel codes.  This simple fact makes {{<sidenote "right"
"extending languages">}}...in order to re-use code, that
is...{{</sidenote>}} seem like a bit of a pipe dream for me.
Particularly since good support for interoperability can be at least
as effective.

{{<pullquote>}}

Being able to continue to use existing code is far more important than
extending an existing language.

{{</pullquote>}}

I suspect that a good part of Java and Python’s success has been their
ability to interoperate with established languages through
capabilities like the Java Native Interface (JNI) and SWIG (Simplified
Wrapper and Interface Generator).  Being able to continue to use
existing code, or to rewrite part of your program in a new language
without rewriting all of it, is far more important for code reuse than
extending an existing language, in my opinion.  To this end, Chapel
has considered interoperability to be a key feature from the
beginning.  Today, we achieve simple interoperability with C via
“extern” and “export” declarations.  We also provide more general
language interoperability through the {{<sidenote "right"
"Babel/BRAID technologies" -5>}}Sadly, Babel and BRAID are no longer
being developed.  However, our interoperability capabilities have
significantly improved since this article's original publication, with
the addition of support for interoperating with
[Python](https://chapel-lang.org/docs/modules/packages/Python.html)
and [Fortran]({{<relref fortran-marbl1>}}), as well as significantly
improved C support through [_extern
blocks_](https://chapel-lang.org/docs/technotes/extern.html#support-for-extern-blocks)
and the [`c2chapel`
tool](https://chapel-lang.org/docs/tools/c2chapel/c2chapel.html).

In
addition, Chapel programs can interact with existing programs
through
[ZeroMQ](https://chapel-lang.org/docs/modules/packages/ZMQ.html),
[Google Protocol
Buffers](https://chapel-lang.org/docs/tools/protoc-gen-chpl/protoc-gen-chpl.html),
and (as of our most recent release) [dynamic
loading](https://chapel-lang.org/docs/modules/packages/DynamicLoading.html)
of libraries.  ZeroMQ in particular was instrumental to enabling
[Arkouda](https://arkouda-www.github.io/) to integrate into Python-based
Jupyter notebooks.{{</sidenote>}} being developed at Lawrence
Livermore National Laboratory [1].


<u>Reasonable benefit::effort ratio</u>

Switching to any new language requires some investment of time and
effort, and since many of us suffer from {{<sidenote "left"
"feature shock">}}Re-reading this today, I found myself
wondering... did I make this term up?  Googling... [maybe
not](http://catb.org/jargon/html/F/feature-shock.html)?

What I meant
by it at the time was the feeling of being overwhelmed by lots and
lots of new features.  One of my favorite compliments from a user was
that they liked that Chapel was easy to get started with, yet was
sufficiently rich that as they dug deeper and learned more, they kept
finding additional depth and power to leverage.  That said, we are
also aware that we could be doing a much better job of easing new users into the
language through online tutorials, exercises, examples, and videos.{{</sidenote>}},
it’s important that a new language provide compelling reasons for
switching while minimizing the effort required to do so.  This also
means not throwing away important use cases of the languages from
which your users are switching.  When people fret about why certain
parallel languages have failed, my sense is that many of them didn’t
get this benefit::effort ratio correct.  That many did not offer
enough new benefit to warrant switching away from an established
technology like MPI; or that others could only handle a subset of what
MPI can do, requiring users to be willing to give something up.  In
our work, we are striving to make Chapel capable of subsuming the
features of systems like MPI, OpenMP, and UPC while providing enough
additional benefit in terms of productivity and generality to make the
switch attractive rather than simply possible.


<u>Riding a technology wave</u>

A final factor for this discussion of language adoption is to try and
ride a technology wave that helps carry the language forward.
Fortran’s success is often cited as being linked to the emergence of
the optimizing compiler; C’s to UNIX; Java’s to the {{<sidenote
"right" "World Wide Web">}}It makes me smile that I called it by its
full name in 2012.{{</sidenote>}}.  Most language designers don’t have
enough influence over technological trends to be able to cause a
change in tide like these to happen; but if you pay attention and your
timing is good, riding such a wave can certainly help.  We are
currently at a time when parallel programming is becoming increasingly
mainstream while next-generation supercomputing architectures are
undergoing {{<sidenote "right"
"bigger changes than they have in decades">}}Today, we are arguably at
a similar point of inflection and uncertainty where more and more
specialized hardware architectures are being developed---such as
tensor and neural processing units---that will ultimately need to be
programmed.{{</sidenote>}}.  Those swells in the ocean represent
potential waves that could help carry a novel parallel language from
concept to adoption.  Though naturally, you should expect some
competition from other surfers.

To summarize, extending existing languages is a completely reasonable
way to approach language design, but it isn’t as much of a silver
bullet for adoption as many suggest.  This leads us to:

##### Counterpoint #3: The surface benefits of extending an existing language are often not as deeply beneficial as we might intuitively believe.  Moreover, when well-designed languages offer clear benefits and a path forward for existing code, the programming community is often more willing to switch than they are given credit for.  Thus, we shouldn’t shy away from new languages and the benefits they bring without good reason.

Tune in next time for more myths about scalable parallel programming
languages.

#### References

[1] A. Prantl, T. Epperly, S. Imam, V. Sarkar.  [Interfacing Chapel
with Traditional HPC Programming
Languages](http://pgas11.rice.edu/papers/PrantlEtAl-Chapel-Interoperability-PGAS11.pdf).
In PGAS 2011: Fifth Conference on Partitioned Global Address Space
Programming Models, October 2011.


---

### Reflections on the Original Article

#### Trends in HPC Notations

I generally think that this article's points have held up reasonably
well over the past 13 years.  That said, I also think that the "myth"
itself might not hold up as well today.  Specifically, my sense is
that the current generation of programmers is not nearly as resistant
to new languages as I considered them to be when writing this article.
Consider that Go, Swift, Julia, and particularly Rust have all become
quite popular and {{<sidenote "right" "broadly adopted" -9>}}CUDA
should arguably be on this list as well, but I've relegated it to a
sidebar due to its particular focus on GPUs (and arguably on NVIDIA
GPUs) rather than what I'd consider to be a more general-purpose
programming.{{</sidenote>}} since 2012, despite the fact that
each is a new language that does not simply extend an existing one.

Or maybe it was just {{<sidenote "right" "HPC">}}HPC, or
High-Performance Computing, can mean different things to different
people.  I should clarify that in this article, I'm using it as a
shorthand for distributed memory supercomputing, typically involving
compute nodes with multicore CPUs and GPUs with distinct
memories.{{</sidenote>}} programmers that I was thinking of when
writing up this myth?  If so, then perhaps it is not so outdated given
that traditional HPC largely continues to use the identical
programming languages as in the 1990's—{{<sidenote "left"
"Fortran, C, and C++">}}Though to be fair, the languages themselves
have evolved quite a bit...{{</sidenote>}}—with MPI+X libraries and
notations still dominating applications and their frameworks.

One big change over that time period is that "X" has expanded from
being "predominantly OpenMP" to also include a large number of
GPU-oriented dialects, libraries, and extensions.  This collection of
GPU programming notations clearly represents the area where HPC
programming has evolved most dramatically and quickly---and also out
of necessity.  That necessity was driven by the fact that GPUs rapidly
became dominant in HPC systems, combined with the fact that our
existing programming languages and notations were poorly suited to
leverage them.  The net effect has been systems that are faster and
more energy efficient than ever, yet also harder than ever to program.

One of the things I'm most proud of with Chapel, as touched on [last
month]({{<relref 10myths-part2>}}#the-rise-of-gpu-computing), is that
while it was designed well before {{<sidenote "right"
"general-purpose GPU computing was a thing">}}...not to mention
multi-socket systems, NUMA sensitivity, and even multicore
processors{{</sidenote>}}, its focus on expressing locality and
parallelism as core, orthogonal concepts has permitted it to remain
relevant over a long span of time.

#### Adopted Languages vs. Libraries

{{<pullquote>}}

Recurring themes of recently adopted languages include productivity,
safety, portability, and performance—all topics that are of huge
importance to HPC as well.

{{</pullquote>}}

The difference between the number of new languages adopted within HPC
over the past 2–3 decades vs. outside of it seems stark.  It's
particularly disappointing when realizing that some recurring themes
of adopted languages within that time period include improved
productivity, safety, portability, and performance---all topics that
are (or should be) of huge importance to HPC as well.

Within HPC, it definitely seems to be the case that most institutions
and users have pinned their hopes on C++ libraries rather than new
languages—and specifically on libraries that make use of C++'s rich
meta-programming features.  In a sense, the "new languages must extend
existing ones" part of this article's myth has transformed into
"actually, we don't really even need new languages, we'll just use
libraries."

It seems self-evident that libraries are sufficient for doing HPC
programming, as proven by MPI, Kokkos, and other HPC technologies that
have powered flagship applications during this period.  However, they
also leave a lot on the table.  For example, {{<sidenote "right"
"having a language">}}These characterizations borrow heavily from a
workshop talk by Kathy Yelick that I was inspired by early in my
professional career.  She later reprised this content in her CHIUW
2018 keynote, [_Why Languages Matter More Than
Ever_](https://chapel-lang.org/CHIUW/2018/Yelick-Languages-CHIUW18.pdf).{{</sidenote>}}
means you can have specialized syntax that can make parallel
algorithms cleaner, resulting in code that is easier to write, debug,
read, and maintain.  It also means having a compiler that can perform
semantic checks to help you avoid introducing errors and bugs; or that
can perform optimizations, reducing the time and effort spent tuning
your code manually.

The HPC community's successes demonstrate that scalable parallel
computing _can_ be achieved without a dedicated programming language
to express parallelism and locality; but wouldn't scalable parallel
programming be better if, as a community, we were able to create and
adopt such a language?  My sense is that we would look back on
MPI+X programming and consider it to be the equivalent of
assembly-level programming in the era of Fortran---something that is
difficult to let go of due to all of the control it affords, yet which
is hampering our productivity when higher-level languages and
optimizing compilers should eventually supplant our need to do
everything manually.  As reassurance, note that the existence of such
technologies would not remove the ability, or occasional need, to
program at lower levels, just as Fortran did not do away with all
assembly-level programming.



#### Benefits of Parallel-by-Design Languages

Reading this article 13 years later, I feel as though I sometimes
focused too much on new languages in general rather than on the
specific benefits that can be gained by creating new _parallel_
languages.  As a very simple example, consider a basic loop iterating
over a sequence of integers in C:

```c
for (int i=0; i<n; i++)
  A[i] += 1;
```

The whole premise of this loop is that we have a single variable `i`
that we are modifying each time we traverse the loop until we exit it.
When you think about the history of parallelizing compilers, parallel
pragmas, and directives, a lot of those efforts have been tangled up
in the simple question of determining whether such loops can safely be
run in parallel in spite of the fact that they are using a serial
control flow construct whose single index variable's value is carried
from one iteration to the next.

Consider the same loop in Chapel:

```chapel
for i in 0..<n do
  A[i] += 1;
```

Chapel defines this loop as invoking the default iterator defined by
the range iterand, `0..<n` and binding each of the `const` values that
it yields to the loop's index variable `i`.  In effect, this gives
each iteration of the loop its own unique `i` variable and value.  For
a serial loop, the difference from C is fairly minor, but this
starting point establishes a strong foundation for supporting parallel
loops:

```chapel
forall i in 0..<n do  // or, alternatively, 'foreach' or 'coforall'
  A[i] += 1;
```

Immediately, there's no need to reason about the values of `i` across
loop iterations because we've already defined that each iteration of
the loop gets its own.  Moreover, where the original loop invoked the
range's default serial iterator, this one will invoke its default
parallel iterator, leading to a very symmetric definition of how the
loop executes.  Essentially, by defining the language with parallelism
in mind, we've made serial loops that can trivially be made into
parallel ones when that's reasonable.

{{<pullquote>}}

Designing a language with parallelism as a first-class concern can
result in a cleaner, safer design than retroactively injecting
parallelism into a language whose original design was sequential.

{{</pullquote>}}


Building on this basis, Chapel then goes on to define semantics that
minimize the chances of introducing accidental race conditions.  For
example, a C loop might compute a sum as follows:

```chapel
int sum;
for (int i=0; i<n; i++)
  sum += A[i];
```

This raises additional challenges or hazards for correct
parallelization due to the reduction computed with `sum`.
Yet, if we write the equivalent parallel loop in Chapel:

```chapel
var sum: int;
forall i in 0..<n do
  sum += i;
```

we will get an error because the language doesn't permit scalar values
like `sum` that are defined outside of a parallel loop to be modified
within it.  To do so, the user must introduce additional
synchronization, explicitly override this default safety feature, or
switch to using a `+ reduce` expression or intent.

These are just two simple examples, but they illustrate how designing
a language with parallelism as a first-class concern can result in a
cleaner, safer, simpler design than retroactively injecting parallelism into a
language whose original design was sequential.  They also are
representative of a much larger set of choices that we made when
designing Chapel's features for parallelism and locality in service of
scalable computing---far more than I could possibly cover in this
article.


#### The Wave of Ubiquitous Parallelism

{{<pullquote>}}

The world has become far more concerned with, and invested in,
parallelism and distributed memory computing than they were in the
1990s or early 2000s.

{{</pullquote>}}

In the original article above, I talk about how many adopted languages
have benefited from leveraging some other technology trend that has
helped carry them to success---sometimes intentionally and sometimes
by accident.  Meanwhile, HPC circles often seem to grouse about how we
are simply not a large enough community to establish and sustain a
{{<sidenote "right" "a programming language of our own">}}(despite the
fact that this same community seems to have plenty of resources to
invest in speculative hardware designs that typically have inherent
lifetime constraints){{</sidenote>}}.  To me, this attitude ignores the
technology wave of ubiquitous parallel computing that has been
changing the face of computing over the past decade or two.

Traditional HPC does arguably continue to be something of a niche
field.  However, the rest of the world has become far more concerned
with, and invested in, parallelism and distributed memory computing
than they were in the 1990s or early 2000s.  Every commodity processor
design of note today is a multicore processor.  GPU computing is
similarly ubiquitous and crucial, particularly with the rise of
Artificial Intelligence and Machine Learning (AI/ML).  Meanwhile,
cloud computing makes supercomputer-like systems available to anyone
who is able to pay for system time.  Performance, parallelism, and
energy efficiency are now as important to many commercial and non-HPC
sectors as they have been to HPC for its lifetime.

So when members of our community suggest that we cannot afford to
create a language that is purpose-built for parallelism and
scalability, to me it reflects a short-sightedness that fails to
recognize the breadth of overlap with communities outside of
traditional HPC who could similarly benefit from the same thing.  This
is the perfect time to be doing outreach to HPC-adjacent fields and
finding allies within them to create languages and compilers that
outstrip what traditional HPC could do on its own.  And that is
precisely what we are attempting to do with Chapel: to catch this wave
of ubiquitous parallel computing and ride it to widespread adoption,
as Fortran did with optimizing compilers or Java did with the web.


### Wrapping Up

That concludes this month's myth about the non-adoptability of new
languages and particularly languages that aren't extensions of others.
Next month, we'll be revisiting the fourth article in the series,
which wrestles with the question of whether or not syntax matters in a
language's design.  See you then!
