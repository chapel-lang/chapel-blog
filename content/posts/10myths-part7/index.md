---
title: "10 Myths About Scalable Parallel Programming Languages (Redux),  Part 7: Minimalist Language Designs"
richtitle: "10 Myths About Scalable Parallel Programming Languages (Redux)<br>  Part 7: Minimalist Language Designs"
date: 2025-10-15
tags: ["Editorial", "Archival Posts / Reprints", "Language Comparison"]
series: ["10 Myths About Scalable Parallel Programming Languages Redux"]
summary: "The seventh archival post from the 2012 IEEE TCSC blog series, with a current reflection on it"
authors: ["Brad Chamberlain"]
---

### Background

In 2012, I wrote a series of eight blog posts entitled "Myths About
Scalable Parallel Programming Languages" for the IEEE Technical
Community on Scalable Computing&nbsp;(TCSC).  In it, I described
discouraging attitudes that our team encountered when talking about
developing Chapel, and then gave my personal rebuttals to them.  That
series has generally been unavailable for many years, so for its 13th
anniversary, we're reprinting the original series here on the Chapel
blog, along with new commentary about how well or poorly the ideas
have held up over time.  For a more detailed introduction to both the
original series and these reprints, please see [the first
article]({{<relref 10myths-part1 >}}) in this series.

This month, we're reprinting the series' seventh article, originally
published on October 15, 2012.  Comments in the sidebar and [the
sections that follow the reprint]({{<relref
"#reflections-on-the-original-article">}}) give a few of my current
thoughts and reflections on it.

---

### The Original Article, Reprinted

Myths About Scalable Parallel Programming Languages:<br>
Part 7: Minimalist Language Designs
{.big}


This is the seventh in a series of blog articles that I’m writing with
the goal of describing and responding to some of the misconceptions
about scalable parallel programming languages that our team encounters
when describing our work designing and implementing Chapel
(https://chapel-lang.org)

For more background on Chapel or this series of articles, please refer
to [part 1]({{< relref 10myths-part1
>}}#the-original-article-reprinted); subsequent myths are covered in
parts [2]({{< relref 10myths-part2
>}}#the-original-article-reprinted), [3]({{< relref 10myths-part3
>}}#the-original-article-reprinted), [4]({{< relref 10myths-part4
>}}#the-original-article-reprinted), [5]({{< relref 10myths-part5
>}}#the-original-article-reprinted), and [6]({{< relref 10myths-part6
>}}#the-original-article-reprinted).


#### Myth #8: To be successful, scalable parallel programming languages should be small/minimal.

A {{<sidenote "right" "fairly common notion">}}(or so it seemed to me
in 2012, at least... let's return to this [below]({{<relref
"#reflections-on-the-original-article">}})){{</sidenote>}} in parallel
programming language design is that developing a small language with a
minimal set of features is ideal.  While I would agree that language
developers should avoid the temptation to put every feature that they
think of into the language, for fear of creating a kitchen sink
design, I also believe that the value placed on minimal language
design can often be overrated.


#### A Case Study in Minimalism: Co-Array Fortran

One rationale for minimalism in language design is to simplify the
implementation.  And this is a worthy goal since {{<sidenote "right"
"many proposed languages" -2>}}You may be wondering, as I am while
re-reading this tonight, what languages I was referring to here.  I
imagine that High-Performance Fortran (HPF)—[discussed earlier in this
series]({{< relref 10myths-part2 >}})—was at the top of my mind.  That
said, it may be that Fortress—one of our sibling languages in the
DARPA HPCS program—may have been as well.  The Fortress team had just
announced that it was winding down the project a few months before I
published this; and of the three HPCS languages, it felt the most
expansive and audacious in design to me.  Beyond those two, there were
dozens of other failed parallel programming languages in the 1990's,
and I imagine my use of "many" refers to them.  That said, today I
find myself wondering how many of them failed to gain broad adoption
due to complexity, as opposed to other reasons.{{</sidenote>}} have
failed for being more complex than their implementations could handle
or optimize for.  But the danger of being too minimal is that the
language may not be sufficiently general or productive to be
attractive and adopted by the user community.

One of my favorite minimal languages is Co-Array Fortran (CAF)
[[1]({{<relref "#bibliography">}})].  CAF set out to define the
smallest change required to Fortran to make it an effective parallel
language; CAF was originally given the clever name F–– to emphasize
what a small change it constituted [[2]({{<relref
"#bibliography">}})].  And to my thinking, it succeeded in this goal.
CAF’s core extension to Fortran is a very simple, elegant, and
powerful concept known as the _co-dimension_.  CAF programs are
written and executed in a Single-Program, Multiple-Data (SPMD) manner,
and _co-arrays_—variables with a co-dimension—permit the user to refer
to the copies of the variable stored by other _images_—the other
copies of the program within the SPMD execution.  For example, the
expression `a[i]` refers to the copy of the scalar variable `a` stored
by the `i`th instance of the SPMD program execution.  Note that the
use of square brackets for co-array dimensions syntactically
distinguishes them from Fortran’s use of parentheses for traditional
array indexing.

{{<pullquote>}}

Adopting any new technology requires time and effort from potential
users. In order to consider this investment worthwhile, users will
weigh the technology’s expected payoff against the effort required.

{{</pullquote>}}

Given the widespread adoption of SPMD programming models,
co-dimensions represent a very natural and elegant way to support
communication between program instances.  Like other PGAS languages,
CAF supports single-sided communication, which can improve execution
times by eliminating buffering and by decoupling data transfer from
synchronization.  Moreover, the use of square brackets in CAF makes
these communication events “pop” syntactically so that {{<sidenote
"left" "programmers">}}And compilers, for that
matter...{{</sidenote>}} can determine where their algorithms require
communication, and then work to eliminate unnecessary cases.  While
co-arrays are the core concept in CAF, the language also supports
other features to help with SPMD programming such as routines for
synchronization and collectives.

In spite of its elegance, CAF has failed to be adopted as broadly as
its proponents had hoped (so far, anyway—its inclusion in the Fortran
2008 standard [[3]({{<relref "#bibliography">}})] could improve that
situation {{<sidenote "right" "over time" -14>}}If it seems odd that I
was writing speculatively about the future of Fortran 2008 in 2012,
keep in mind that Fortran 2008 wasn't approved until 2010, and even
then there can be a lag between finalizing a language standard and
having compilers support all of its new features (not to mention
getting users to start using those new features).

While I understand Fortran 2008 to have enjoyed some amount of uptake
since I originally wrote this article, I think few would consider its
coarray features to have achieved _broad_ adoption---and certainly
nowhere near the level of MPI.  Then again, nothing else has either
(yet...!).{{</sidenote>}}).  Several explanations have been offered
for its lack of adoption, such as the dearth of mature implementations
or disappointing performance portability due to the lack of good
support for fine-grained, single-sided communication in many network
architectures.  These are almost certainly factors contributing to the
lack of CAF adoption, but in my opinion, the biggest strike against
CAF is the one that was intended to be its strength: its minimalism.

Adopting any new technology requires time and effort from potential
users.  In order to consider this investment worthwhile, most users
will weigh the technology’s expected payoff against the effort
required.  My sense is that in evaluating the cost::benefit ratio of
switching from MPI to CAF, most users conclude that the benefit in
expressing communication more elegantly is not sufficiently valuable
to make the conversion worthwhile.  As in most MPI programs, CAF’s
SPMD model requires a certain amount of bookkeeping code that incurs
programming effort regardless of how nicely the communication is
expressed.  In fact, I would claim that any parallel programming model
which requires SPMD programming from its users is unlikely to supplant
MPI, simply because {{<sidenote "right" "the bookkeeping overheads"
-4>}} [Last month's
article](https://chapel-lang.org/blog/posts/10myths-part6/#the-original-article-reprinted)
gave some high-level indications of the syntactic overheads of
SPMD-oriented bookkeeping, but didn't really illustrate them very
clearly.  I'll attempt to remedy this with a simple example in the
[discussion section below]({{<relref
"#an-spmd-bookkeeping-example">}}).{{</sidenote>}} of SPMD programming
outweigh the benefits of an incrementally more attractive SPMD
notation.  So why risk switching away from something that has proven
so effective?

CAF also has rules governing its SPMD execution that are stricter than
MPI’s.  For example, CAF constrains how co-array declarations must be
encountered in order to maintain a symmetric heap across program
images.  Meanwhile, powerful MPI concepts like communicators—useful
for referring to subsets of the program images—{{<sidenote "right"
"do not have a natural counterpart in CAF">}}It's important to note
that Fortran 2018 has since addressed this specific concern by adding
support for _teams_, which permit the complete set of program images
to be subdivided into groups.  For example, slide 63 of [this
presentation](https://stevelionel.com/drfortran/wp-content/uploads/2022/08/Modern-Fortran.pdf)
illustrates a conceptual use of teams to execute distinct parts of a
coupled climate model---the same motivator I used here.{{</sidenote>}}.
The combination of these factors makes CAF best when writing
algorithms in which all the program images are computing the same
thing, whereas MPI programs can more easily create general teams of
processes that are doing completely different things, as in a coupled
climate model.  The net result is that for a slight boost in
programmability, the CAF user must give up a certain amount of
flexibility and generality, or at least ease-of-use.  My impression is
that for most potential users, this tradeoff does not come out in
CAF’s favor and therefore does not warrant switching away from MPI—the
rewards are simply not great enough to outweigh the liabilities.  I’d
also argue that it was CAF’s self-imposed minimalism that limits those
rewards; that it chose to focus on supporting a common case rather
than supporting the more general case and optimizing for the common
one.

{{<pullquote>}}

In creating Chapel, our goal wasn’t to do an academic study or publish
some papers, but to create a parallel programming language that could
plausibly be adopted to write a broad spectrum of real-world HPC
computations.

{{</pullquote>}}

#### Academic vs. Deployed Languages

As anyone who’s investigated it knows, Chapel is not a particularly
minimal language.  It has distinct concepts for data and task
parallelism, a rich set of array types, locality abstractions, and a
very rich base language with support for {{<sidenote "right"
"object-oriented programming">}}Chapel's object-oriented features have
become even less minimal since this article was written, with the
addition of class memory management types and nilable vs. non-nilable
class types.  Both of these were added based on feedback and requests
from users, reflecting features that had become popular in Rust and
Swift, not to mention modern C++.{{</sidenote>}}, iterators, ranges,
and type inference.  When we started work on Chapel, I recall a
colleague of Hans Zima’s expressing concern that by undertaking such a
rich language, we not only risked failure, but also the possibility of
not being able to determine _why_ we had failed due to the multitude
of features.

In my mind, this concern is a wise one to keep in mind for academic
projects.  In a scientific study, it makes sense to change the fewest
number of things possible—ideally one—so that you can measure the
effects of that change against the status quo.  In a sense, this is
what made ZPL a successful academic project: it focused on the design
of a language with support for array-based parallel programming with
the goal of a syntax-based (“WYSIWYG”) performance model
[[4]({{<relref "#bibliography">}})].  In pursuit of this goal, it
didn’t support task parallelism, nested parallelism, object-oriented
programming, or even a particularly modern syntax or base language.
This focused its research agenda but, in my opinion, made it
essentially unadoptable.  It simply wasn’t general enough to support
the complexities of real parallel applications.

In creating Chapel, our goal wasn’t to do an academic study or publish
some papers, but to create a parallel programming language that could
plausibly be adopted to write a {{<sidenote "right"
"broad spectrum of real-world HPC computations">}}The broad range of
applications that Chapel has been used for since this article was
originally published is one of the things I am most proud of and
gratified by.  In recent years, users have successfully applied Chapel
to fields as diverse as astrophysics, computational fluid dynamics,
satellite image analysis, climate research, hydrological modeling,
quantum physics, branch-and-bound computations, large-scale data
science, and AI.  Read more about such examples in our [7 Questions
for Chapel Users]({{<relref 7-questions-for-chapel-users>}}) series,
as well as the Chapel website's
[papers](https://chapel-lang.org/papers/) and
[presentations](https://chapel-lang.org/presentations/)
pages.{{</sidenote>}}; and in doing so, to add value in the form of
productivity far beyond what existing HPC programming models provide.
To us, this suggested creating a language that strives to be at least
as rich as the most productive desktop languages (e.g., {{<sidenote
"left" "Java, C#, Python, Matlab">}}Though they weren't around when
we were first designing Chapel, I would add languages like Rust,
Swift, and Julia to this list if we were starting out
today.{{</sidenote>}}), that can do anything MPI can do, that offers
an alternative to SPMD programming, and that adds significant value to
a parallel programmer (in terms of clarity, abstractions, conciseness,
etc.).  To expect such a language to be minimal strikes me as being
naïve.  Or, as one of my colleagues says when Chapel is accused of
being too feature-rich: “Go big or go home!”

{{<pullquote>}}

Most computer users, certainly HPC programmers, use large complex
software systems every day without being paralyzed by the large number
of features.

{{</pullquote>}}

#### Overwhelming the User?

One of the reasons that I believe people get nervous about
feature-rich languages is the learning curve.  There is a sense that
large languages will overwhelm users, compromising the languages'
adoptability.  While I understand this concern, I don’t share it.
Most computer users, certainly HPC programmers, use large complex
software systems every day without being paralyzed by the large number
of features.  LaTeX, the bash shell, UNIX, C++, MPI, and GNU Make are
all examples of powerful, adopted software systems that are also quite
large and feature-rich.  One can imagine more minimal counterparts to
these technologies, yet the size of these systems has not been a
liability in their adoption, and in fact has been a strength.  A key
characteristic is that users can utilize them effectively without
being familiar with every single feature (or, in many cases, a
significant fraction of them).

So what does this tell us?  To me, it suggests that it is more
important to support a rich set of features than to be minimal; and
that to be effective, there should be a core set of features that are
approachable and useful without requiring the user to be familiar with
every single feature.  Arguably, another important characteristic of
these systems is {{<sidenote "right" "good documentation">}}I'll touch
on the state of Chapel's documentation in 2012 versus today in the
[discussion section below]({{<relref
"#chapel-documentation">}}).{{</sidenote>}} that enables a user to
find and learn about additional concepts as they need them.

Again, I don’t mean to suggest that language designers should adopt
every idea that occurs to them; care should be taken to select
features that add power and benefit by inclusion in a language,
particularly ones that result in better syntax or optimization
opportunities.  Otherwise, the feature is probably more appropriate as
a standard library feature rather than a core language concept.  That
said, in the case of general and scalable parallel languages, we
should fully expect that in order to be adoptable, such languages are
likely to require at least as many features as our best serial or
desktop languages.

This brings us to this month’s conclusion:


#### Counterpoint #8: Many of the successful software systems we use are large in order to be general and productive.  More important than minimalism is the language’s approachability and documentation—i.e., can one make effective use of it without being familiar with all of its features?

Tune in next time for the final myths in this series about scalable
parallel programming languages.


#### Bibliography

[1] R. Numerich, J. Reid, [Co-array Fortran for Parallel
Programming](https://dl.acm.org/doi/10.1145/289918.289920), SIGPLAN
Fortran Forum 17:2, pp. 1–31, August 1998.

[2] R. Numerich, [F––: A Parallel extension to Cray
Fortran](https://www.researchgate.net/publication/220061034_F--_A_Parallel_Extension_to_Cray_Fortran),
Scientific Programming 6:3, pp. 275–284, 1997.

[3] R. Numerich, J. Reid, [Co-arrays in the next Fortran
Standard](https://dl.acm.org/doi/10.1145/1080399.1080400), SIGPLAN
Fortran Forum 24:2, pp.&nbsp;4–17, August 2005.

[4] B. Chamberlain, S.-E. Choi, E Lewis, C. Lin, L. Snyder,
W. Weathersby, [ZPL’s WYSIWYG Performance
Model](https://research.cs.washington.edu/zpl/papers/data/Chamberlain98ZPL.pdf),
HIPS '98: Proceedings of the IEEE Workshop on High-Level Parallel
Programming Models and Supportive Environments, 1998.



---

### Reflections on the Original Article

Re-reading the original article today, I wonder whether this myth is
one that will resonate at all with modern readers.  As one of my
colleagues points out, currently popular languages like Python, Julia,
and Rust are definitely in the "feature-rich" category rather than
being minimal.  Meanwhile, each new version of C++ adds lots of new
features to what was already a fairly sizable language.  So perhaps
whatever preference toward minimalism I was reacting to in 2012 either
no longer exists, or was somehow specific to the HPC community.

In any case, my belief in bigger, more general languages that can be
learned incrementally remains as strong today as it was in back
then---particularly for scalable parallel programming.  In this
section, I'll reflect on why this is and what I think about Chapel's
current size and features. Then I'll touch on the state of Chapel
documentation and wrap up with an illustration of the bookkeeping
that's required by SPMD programs.

{{<pullquote>}}

There are very few features provided by typical, mainstream, adopted
programming languages that can be ignored in a language for scalable
parallel computing.

{{</pullquote>}}

#### Chapel's Size and Feature Set

While people sometimes reel at how large and feature-rich Chapel is,
the closing statement of the article remains true for me: That there
are very few features provided by typical, mainstream, adopted
programming languages that can be ignored in a language for scalable
parallel computing without compromising generality or adoption.  And
then, beyond those features, you must add additional capabilities to
express the parallelism and locality required for scalable parallel
applications, ideally in a way that supports performance,
optimization, and clarity.

Generally in Chapel, when we've tried to ignore, or at least put off,
incorporating certain traditional language features in hopes that they
are non-essential ("for now"), users have typically called us on it.
Specific cases of this include error-handling, first-class procedures,
record initializers, and automated memory management for classes—all
of which have now been added to the language and implemented based on
user requests.  A few areas that have been neglected remain sore
points, such as the lack of `ref` fields and Chapel's not-yet-complete
support for interfaces.

Meanwhile, I think it's worth stressing that when it comes to core
features that introduce parallelism and control locality, Chapel is
more minimal than it might first appear.  There are exactly three
keywords in the language that introduce new parallel tasks (`begin`,
`cobegin`, and `coforall`) and one keyword that indicates the
potential for hardware parallelization like vectorization (`foreach`).
There is also just one keyword to transfer a task's execution or
declaration context to another locale (`on`).

Most of Chapel's complexity with respect to parallelism relates to its
user-facing mechanisms for creating new parallel abstractions, such as
{{<sidenote "right" "parallel iterators or distributions">}}Ironically,
these are also both features that would benefit from improvements to
the aforementioned lack of good support for interfaces{{</sidenote>}}.
However, many users never need to learn how to create these
abstractions, and those that do rarely need to do so from day one.
Meanwhile, beginning users benefit from the existence of these
abstractions whenever they declare a distributed array or invoke a
`forall` loop (either explicitly, or implicitly through features like
_promotion_).

Generally speaking, I feel very comfortable with Chapel's size, both
on its own terms, and relative to popular modern languages.  When I
think about features it contains that feel neglected, only two come to
mind.  The first is the `let` expression, which has been a part of the
language since its inception, yet which has rarely been used in
practice (while also having its share of detractors over the years).
Based on this experience, it seems like one of the least important
features in the language; though it also feels fairly innocuous.

The second is a (relatively) new feature, the `manage` statement,
which was introduced around four years ago.  Despite being popular and
anticipated when it was introduced, to my knowledge, it hasn't been
used much in practice.  That said, there are some current efforts to
add utilities based on `manage` to the standard library, and given the
feature's success in Python, I remain optimistic that their use will
grow in the coming years.

The fact that only these two examples come to mind after years of
using Chapel and supporting users with it is a big part of what makes
me feel that Chapel is not oversized.  And more to the point, we have
had key users express their gratitude that Chapel is very approachable
while also having additional depths when more control or complexity
is required, suggesting that the whole language need not be learned
to use it effectively.


#### Chapel Documentation

This month's article stresses the importance of good documentation in
learning a language.  This is an area where Chapel has made
outstanding strides since the article was originally written, though
more can, and should, still be done.

Looking back at Chapel {{<sidenote "right" "version 1.6">}}It's purely
coincidental that this past month's release was version 2.6.  There's
no logical relationship between the numerical symmetry and the
thirteen years that have passed between articles.{{</sidenote>}},
which was released just a few days after this article's publication,
it left a lot to be desired in terms of documentation.  It included
PDF versions of the language specification and quick-reference sheet.
It also had a couple dozen primer examples that were made available as
commented source code files that you could bring up in your editor.
Finally, it had 32 README-style text files, all of which were
maddeningly named `README.*` (`README.ibm`, `README.building`,
`README.atomics`, etc.), as though named by {{<sidenote "left"
"someone">}}(very likely me... but I'd like to think I've improved
since then){{</sidenote>}} who liked Lewis Carroll more than useful
file extensions.  Notably, we had no online, HTML, hyperlinked
documentation, and no search capability.  As it happens, Chapel 1.6
was also the first release to support a prototype of our `chpldoc`
tool that generates {{<sidenote "right" "HTML documentation">}} Even
so, we did not reach the point of using it to publish web-based
documentation for our library modules until [Chapel
1.11](https://chapel-lang.org/docs/1.11), 2-1/2 years
later.{{</sidenote>}} from comments in the code.

Contrast the state in 2012 with [Chapel's documentation
hierarchy](https://chapel-lang.org/docs/2.6/) today, where the
primers, technical notes, and specification are all rendered directly
online, along with our library modules.  There have also been many
significant improvements and resources that have been added over the
years, as tracked in the Documentation sections of our [CHANGES
file](https://github.com/chapel-lang/chapel/blob/main/CHANGES.md).  In
total, we now have over 370 distinct pages of HTML documentation, much
of which is indexed, and all of which is searchable.

Despite these great strides, documentation remains a place where
further investment and improvements would still be beneficial.  Chapel
would benefit greatly from a user's guide or textbook that provides a
more complete and readable introduction to Chapel.  We would also like
to have alternatives to written documentation, such as a library of
short videos that teach Chapel features and workflows, or an online
course for learning Chapel.  We've made some progress here in recent
years, by kicking off a monthly demo session, [archived on
YouTube](https://www.youtube.com/playlist?list=PLuqM5RJ2KYFjYgOStSfrNshIQ0I-AibHY);
"[how-to]({{<relref how-to>}})" articles on this blog, and a
[repository of code examples and
resources](https://github.com/chapel-lang/ChapelExamplesAndTeachingMaterials)
stemming from our monthly meet-up about teaching Chapel.  It seems the
task of improving documentation is never done; and simultaneously, it
is an activity that often feels difficult to prioritize or fund as
compared to adding the next language feature or optimization.  That
said, it remains crucial because of its importance in making the
language more approachable and usable.


#### An SPMD Bookkeeping Example

In [last month's article]({{<relref 10myths-part6>}}), we saw some
examples of how benchmark implementations in MPI, CAF, or SHMEM
required more code than in Chapel, SAC, or ZPL.  In that article, I
attributed this to the bookkeeping required by SPMD programming
models, yet did not take the time and space to describe the causes
well.  One of the nice things about CAF's minimalism and clean design
is that it can make this bookkeeping much clearer.

In this section, we'll look at a simple program that uses a Monte
Carlo method to compute an approximation of <small>$\pi$</small> in
both CAF and Chapel.  The program takes the approach of computing _n_
random coordinates and then seeing what fraction of them fall within a
quadrant of the unit circle.  Given that the quarter-circle's area is
<small>$1/4(\pi\cdot 1^2)$</small> and the square's is 1, we can
multiply the resulting ratio by four to get an approximation of
<small>$\pi$</small>.

Here is an implementation in CAF, with comments to guide you through
the code:

{{< file_download fname="pi.f90" lang="fortran" >}}

One thing I did in this program, which was admittedly lazy, was to
divide the global problem size, _n_, by the number of images running
the program as though it divides evenly, when it very well may not—and
then printing a warning when it doesn't.  With a bit more code and
care, I could've given the images varying local problem sizes such
that the total across images was _n_, as you would want in a real
application.  However, this would've required a bit more code while
making the same point—that care must be taken when dividing a global
problem space between images in the SPMD model.  In this case, where
the problem size merely acts as a local count and array size, the
bookkeeping is not so bad.  However, in cases where the problem size
matters—say the images are storing chunks of a dataframe or a
discretized volume—things can get more challenging, particularly when
each image must also know how many elements others own, as in a
stencil computation.

Summarizing the comments in the code above, ways in which SPMD
bookkeeping come up in this simple example include:

* storing and computing using distinct global vs. local problem sizes
* using conditionals to avoid doing redundant work on all images
* using explicit synchronization to ensure communication readiness
* using communication (co-array indexing here) to transfer data between images

All said, Fortran 2008's coarray features make the communication steps
far more concise and elegant than in MPI, demonstrating the benefits
of using a compiled parallel language over a library-based approach.
That said, the need for this additional bookkeeping remains, due to
requiring users to code using an SPMD model in the first place.

In Chapel, the same computation can be written as follows:

{{< file_download fname="pi.chpl" lang="chapel" >}}

Chapel obviates the need for such SPMD bookkeeping by virtue of:

* its global view of control flow, in which one task starts running
  the program rather than one per processor as in SPMD-based
  approaches

* its global-view arrays, in which a single logical array can be
  distributed across program images (_locales_) with all the
  bookkeeping and parallelization handled by the distribution.

The result is a program that much more closely resembles traditional
desktop programming.

At the same time, Chapel is general enough that explicit SPMD
patterns {{<sidenote "right" "can be written">}}Moreover, users can
even create coarray-like data structures in Chapel by creating
block-distributed arrays of arrays.{{</sidenote>}} when required.
This combination of abstractions and flexibility are part of what make
Chapel a large, rather than minimal language.  Yet, it's also why
Chapel can support compact, readable, performant code, while also
supporting manual overrides when desired.


### Wrapping Up

That concludes this month's look at the relationship between the size
of a language's feature set and its productivity and capabilities.
Next month, join us for the final article in the series, in which we
tackle our last two myths, relating to whether Chapel is perfect and
whether it will ultimately be broadly adopted.
