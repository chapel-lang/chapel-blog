---
title: "10 Myths About Scalable Parallel Programming Languages (Redux),  Part 2: Past Failures and Future Attempts"
richtitle: "10 Myths About Scalable Parallel Programming Languages (Redux)<br>  Part 2: Past Failures and Future Attempts"
date: 2025-05-28
tags: ["Editorial", "Archival Posts / Reprints", "GPUs"]
series: ["10 Myths About Scalable Parallel Programming Languages Redux"]
summary: "Another archival post from the IEEE TCSC blog in 2012, with a current reflection on it"
authors: ["Brad Chamberlain"]
---

### Background

In 2012, I wrote a series of eight blog articles for the IEEE
{{<sidenote "right" "TCSC">}}TCSC = Technical Community on Scalable
Computing{{</sidenote>}} blog entitled "Myths About Scalable Parallel
Programming Languages."  In it, I described discouraging attitudes
that our team encountered when talking about developing a language
like Chapel, and also gave my personal perspective and rebuttal to
them.  That series has been generally unavailable for many years, so I
thought it'd be interesting to reprint the original series in honor of
its 13th anniversary, along with new commentary reflecting on how well
or poorly the ideas have held up over time.  For a more detailed
introduction, to both the original series and this one, please see
[last month's article]({{< relref 10myths-part1 >}}).


Here's the second article from the series, originally published on May
28, 2012, followed by [new sections]({{<relref
"#reflections-on-the-original-article">}}) with current reflections on
it:


---

### The Original Article, Reprinted

Myths About Scalable Parallel Programming Languages:<br>
Part 2: Past Failures and Future Attempts
{.big}

This is the second in a series of blog articles I’m writing with the
goal of describing and responding to some of the assumptions about
scalable parallel programming languages that our team frequently
encounters when talking about our work designing and implementing
Chapel (https://chapel-lang.org).  For more background on Chapel or
this series, please refer to [part 1]({{< relref 10myths-part1 >}}#the-original-article-reprinted).




#### Myth #2: Because HPF failed, your language will not succeed.

In describing Chapel, one of the earliest reactions we encountered
within the HPC community (and one that still comes up today with
surprising frequency) was “How can your language possibly succeed when
HPF failed?” Another popular variation is: “How can it possibly succeed when I can name 
{{<sidenote "right" "dozens (hundreds?) of parallel languages" -12>}}
These days, HPF doesn't come up very frequently, as the HPC community
has largely gotten over it by now.  However, this second, more
general, question still comes up from time to time, and some people
seem to enjoy enumerating failed parallel languages to rationalize not
trying to improve the state of the art.  Imagine if non-HPC
programming communities had taken this defeatist stance and failed to
develop Java, Python, Go, Swift, or Rust as alternatives to C, C++,
and Perl.{{</sidenote>}} that have failed?”

{{<pullquote>}}
The failure of one language doesn’t dictate the failure of all future
languages any more than early failed attempts at flight or putting
rockets into space meant those feats were impossible.
{{</pullquote>}}

For the young {{<sidenote "right" "and the forgetful">}}On reflection,
that seems a bit rude, 2012-era Brad...  Maybe it felt more obviously
humorous at the time since HPF was recent enough that it was unlikely
to have been forgotten?  🤔{{</sidenote>}}: HPF (High Performance
Fortran) is a language in which a significant amount of funding,
effort, and faith was placed in the 1990s, yet one which ultimately
did not pan out for the HPC community.  The level of expectation
placed on HPF followed by its demise made funding novel language
development in its wake even more challenging than usual.  For the
insider’s view of HPF’s lifecycle, refer to the insightful and
enjoyable HoPL III paper by Kennedy et al. [1].

The short and simple response to this question is that the failure of
one language (or many) doesn’t dictate the failure of all future
languages any more than early failed attempts at flight or putting
rockets into space meant those feats were impossible.  Challenging?
Yes.  Improbable?  In the case of language adoption, also yes; but in
spite of this, it is still a very worthwhile pursuit.

[Tips for language developers: To get detractors past this mental
block, try the following approach: “Are you completely satisfied with
the scalable parallel programming notations that we have today?  And
if so, will you continue to be in 10, 20, or 40 years?  If so, that’s
great; I am working on this language to support others who answer
differently.  If not, then how will we ever move on to better
parallel programming notations if we do not strive to improve the
state of the art?”]

Moving beyond the simple response, we should note that beyond sapping
morale, failed languages also have great value: they provide a rich
opportunity for learning lessons that can (and often should) be
applied to subsequent attempts.  “Those who ignore history are bound
to repeat it” and all that.  With Chapel, we went into our language
design effort by considering HPF’s failure and learning from it rather
than blindly pretending it didn’t happen.  We also dissected other
failed and struggling languages of the time like NESL, Sisal, Cilk,
ZPL, UPC, {{<sidenote "right" "Coarray Fortran" -4>}}Today, I wince a
bit at the inclusion of Coarray Fortran in this list given that my
Fortran-oriented colleagues would rightly point out that co-arrays were
incorporated into the Fortran 2008 standard and have found an
audience.  Our team did learn from Coarray Fortran, but whether it was
struggling at the time feels unclear to me now.{{</sidenote>}}, and
Titanium.  And we took lessons from each of them.

One of the things that’s interesting about performing a postmortem on
HPF is that if you ask a dozen people why it failed, you’ll get a
variety of answers.  In my personal opinion, HPF didn’t have any
single fatal flaw, but failed due to a combination of factors.  I’ll
list some of the main ones here, and summarize our response to them in
Chapel.

###### “HPF did not achieve sufficient performance fast enough”

This is perhaps the most frequently cited reason given for HPF’s
failure, and one that’s compounded by the promise of the appearance of
“High Performance” in its name.  While this was certainly a factor in
HPF’s demise, in my opinion it wasn’t the fatal flaw that some would
claim it to be.  Although HPC is an impatient community by nature, I
believe that if there had been a brighter light at the end of the
tunnel, the community would have worked through its impatience.  In
our work on Chapel, we share a similar threat of losing potential
users’ interest
{{<sidenote "right" "by not achieving the performance they ultimately want" -9>}}
This definitely was a challenge for us in the years
since this article was published.  While current Chapel performance
typically competes with or beats Fortran or C++ with MPI, many who
tried it prior to ~2019 formed negative impressions of it that have
stuck, while also influencing the views of others who have never tried
Chapel themselves.{{</sidenote>}} quickly enough.  To work past that,
we encourage users to reason about whether there are features in Chapel
that will inherently prevent it from achieving good performance
(instead of simply
{{<sidenote "right" "taking a stopwatch to its current performance" 7>}}
Happily, unlike 2012, we no longer have to ask people to reason about
whether we're on a path to good performance—now, they can just try
Chapel and time it themselves.  Of course, there are still a few areas
where Chapel's performance does not yet reflect its potential, so if
users are disappointed, we encourage them to engage with us to
understand the cause and check whether it's an area where further
improvements are planned.{{</sidenote>}} and judging it based on
today’s status).  This can be a hard sell since it requires more
intellectual effort; yet users who bother with it typically agree that
while Chapel’s design is aggressive, it is not inherently flawed with
respect to its potential to generate competitive performance.  If it
is, we’d surely like to hear about it to address those flaws.

###### “HPF left too much unspecified in its execution model, resulting in challenges to portable performance”

This was the rallying cry within the ZPL group in which several
members of the Chapel team (myself included) worked in the 1990’s [2].
Our observation was that the HPF specification provided very few
guarantees about how a given HPF program would be executed; that its
directives were essentially hints that could be ignored by the
compiler; and that when programs contained underspecified or
contradictory directives, the language gave little guidance as to what
a user could expect to happen.  This hypothesis was borne out as
multiple HPF compilers began to emerge, and programs needed to be
tuned for each one independently [3].  In Chapel, as in ZPL, we have
strived to avoid this pitfall by being far more explicit about 
{{<sidenote "right" "how the language will be implemented" 6>}}
A great example of this is Chapel's <code>forall</code> loop, which
many casual users assume relies on compiler smarts or
auto-parallelization.  In reality, Chapel's <code>forall</code> loop
is just a stylized call to a parallel iterator written in the
language, either as part of the standard library or by end-users.  As
a result, its behavior can be reasoned about very
explicitly.{{</sidenote>}} so that programmers have a concrete
execution model to guide their use of its features.

{{<pullquote>}}
In Chapel’s design, we built our data-parallel features on a
foundation of task-parallel and concurrent programming concepts in
order to support arbitrary mixing and nesting of different styles of
parallelism within a single program.
{{</pullquote>}}


###### “HPF only supported a single level of data-parallelism, and no support for task-parallelism, concurrency, or nested parallelism.”

The argument here is that while HPF contained reasonably attractive
data-parallel features that supported some important common cases,
many real-world computations contain other styles of parallelism and
concurrency, as well as opportunities for nested parallel regions.
For this reason, in Chapel’s design, we built our data-parallel
features on a foundation of task-parallel and concurrent programming
concepts in order to support
{{<sidenote "right" "arbitrary mixing and nesting of different styles of parallelism">}}
This also turned out to be invaluable for GPU computing, which I'll
come back to later on.{{</sidenote>}} within a single program.
This permits us to support the general case and optimize for the
common case of data parallelism rather than only supporting the common
case.


###### “HPF supported only a fixed set of distributions on dense arrays”

Though attractive, HPF’s data-parallel features also had drawbacks,
the most commonly-cited one being that if you didn’t like the handful
of distributed array formats that it supported, you had no recourse
other than to lobby for the inclusion of additional distributions in
subsequent drafts of the language.  In Chapel, we are addressing this
limitation by: (i) supporting a rich set of array types including
multidimensional, sparse, associative, and unstructured arrays; (ii)
permitting end users to implement local and distributed parallel
arrays within Chapel itself [4]; and (iii) writing standard array distributions
{{<sidenote "right" " using the same mechanism that an end-user would" -3>}}
This was arguably the biggest barrier to Chapel achieving better
performance sooner.  Building array capabilities from scratch within
the language itself and getting performance that could compete with
all the longstanding languages whose arrays were built-in put us at a
significant performance disadvantage.  It took us years to close the
gap to an acceptable level, and that delay to achieving performance
led to a lot of doubt and cynicism around Chapel in the 2010's, some
of which persists to this day.  However, this approach was also an
investment that has paid off—for example, the recently-added sparse
features and optimizations [mentioned last month]({{<relref 10myths-part1>}}#the-sparse-example) were
made with no changes to the compiler thanks to this
approach.{{</sidenote>}}, with the goal of avoiding a performance
cliff between “built-in” and user-defined distributions.

###### “HPF did not provide sufficient mechanisms for the user to drop to lower, more explicit levels of control”

This is closely related to the last few items, the point being that if
and when HPF’s high-level language abstractions failed you, there
wasn’t much recourse other than abandoning the language and reverting
to MPI.  Chapel uses a philosophy we call _multiresolution language
design_ to address this, in which high-level data-parallel features
are specified within the language in terms of lower-level features for
task parallelism and locality control.  This permits users to move up
and down the layers of abstraction as required by their algorithms or
performance requirements.

###### “HPF lacked an open-source implementation”

To be fair, HPF was being developed at a time when open-source
software was not as commonplace in HPC as it is today.  Nevertheless,
one must suspect that a community-based, open-source compiler may have
helped it evolve past some of these other limitations.  By the time we
started Chapel’s development, it was well-understood that a language
would not be adopted without a free, portable, open-source
implementation, so that’s what we set out to build from day one.  To
my thinking, it is regrettable that so much money and effort was
invested in HPF, yet the community doesn’t have an open-source
compiler artifact to represent or re-evaluate that effort today.

{{<pullquote>}}
Our plan is to keep striving to make Chapel worthy of being called
your favorite scalable parallel programming language.
{{</pullquote>}}

It obviously remains to be seen whether Chapel will be considered a
success or another disappointing failure.  As we pursue it, people
often wonder why we even bother trying, given the long odds a new
language has for being adopted.  For me, the answer is the simple one:
If, as a community, we want to have better scalable parallel
programming languages, we need to keep striving forward no matter what
the odds are.  And because even if Chapel ultimately fails, it will
have provided some new lessons along the way that should help
influence future language designs, much as the lessons of HPF, NESL,
ZPL, and others influenced ours.  For a language designer, this result
should also be considered a success, simply one in another guise.
Having said that, our plan is to keep striving for the higher goal of
making Chapel worthy of being called your favorite scalable parallel
programming language.

This leads to my conclusion for this month:

##### Counterpoint #2: Past language failures do not dictate future ones; moreover, they give us a wealth of experience to learn from and improve upon.

Tune in next time for more myths about scalable parallel programming
languages.


#### References

[1] K. Kennedy, C. Koelbel, and H. Zima. [The rise and fall of High
Performance Fortran: an historical object
lesson.](https://dl.acm.org/doi/10.1145/1238844.1238851) In
Proceedings of the third ACM SIGPLAN conference on History of
programming languages (HOPL III), 2007.

[2] L. Snyder, [The design and development of
ZPL.](https://doi.acm.org/10.1145/1238844.1238852) In Proceedings of
the third ACM SIGPLAN conference on History of programming languages
(HOPL III), 2007.

[3] T. Ngo, L. Snyder, and B. Chamberlain. Portable Performance of
Data Parallel Languages. In Proceedings of the 1997 ACM/IEEE
Supercomputing Conference on High Performance Networking and Computing
(SC97), November 1997.

[4] B. L. Chamberlain, S.-E. Choi, S. J. Deitz, D. Iten, V. Litvinov,
[Authoring User-Defined Domain Maps in
Chapel](https://chapel-lang.org/publications/cug11-final.pdf), CUG
2011, May 2011.

---

### Reflections on the Original Article

#### Datedness of HPF focus (or not?)

This month's article doesn't feel quite as timeless as the [previous
one]({{<relref 10myths-part1>}}) due to its focus on HPF.  Today, I
would guess that most programmers, HPC or otherwise, are not
particularly aware of HPF or concerned about its failure.  While the
characterizations of Chapel made in the article are still accurate and
important, and capture key ways in which we learned from parallel
languages that preceded us, focusing on HPF may be less motivational
to a contemporary audience than it was in the early 2000's.

That said, it is definitely still possible to find people of my
generation or older who feel burned by the HPF experience and mistrust
working on new parallel languages as a result.  One of my teammates
attended an invited talk in the past few years in which the speaker
lamented the resources wasted on HPF, citing its lack of task
parallelism and reliance on fusing whole-array operations as
contributing to its failure.  As touched on above, these are lessons
that Chapel learned from HPF and improved upon by supporting task
parallelism, explicit parallel loops, and a zippered interpretation of
whole-array operations.

{{<details summary="**(A zippered interpretation of whole-array operations?)**">}}

To clarify what I mean here without distracting too much from the
article's flow, most languages with support for whole-array
operations define an array statement like:

```chapel
A = B * C + sin(D);
```

as meaning:

```chapel
T1 = B * C;
T2 = sin(D);
A = T1 + T2;
```

The introduction of these temporary arrays, `T1` and `T2`, can lead to
many more memory operations, slowing the application down while
increasing the program's memory footprint.  They can be optimized away
using transformations such as
{{<sidenote "right" "_loop fusion_ and _array contraction_">}}See, for
example, [The
implementation and evaluation of fusion and contraction in array
languages](https://dl.acm.org/doi/10.1145/277652.277663) by E Christopher Lewis, Calvin Lin, and Lawrence Snyder
in <i>Proceedings of the ACM Conference on Programming Language Design
and Implementation</i>, 1998.{{</sidenote>}}, resulting in performance
that competes with hand-generated loops.  But these optimizations can
be non-trivial to implement in a general purpose language like HPF.

In Chapel, whole-array operations are defined using a _zippered_
parallel iteration over all the arrays, avoiding the need for
temporary arrays:

```chapel
forall (a, b, c, d) in zip(A, B, C, D)
  a = b * c + sin(d);
```

This results in great performance without relying on optimizations by
improving locality and cache utilization.  Moreover, programmers can
write such zippered loops and parallel iterators themselves, providing
far more control over array computations than in HPF or other parallel
languages.

{{</details>}}

The speaker also voiced a concern that was not addressed in my
original article, which was that new languages require every vendor to
invest effort implementing them—and this was certainly the approach
taken with HPF in the 90's.  However, it's not something that needs to
be the case for well-designed languages and compilers.

In the case of Chapel, though its development has been led by
Cray/HPE, we have always strived to run on systems and chips from as
many vendors as we have had access to, including early runs on Sun and
IBM systems during the HPCS years.  Chapel currently supports Intel,
AMD, and Arm CPUs, various networks including InfiniBand and Ethernet,
and {{<sidenote "right" "NVIDIA and AMD GPUs" -4>}}Apple and Intel GPUs
represent additional cases we would like to support going
forward{{</sidenote>}}.  All of this has been achieved without
explicit support from the respective vendors.

A key factor in our ability to achieve this kind of portability is the
LLVM compiler infrastructure.  Since Chapel's inception, LLVM has
become a mature and broadly adopted open-source compiler that many
vendors have invested in.  Because Chapel uses LLVM as {{<sidenote
"right" "its preferred back-end compiler" -4>}}Generating C is also an
option for non-GPU targets.{{</sidenote>}}, any vendor whose chips are
supported by LLVM—whether through their investment or the
community's—can also be supported by Chapel.  Moreover, this
typically {{<sidenote "right" "should">}}Vendors with more exotic
hardware may need to use or define a dialect of MLIR, working to
ensure that the Chapel compiler can target it.{{</sidenote>}} involve
no additional effort on the vendor's part beyond what they needed to
do to support C.

It's important to note that since Chapel has also been developed as an
open-source project, a vendor who wants to improve Chapel's support
for their systems could do so within the community code base, or by
creating their own fork of it, rather than starting from scratch as so
many vendors did for HPF in the 90's.


#### The rise of GPU computing

As mentioned in the 2012 article, we always felt it was crucial that
Chapel support task parallelism and nested parallelism, since many
parallel computations can't be expressed using just a single level of
data parallelism.  However, one unanticipated outcome of this is that
as GPU computing has begun dominating HPC–a trend that was starting
right around the time this article was originally published–Chapel did
not require a massive redesign due to its support for
data-parallelism, task-parallelism, and locality control.  To make
clear just how unanticipated GPU computing was at Chapel's outset,
note that its core features for parallelism and locality—which still
form the backbone of the language today—were designed before multicore
processors had even become commoditized and commonplace.  At that
time, we were focused exclusively on single-core processors,
distributed-memory computing, and the vector and multithreaded
processors of the Cray X1 and XMT.

Chapel has remained relevant across all of these architectural changes
because {{<sidenote "right" "parallelism" -2>}} "What should run
concurrently?"  {{</sidenote>}} and {{<sidenote "right" "locality"
2>}} "Where should these computations run?"  "Where should these
variables be allocated?"{{</sidenote>}} are so fundamental to scalable
parallel computing.  As a result, the same core features designed for
expressing parallelism and locality on the clusters, X1, and XMT of
the early 2000's did not have to change as multicore and GPU
processing became dominant.  Contrast this with MPI, which was not
well-suited for GPU computing.  Or with OpenMP, which had to change
from being a semantically neutral markup notation for parallelism to
a far more imperative and embedded mini-language of its own.  And then
there are all of the brand new notations that were developed specially
for GPU programming to address these gaps (CUDA, HIP, SYCL, OpenACC,
OpenCL, ...).

For Chapel, the biggest challenge to supporting GPUs was less about
expressing the computations and more about generating code
(instructions) for them.  Happily, this has been another area where
LLVM's success as a community compiler back-end has made a huge
difference.  To learn more about GPU computing in Chapel see [this
series of blog articles]({{<relref gpu-programming-in-chapel>}}).


#### More Departed Parallel Languages

Before wrapping up, I want to acknowledge that since the original
publication date of this month's article, two additional noteworthy
parallel languages have fallen by the wayside—specifically, Chapel's
two peer languages within the DARPA HPCS program: Fortress from Sun
Microsystems and X10 from IBM.  Fortress began closing up shop in
2012, a few months after this article was originally published, when
Guy Steele wrote a blog post entitled [_Fortress Wrapping
Up_](https://web.archive.org/web/20160924201206/https://blogs.oracle.com/projectfortress/entry/fortress_wrapping_up).
X10 stuck around for several more years, and it still has [a presence
on GitHub](https://github.com/x10-lang), but its last release was in
January 2019, and very few commits have been made since then.

An obvious theme of this month's reprint was about learning from past
languages; but one of the highlights of my professional career was
interacting with the technical members of the X10 and Fortress teams
to hear about what they were pursuing in their language designs, and
to learn from them in real-time rather than postmortem.  I'm
particularly remembering a multi-day workshop that John Mellor-Crummey
hosted at Rice, in which our three teams were able to dig into several
of the choices we were making in our languages in detail, discussing
the tradeoffs and getting real-time feedback from HPC programmers in
the room.  At that point in my career, I thought this would be a
common occurrence, but it has become far too rare in the years since
HPCS started wrapping up.  The lack of such cross-language forums for
users has been to the detriment of parallel programmers worldwide, in
my estimation.

To that end, thanks in particular to Guy Steele, Jan-Willem Maessen,
Eric Allen, and Victor Luchangco at Sun/Oracle, and to Vivek Sarkar,
Vijay Saraswat, Dave Grove, and Josh Milthorpe at IBM for all the good
language design discussions during those years, and the positive
impact they had on Chapel.


### Wrapping Up

That wraps up this month's article.  While its focus on HPF may seem
dated, I think the content remains interesting by capturing some of
the ways in which Chapel learned from HPF's example, improved upon it,
and has enjoyed much more longevity as a result.  Today, Chapel is
being used to develop performance-critical applications across diverse
fields by [many different users]({{<relref
7-questions-for-chapel-users>}}).

It's also interesting to consider how much the parallel computing
landscape has changed in the past 13 years, from the advent and
dominance of GPU computing to the rise of cloud computing and AI.
Chapel's focus on expressing general parallelism and locality has
permitted it to remain relevant across all these changes, and I expect
that those fundamentals will continue to be of crucial importance in
the years to come as well.

Next month, we'll revisit the third article in the series, which
wrestles with the tradeoffs between creating new languages versus
extending existing ones.
