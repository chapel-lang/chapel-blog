---
title: "10 Myths About Scalable Parallel Programming Languages (Redux),  Part 8: Striving Toward Adoptability"
date: 2025-11-12
tags: ["Editorial", "Archival Posts / Reprints", "Community"]
series: ["10 Myths About Scalable Parallel Programming Languages Redux"]
summary: "The eighth and final archival post from the 2012 IEEE TCSC blog series, with a current reflection on it"
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

This month, we're reprinting the series' eighth and final article,
originally published on November 12, 2012.  Comments in the sidebar and
in [the sections that follow the reprint]({{<relref
"#reflections-on-the-original-article">}}) give some of my current
thoughts and reflections on it.

---

### The Original Article, Reprinted

Myths About Scalable Parallel Programming Languages:<br>
Part 8: Striving Toward Adoptability
{.big}


This is the last in a series of blog articles that I’ve been writing
with the goal of summarizing and responding to ten misconceptions
about scalable parallel programming languages that our team encounters
when describing our work designing and implementing the Chapel
language (https://chapel-lang.org).

For more background on Chapel or this series of articles, please refer
to [part 1]({{< relref 10myths-part1
>}}#the-original-article-reprinted); subsequent myths are covered in
parts [2]({{< relref 10myths-part2
>}}#the-original-article-reprinted), [3]({{< relref 10myths-part3
>}}#the-original-article-reprinted), [4]({{< relref 10myths-part4
>}}#the-original-article-reprinted), [5]({{< relref 10myths-part5
>}}#the-original-article-reprinted), [6]({{< relref 10myths-part6
>}}#the-original-article-reprinted), and [7]({{< relref 10myths-part7
>}}#the-original-article-reprinted).


#### Myth #9: The Chapel team believes that Chapel is perfect.

When developing a new parallel language that you’d like to see
adopted, a certain amount of time necessarily goes into
outreach—making the rounds to let people know what you’re doing and
why; and, in doing so, trying to get feedback from potential users.
When you’re out proselytizing for your language over a period of time
like this, it can often give the unfortunate impression that you
believe your design to be flawless.  And this, in turn, can have the
effect of becoming a barrier that prevents audience members from
keeping an open mind about your language if they find something flawed
or less-than-perfect about its design.



{{<pullquote>}}

We have made a number of design decisions with Chapel that have
improved its chances of adoption and forward portability, and this is
why I’m interested in persevering.

{{</pullquote>}}

In my opinion, all emerging languages of a certain size and
practicality are likely to have flaws, some due to a compromise that
was made in favor of another capability, others due to lack of
sufficient time or expertise within the design team to flesh out
certain feature areas, still others due to myopia caused by working
too close to the language.  In Chapel’s case, we’ve certainly had
missteps that fall into each of these categories.  {{<sidenote "right"
"Early users" -7>}}And not just early users; we've continued to get great
feedback from users in the years since this was originally written as
well.{{</sidenote>}} have pointed out seemingly obvious improvements
to which we’d become blind due to prolonged exposure to the language;
other features—exceptions and hierarchical representations of
locality, for example—were intentionally omitted from the original
design simply due to the fact that we knew our plate was already quite
full.  As we moved them to the back burner, we would refer to these as
“excellent features for {{<sidenote "right" "version 2.0" -5>}}Version
2.0 has now been released, and ended up containing both an
exception-handling capability and support for hierarchical locales,
most notably in support of [targeting GPUs]({{<relref
gpu-programming-in-chapel>}}).{{</sidenote>}}.”

Having occasionally encountered this attitude of “it’s not perfect, so
it’s not worth my time,” my suggestion to those who dismiss emerging
languages on such a basis would be to avoid considering any perceived
flaws in the language as a personal affront to your intelligence, or a
failed test that necessitates the language’s dismissal.  {{<sidenote
"right" "If one of our goals as a community">}}When I wrote this
series originally, I considered this to be a truism.  Today, I feel
less confident in that.  Let me come back to this in the [discussion
section below]({{<relref
"#reflections-on-the-original-article">}}).{{</sidenote>}} is to
create better parallel programming models over time, then the limited
time that any of us has would be better spent discussing such flaws to
help the language team improve upon them rather than writing off the
language simply due to the fact that it is imperfect.  Who among us
has ever done {{<sidenote "left" "flawless work">}}Re-reading this
paragraph today, and perhaps my whole response to this myth, I find it
a bit more defensive than I would like—but due to the archival nature
of the series, I'm avoiding the urge to edit myself.  I understand
what 2012-era Brad was feeling, because I still feel it with some
frequency today... but that's probably better as a discussion over
drinks.{{</sidenote>}}?

As described in [last month’s article]({{< relref 10myths-part7
>}}#the-original-article-reprinted), my personal belief is that any
plausibly adoptable scalable language is necessarily going to be quite
large; and for this reason, it’s not at all difficult for me to
believe that our modest-sized Chapel team has made mistakes and
oversights along the way.  As a result, it is always my intention to
be grateful when users point out perceived flaws constructively,
particularly when they already have a proposed solution in hand.

While I don’t think of Chapel as being perfect, and fully expect more
flaws {{<sidenote "right" "to be identified over time">}}Spoiler
alert after 13 additional years of experience: They have been, though
many have also now been resolved thanks to users pointing them
out.{{</sidenote>}}, I believe that most of these can be addressed as
we go.  I also believe that we have made a number of design decisions
with Chapel that have improved its chances of adoption and forward
portability compared to other parallel programming models; and this is
why I’m personally interested in persevering and striving to address
Chapel’s flaws rather than throwing in the towel and moving on.  Here
are some of the design choices that, in combination, I believe make
Chapel notable:

* **A multithreaded execution model:** The continuing dominance of
  static Single-Program, Multiple-Data (SPMD) execution models in a
  world that is increasingly dynamic and hierarchical seems like a
  significant problem to me, and a symptom of developing programming
  models that only support a common case rather than supporting the
  general case and optimizing for the common one.  In contrast, I
  think programming models like Chapel’s that support a fully dynamic
  execution model through multithreading, while still supporting SPMD
  as an important common case, are far better prepared to handle
  future architectures and algorithms.

* **Distinct concepts for parallelism and locality:** A related flaw
  that I think conventional parallel programming models share is that
  most have no way to talk about locality distinctly from parallelism
  (assuming locality is represented at all).  In MPI and UPC, for
  example, there is no way to create a parallel activity within the
  model without also creating a new process/thread, which also serves
  as the unit of locality within these models.  To the Chapel team’s
  thinking, {{<sidenote "right"
  "parallelism and locality are distinct properties" -5>}}I believe
  that this property, and the previous, are a large part of the reason
  that Chapel was able to adapt to the advent of GPU computing so
  seamlessly relative to other HPC programming models.{{</sidenote>}},
  and therefore should be treated as such within scalable parallel
  languages.

* **Support for a multiresolution design:** In our work, supporting a
  multiresolution language design means providing both higher- and
  lower-level features within a single language, permitting users to
  move between layers as necessary, or to provide their own
  implementations of {{<sidenote "right" "higher-level features">}}Or
  to call out to another language, like C or Python.{{</sidenote>}}
  [[1](#bibliography)].  This seems essential in any parallel language
  where productivity, performance, and forward portability are
  desired, since it provides a means of trading off abstraction for
  control, and for creating new abstractions that a compiler can
  reason about and optimize.

* **User-defined layouts, distributions, and parallel iterators:** In
  Chapel, I think the specific choice of permitting users to provide
  their own local and distributed array implementations [[2,
  3](#bibliography)], as well as the ability to control the
  implementation of data parallel loops [[4](#bibliography)] is
  incredibly important in terms of making the language
  forward-portable and adaptable to emerging parallel architectures
  and algorithms.

* **Unification of Data- and Task-Parallelism:** While most previous
  languages have restricted themselves to support either data- or
  task-parallelism, others have strived to support both, often
  resulting in a somewhat haphazard mash-up between the two feature
  sets.  Chapel’s approach of specifying data parallelism using task
  parallel features via its multiresolution design permit the two
  modes of parallelism to coexist quite well compared to previous
  efforts.

* **Productive base language features:** While Chapel’s base language
  features—type inference, generics, iterators, object-oriented
  programming, ranges, tuples, and the like—are clearly orthogonal to
  the key issues of parallelism, locality, and scalability that Chapel
  strives to address, I also consider them crucial for adoption.
  Being merely Turing-complete is all well and good, but creating a
  language that makes it tractable to write challenging code—such as
  distributed data structures—while also simplifying the creation of
  more straightforward code goes a long way toward improving user
  satisfaction.  I believe that such features can help bring about the
  tipping point that’s necessary to move a language from simply being
  an interesting case study to becoming adoptable in practice.

Let’s move from these statements of optimism to the most pessimistic
myth of all:


#### Myth #10: We'll never pull this off.


My reaction to this myth depends on the intended definitions of “we”
and “this.” If the statement is intended to mean, “The Chapel team
in its current configuration will never succeed in getting Chapel, as
it is currently defined, adopted,” then I would tend to agree, with
regret.  But if it’s meant in the more pessimistic sense of “the HPC
community will never succeed in creating a new, more productive
language that is adopted by users,” then I vehemently disagree.

{{<pullquote>}}

Designing a productive and adoptable parallel language seems far more
like a matter of will, cooperation, and resources than of technical
impossibilities.

{{</pullquote>}}

My opinions on this topic crystallized a few years ago while taking my
daughter to the Smithsonian's National Air and Space Museum for her
first time.  As kids, my brother and I used to insist on visiting the
museum on every family trip to DC, and this was my first time back in
decades.  Seeing the exhibits as an adult and a software engineer, I
found myself in renewed awe of the successes of the US space
program—particularly for the obvious amount of planning, technical
skills, coordination, and sheer force of will that were required.  We
habitually use the term “rocket scientist” to refer to smart people
without a second thought; yet standing amidst all that equipment with
video monitors displaying successful launches made me acutely aware of
what a significant and focused effort was required to achieve those
milestones.

By comparison, the achievements of the space program made designing a
productive and adoptable parallel language seem far more like a matter
of will, cooperation, and resources—{{<sidenote "right"
"social challenges, really" -7>}}When writing this in 2012, we still
had many significant technical challenges ahead of us, a large
fraction of which we've now addressed.  These days, it sometimes feels
like it's all social challenges remaining...  That's an overstatement
because technical challenges still exist, but the social ones are the
ones that keep me up at night now—in part because I find them far more
challenging to wrestle with.{{</sidenote>}}—than of technical
impossibilities.  So if, as a parallel computing community, we truly
believe that we would benefit from improved parallel programming
models, then we should get to work creating them rather than standing
around wringing our hands or prophesying their doom out of sheer force
of habit after years of disappointment.

Sometimes when looking back on a period, it can feel as though a goal
is unattainable.  But it doesn’t take many concrete steps toward a
goal to realize that it’s within reach after all.  Parallel
programming is hard.  Designing good parallel languages is hard.  But
neither is impossible given sufficient will, cooperation, and
community mindedness.

What would the emergence of a plausibly adoptable parallel language
look like?  In my opinion, it wouldn’t "spring from the forehead of
Zeus", fully formed on day one.  You’d see it approaching from a ways
off, be around during its awkward years, encounter its shortsighted
flaws before they were all ironed out, become impatient with the rate
at which its performance improved, and perhaps even {{<sidenote
"right" "fail to notice its advancement over time" -7>}}I remember
having the scene from _Monty Python and the Holy Grail_ where Lancelot
is endlessly running toward the guards in my head when writing
this.{{</sidenote>}} due to the amount of time required.  So, when you
come across a new language that’s on a path you generally like, try to
extrapolate forward, help keep it on a productive path, make your
feedback constructive, find ways to {{<sidenote "right"
"support it if you can">}}For Chapel, some ways to do this are listed
on our [Get Involved](https://chapel-lang.org/getinvolved/)
page.{{</sidenote>}}, suggest milestones that will demonstrate
capabilities and progress prior to completion, and exercise patience.
As a community, we have important problems to solve and smart people
to work on them; surely we can find the will and expertise to create a
plausibly adoptable parallel language.

Jumping back to the other interpretation of “we’ll never pull this
off,” regarding whether or not Chapel will succeed…  Change the
definition of “we” from “a modest-sized Cray-centric team” to “the
Chapel team as it could become—a broad community effort, leveraging
the best HPC has to offer;” and change “this” from “Chapel today” into
“Chapel as it could be, improved by the efforts of the broader
community;” and {{<sidenote "right" "in those terms">}}If, like me
today, you're having trouble untangling the interpretation proposed by
this sentence, I'm saying that if "We'll never pull this off" is
intended to mean "A broad community effort, leveraging HPC expertise,
will never be successful with a language like Chapel," then I strongly
disagree—I definitely believe we have a fighting chance.  I'll come
back to this in the [sections that follow]({{<relref
"#reflections-on-the-original-article">}}).{{</sidenote>}}, yes, I
believe we do have a fighting chance of making Chapel successful.  And
if, in the end, Chapel joins the legions of failed parallel languages,
hopefully it will have moved the ball forward in a way that aids
languages that follow, much as our team learned from HPF, ZPL, NESL,
and the like.

This brings us to the conclusions for this final article’s myths:

#### Counterpoint #10:  With appropriate force of will, cooperation, resources, and effort, the HPC community should be able to successfully create a viable and adoptable scalable parallel programming language.

#### Counterpoint #9: While Chapel almost certainly has flaws, its design also has a number of reasonably unique strengths that make it worth pursuing and striving to perfect.  To that end, we appreciate having users point out missteps in a constructive manner that helps lead us to a better design.

To summarize the series as a whole, the ten myths and counterpoints
have been as follows:

   {{< alttable >}}
   | **Article**    | **Myth** | **Counterpoint** |
   |:---------------|:---------|:-----------------|
   | [Part 1: Productivity and Performance]({{< relref 10myths-part1 >}}) | #1: Productivity is at odds with performance. | A smart selection of language features can improve programmer productivity while also having positive or neutral impacts on performance. |
   | [Part 2: Past Failures and Future Attempts]({{< relref 10myths-part2 >}}) | #2: Because HPF failed, your language will not succeed	| Past language failures do not dictate future ones; moreover, they give us a wealth of experience to learn from and improve upon. |
   | [Part 3: New Languages vs. Language Extensions]({{< relref 10myths-part3 >}}) | #3: Programmers won’t switch to new languages.  To be successful, a new language must be an extension of an existing language. | The surface benefits of extending an existing language are often not as deeply beneficial as we might intuitively believe.  Moreover, when well-designed languages offer clear benefits and a path forward for existing code, the programming community is often more willing to switch than they are given credit for.  Thus, we shouldn’t shy away from new languages and the benefits they bring without good reason. |
   | [Part 4: Syntax Matters]({{< relref 10myths-part4 >}}) | #4: Syntax doesn’t matter. | Syntax does matter and can greatly impact a programmer’s productivity and creativity in a language, as well as their ability to read, maintain, and modify code written in that language. |
   | [Part 5: Productivity and Magic Compilers]({{< relref 10myths-part5 >}}) | #5: Productive languages require magic compilers. | Well-designed languages should not require heroic compilation to be productive; rather, they should provide productivity through an appropriate layering of abstractions, while also providing opportunities for future compiler optimizations to make that which is merely elegant today efficient tomorrow. |
  | [Part 6: Performance of Higher-Level Languages]({{< relref 10myths-part6 >}}) | #6: High-Level languages can’t compete with MPI. | Well-designed high-level languages can outperform MPI while also supporting better performance, portability, programmability, and productivity. |
  | | #7: If a parallel language doesn’t have good performance today, it never will. | The performance potential of a novel language should be evaluated by studying ways in which the features enable and/or limit its ability to achieve good performance and projecting its implementation strategy forward in time; not by simply measuring the performance that it happens to produce at a given point in time. |
  | [Part 7: Minimalist Language Designs]({{< relref 10myths-part7 >}}) | #8: To be successful, scalable parallel programming languages should be small/minimal. | Many of the successful software systems we use are large in order to be general and productive.  More important than minimalism is the language’s approachability and documentation—i.e., can one make effective use of it without being familiar with all of its features? |
| [Part 8: Striving Toward Adoptability]({{< relref 10myths-part8 >}}) | #9: The Chapel team believes that Chapel is perfect. | While Chapel almost certainly has flaws, its design also has a number of reasonably unique strengths that make it worth pursuing and striving to perfect.  To that end, we appreciate having users point out missteps in a constructive manner that helps lead us to a better design. |
| | #10: We’ll never pull this off. | With appropriate force of will, cooperation, resources, and effort, the HPC community should be able to successfully create a viable and adoptable scalable parallel programming language. |

In concluding this series, I’d like to express my gratitude to the
IEEE TCSC blog editors and leadership—Yong Chen, Pavan Balaji, and
Xian-He Su—for giving me the opportunity to write and publish this
series.  And a special thanks to Dr. Chen’s student, Jialin Liu, for
publishing these articles to the web, typically under tight deadlines
due to my procrastination.  Upon receiving the original invitation to
submit a 500–1000 word article, I naïvely thought that I would address
most of these ten myths in a single article; but upon exceeding my
space budget on just the first myth, it quickly morphed into this
series.  Timed as they were with the final months of the DARPA
{{<sidenote "right" "HPCS">}}High Productivity Computing
Systems{{</sidenote>}} program that spawned Chapel, the articles
became a perfect opportunity to reflect on community skepticism about
scalable parallel languages and to collect in one place the thoughts
and rebuttals I’d assembled over the course of HPCS.  The blog format
was particularly appealing due to its casual/conversational format.
Whether the resulting manifesto is ultimately viewed as advocacy for a
better future or simply self-indulgent venting, I leave to you.
{{<sidenote "right"
"Meanwhile, I’ve got a scalable language to finish.">}}There's a lot I
didn't remember about this series until re-reading it, but I never
forgot this concluding sentence, which captured the resolve I felt at
the time, and my relief at having wrapped up the
series.{{</sidenote>}}

#### Bibliography

[1] B. Chamberlain, [Multiresolution Languages for Portable yet Efficient Parallel Programming](https://chapel-lang.org/papers/DARPA-RFI-Chapel-web.pdf), position paper, October 2007.
 
[2] B. L. Chamberlain, S.-E. Choi, S. J. Deitz, D. Iten, V. Litvinov, [Authoring User-Defined Domain Maps in Chapel](https://chapel-lang.org/publications/cug11-final.pdf), CUG 2011, May 2011.

[3] B. Chamberlain, S. Deitz, D. Iten, S.-E, Choi, [User-Defined Distributions and Layouts in Chapel: Philosophy and Framework](https://chapel-lang.org/publications/hotpar10-final.pdf), 2nd USENIX Workshop on Hot Topics in Parallelism (HotPar '10), June 2010.

[4] B. L. Chamberlain, S.-E. Choi, S. J. Deitz, A. Navarro, [User-Defined Parallel Zippered Iterators in Chapel](http://pgas11.rice.edu/papers/ChamberlainEtAl-Chapel-Iterators-PGAS11.pdf), PGAS 2011: Fifth Conference on Partitioned Global Address Space Programming Models, October 2011.


#### Acknowledgments

Thanks to my colleagues on the Chapel team and within the HPC
community for the many interesting discussions that have helped inform
the contents of this series.  This material is based upon work
supported by the Defense Advanced Research Projects Agency under its
Agreement No. HR0011-07-9-0001. Any opinions, findings and conclusions
or recommendations expressed in this material are those of the author
and do not necessarily reflect the views of the Defense Advanced
Research Projects Agency.



---

### Reflections on the Original Article

For most of these reprints, I've focused on whether I think the myths
or arguments in the series hold up.  For this one, I think they do.
However, a few phrases haunt me a bit today, most notably: "If one of
our goals as a community is to create better parallel programming
models over time..." and "If, as a parallel computing community, we
truly believe that we would benefit from improved parallel programming
models..."

Although the HPCS program was coming to an end when I wrote these
words, I had zero doubt that they were safe assumptions ("Of course
this is one of our goals!  Of course we believe we would!").  For my
career up through that point, it seemed self-evident that they were
commonly agreed upon—the design and implementation of parallel
languages had been a time-honored and common goal of the HPC community
for decades leading up to that point.  But I'm far less confident that
they represent typical HPC mindsets today.

{{<pullquote>}}

Community interest in, not to mention hope for, new scalable parallel
languages has become far more muted—and not because it’s a solved
problem.

{{</pullquote>}}

Despite the ongoing and arguably growing need for productive parallel
languages, the number of groups working on scalable parallel languages
has dwindled significantly.  How many current language projects can
you name that are playing in the space that HPF, ZPL, UPC, Titanium,
X10, Fortress, and others once did?  Community interest in, not to
mention hope for, new scalable parallel languages has become far more
muted.  And not because it's a solved problem—if anything, HPC systems
have only become more challenging to program over that time.

When we launched Chapel and I was put in charge of its implementation,
I often felt overwhelmed by what we were trying to achieve.  In
response, my manager at that time would tell me that my role was to be
the "young Turk" who would lead the charge and show people the way to
better parallel programming.  Now I feel increasingly like the much
older man who is easy to ignore because he seems to tell similar
stories over and over.  So how did we get here...?


#### Time flies

Revisiting this 2012-era series in 2025, one of the things that's been
most surprising to me is how immature Chapel still was when the series
was published—not to mention how far it's come in the intervening 13
years!  Like a lot of things in life, when you see something on a
daily basis, it's easy to lose track of the changes that gradually
take place over time, or even to remember just where things stood at a
given point.  Logically, it's not at all surprising that the daughter
I mention taking to the Smithsonian is now 13 years older than she was
then.  Yet it's simultaneously mind-blowing to think that she was just
six when I wrote about her then, and is now in college.  The math
makes sense, yet it still seems like a lot of change, mostly
imperceptible on a daily basis, and in what hasn't _felt like_ all that
much time.

Similarly, if you'd asked me what this series covered before I
revisited it this year, I probably would've described it as containing
Chapel results showing a good combination of code clarity and
performance, because it feels as though we've been sharing those kinds
of results forever.  So it was interesting to be reminded that 13
years ago, we didn't really have worthwhile performance results to
speak of, just the belief that we'd designed a language that would be
able to achieve them in time.  To that end, it's been gratifying to be
able to reprint the series and to share results where we've
successfully delivered on our aspirations.

In gathering those results for publication, it's also been surprising
to realize how many of them were still years away when the series was
originally published.  Our first competitive results for HPCC STREAM
Triad—arguably one of the simplest distributed benchmarks—weren't
achieved until 2015.  Our first optimizations enabling massively
scalable results for HPCC RA, Arkouda argsort, and Bale Indexgather
were all developed in 2019.  Our first run on thousands of compute
nodes "just" occurred in 2023.

Despite feeling surprised by being reminded of how primitive Chapel was
in 2012, I also want to acknowledge that 13 years isn't exactly the
blink of an eye.  And in that vein, many who are reading this may be
reacting with a sense of "Why has this taken so long?!?"  Well...


#### A Brief History of Chapel

Before answering that question, let me start with a very simplified
timeline of the Chapel project, at least as I think of it:


###### December 2002–July 2006: The blank slate years

Chapel's inception occurred at the very end of 2002 during phase I of
the DARPA HPCS program.  We then spent the next several years trying
to figure out exactly what the language would be.  These years focused
on taking first steps in the implementation along with lots of
discussions at whiteboards and in whitepapers, trying to figure out
what features Chapel would have, how they'd be expressed, and how we
could implement it in a way that would result in performance and
scalability.  By the summer of 2006, we started to have a pretty good
idea of what we were building and how.


###### August 2006–October 2012: The HPCS scramble

I think of these next years as the ones we spent scrambling to
implement Chapel's unique language features well enough to prove its
value and viability.  We were driven primarily by the goals and
expectations of the HPCS program to demonstrate Chapel's flexibility,
clarity, conciseness, stability, and scalability.  Though we achieved
these goals by the end of the program, as noted above, we were still a
ways off from having performance that could compete with standard
approaches.


###### November 2012–November 2018: Hardening the prototype

Emerging from HPCS, we were faced with a choice: Did we want to
continue as a research project, or did we want to focus on creating
something more product-like that real programmers could make use of?
Without hesitation, we knew that we wanted the second option, so spent
these next years hardening features, expanding the language's
capabilities, and beginning the process of reworking the base
language, including adding features to it, as motivated by user
feedback.  Notably, it was only toward the end of this period, around
the time of CUG 2018, that we began encouraging users to consider
writing applications in Chapel in earnest.  Up until that point, we'd
suggested they experiment with Chapel and give us feedback, but would
generally gently dissuade people from using it for mission-critical
applications.


###### December 2018–December 2019: First flagship apps

In the year or so that followed, users began to take us up on that
challenge.  Flagship Chapel applications such as [Arkouda]({{<relref
7qs-reus>}}), [CHAMPS]({{<relref 7qs-laurendeau>}}), and
[ChOp]({{<relref 7qs-chop>}}) were all initiated during this time
period.  Their authors began doing initial presentations and
publications of their work by mid-to-late 2019.


###### January 2020–March 2024: The march to 2.0

These next several years were dominated by our push to release [Chapel
2.0]({{<relref announcing-chapel-2.0>}}), which stabilized the core
language and library features.  During this period, we also began
successfully targeting GPUs and the Cray Slingshot network for the
first time.


###### April 2024–today: Focus on the community

Since Chapel 2.0, our primary focus has been on nurturing and growing
the Chapel community.  On the technical side, we've been working on
the [Dyno]({{<relref dyno>}}) compiler rework, addressing technical
debt that dates back to Chapel's research origins.  We also began
investing time in developing [productivity tools]({{<relref tools>}})
for Chapel and amping up our focus on resolving user issues.  On the
less-technical side, we focused on broadening our communications
through [talks](https://chapel-lang.org/presentations/),
[tutorials](https://www.youtube.com/playlist?list=PLuqM5RJ2KYFgllPMfP5OiRKsVRPf1UEDs),
[demos](https://www.youtube.com/playlist?list=PLuqM5RJ2KYFjYgOStSfrNshIQ0I-AibHY),
[ChapelCon]({{<relref chapelcon>}}), [social
media](https://chapel-lang.org/socials/), and this blog.  And that
brings us to today.


#### What's taken so long?

Summarizing the timeline above, the Chapel project could be
characterized as 10 years of research prototyping followed by 7 years
of development to prepare for initial users, followed by 5 years of
supporting those users and setting the stage to support more.

So, back to the question of "Why has this taken so long?", part of my
answer is to note the large number of novel research and development
problems we tackled and solved during Chapel's early years, [as
characterized
above](#myth-9-the-chapel-team-believes-that-chapel-is-perfect).
Another part of my answer relates back to [last month's
article]({{<relref 10myths-part7>}}) and its argument that when
implementing a scalable parallel programming language, you need all of
the modern productivity features that you'd want in a desktop language
combined with all of the features that are uniquely designed to
support parallel computing at scale—e.g., lightweight multithreading,
a global namespace, and the ability to efficiently target the node and
network architectures of the time.

"Of the time" is a key qualifier since another challenge has been the
constant changes in HPC architectures.  Chapel was kicked off at a
time when the Cray XMT and Cray X1 were the flagship HPC architectures
at Cray Inc.  Notably, Chapel's design predated the widespread use of
multicore processors, high-radix/low-diameter networks, multi-socket
compute nodes, NUMA memory architectures, and GPU computing.  Yet it
has adapted to those (significant!) changes relatively seamlessly due
to its distinct (and composable) concepts for describing parallelism
and locality.  How many other programming models can claim to have
been general enough to run on the Cray XMT, over a million cores of
HPE Cray EX, NVIDIA and AMD GPUs, and most other HPC architectures and
vendors in-between?  Moreover, Chapel has done this with a team of
fairly modest size, as is often the case for HPC software projects.

In short, the reason Chapel took so long to demonstrate its promise is
that there was a lot of work required to get here.  We appreciate your
patience.


#### Bonus Myth #1: Longevity and Adoption

If I were asked to add new myths to this series today, the first one
that comes to mind is "Since Chapel hasn't been broadly adopted by
this point, it never will be."  I think this is probably the most
frequent and pessimistic reaction we've heard from the community in
recent years.  And, as with many of the myths in this series, I find
it frustrating since it has less to do with evaluating Chapel's design
and capabilities as it does with the social challenges of launching
new languages.

Users understandably want guarantees that languages they invest in
will stick around; and the larger a language's community is, the
easier it is to feel confident that it will.  Yet, all new languages
have to start somewhere, and it is easy to interpret the combination
of Chapel's longevity and its modest-sized user base as a sign that it
isn't up to the task.  Maybe the thing most frustrating about this
myth is the number of times I feel like I hear it from people who
don't have direct (or recent) experience with Chapel.

I've long said that I hope I would have the grace to pull the plug on
Chapel if something better were to come along; yet as HPC
architectures have become more complex over time, it seems as though
programming them has only gotten harder.  The SPMD-based MPI+X (+Y
(+Z)) approaches being used in practice by the HPC community are
clearly _sufficient_ for programming supercomputers, but are they
helping the community thrive, grow, and be more productive?  It
doesn't seem that way to me.

So my counterpoint to this myth is that while Chapel has not yet been
broadly adopted, it still uniquely fulfills a crucial role and need in
the parallel programming landscape, with relatively few competing
approaches still standing.


#### Bonus Myth #2: HPC Community and Languages

The other myth that comes to mind is "The HPC community simply isn't
large enough to support the development of its own language."  It's
arguably this attitude that has led to HPC programming models being
developed as libraries, pragmas, and modest language extensions (which
often seem to become less modest as architectural complexity grows).
Again, such approaches are clearly sufficient; yet, they leave a lot
to be desired as compared to programming languages which, by nature,
can support better syntax, semantic checks, and compiler-based
optimizations.  Again, the analogy to assembly programming vs. Fortran
from [part 3]({{<relref 10myths-part3>}}) comes to mind.

{{<pullquote>}}

Parallel computing and scalability are no longer HPC-specific
concerns. Every programmer can now be a parallel programmer, and
performance-focused programmers increasingly must be.

{{</pullquote>}}

My counterpoint to this myth is that parallel computing and
scalability are no longer HPC-specific concerns.  Every computer is
now a parallel computer by virtue of its multicore processors and
GPU(s).  Every programmer can now purchase time on the cloud, making
supercomputer-like scales available to the general public.  AI has
demonstrated the benefits of scalability, resulting in data centers
that dwarf traditional HPC centers.  So to consider the target
community for a language like Chapel to be small or niche seems to
ignore the fact that most performance-focused programmers must now be
parallel programmers, and increasingly ones for whom scalability might
matter.

Summarizing, here's a table with the two bonus myths added in
this article's commentary:

   {{< alttable >}}
   | **Myth** | **Counterpoint** |
   |:---------|:-----------------|
   | Bonus Myth #1: Since Chapel hasn't been broadly adopted by this point, it never will be. | Though Chapel has not yet been broadly adopted, it still fulfills a crucial role and need in the parallel programming landscape, with relatively few competing approaches still standing. |
   | Bonus Myth #2: The HPC community simply isn't large enough to support the development of its own language. | Parallel computing and scalability are no longer HPC-specific concerns.  Every programmer can now be a parallel programmer, and performance-focused programmers increasingly must be. |
   

### Wrapping Up

Returning to Myth #9: Is Chapel perfect?  Definitely not, and I'm
painfully aware of this every time a user or developer opens a new
GitHub issue.  However, it is far better than it has ever been, and
our team continues to improve it day by day.  Most impressively, its
imperfections haven't stopped early adopters from writing critical
applications in it, whether in [~300 lines]({{<relref 7qs-bachman>}})
or [~100,000]({{<relref 7qs-laurendeau>}}).  But it definitely needs
more work to be truly broadly adopted or mainstream.

{{<pullquote>}}

With the recent formation of HPSF, the HPC community now has what I
consider to be the largest and healthiest forum for developing and
nurturing open-source software that it ever has.

{{</pullquote>}}

I started this commentary section by lamenting the seemingly reduced
interest in developing and studying scalable parallel languages.  Let
me now offset that by ending on a note that I feel far more optimistic
about.  With the recent formation of the [High Performance Software
Foundation (HPSF)](https://hpsf.io), the HPC community now has what I
consider to be the largest and healthiest forum for developing and
nurturing open-source software that it ever has.  And I'm proud to say
that the Chapel project is in the final stages of becoming an HPSF
project as I write this.  Only time will tell how big HPSF's impact
will be, but I am optimistic that it is indicative of a growing sense
that HPC software has been malnourished and overshadowed by the
community's overwhelming focus on hardware, and that it's overdue for
a space of its own.

In any case, as part of Chapel's transition to HPSF, we have been
working on opening up our project's weekly meetings, processes, and
governance.  So where I ended the original series with the arguably
snotty mic-drop "I've got a scalable language to finish," this time I
can end with something a bit more community-minded.  So, turning the
question to you: Do you want to be part of a community that continues
to strive toward perfecting and increasing the adoption of scalable
parallel languages?  If so, we're always looking for new users,
partners, community members, and funding sources, so come join us and
[get involved](https://chapel-lang.org/getinvolved/)—_We've_ got a
scalable language to finish!

---

### Acknowledgments (Redux)

The [acknowledgments section above](#acknowledgments) is from the
original article, and it appeared at the end of each post in the 2012
series.  In these reprints, I only bothered reproducing it on the
first post and this one to avoid needless repetition, hoping DARPA
won't mind.

For this reprint series, I'd like to add my thanks to my current
colleagues and teammates who helped significantly improve my drafts
through feedback and conversation–often with a quick turnaround since,
as with the original series, I'd typically complete my drafts at the
last minute, just before our self-imposed "13 years to the day"
deadlines.  I'd particularly like to thank [Daniel Fedorin]({{<relref
daniel-fedorin>}}), [Michael Ferguson]({{<relref michael-ferguson>}}),
and especially [Engin Kayraklioglu]({{<relref engin-kayraklioglu>}}),
who served as my principal readers and editors.

I'd also like to thank my family for their patience, as both the
original articles and these reconsiderations of them were typically
written during weekends and evenings, never quite seeming to fit into
the traditional workday.

And finally, I'd like to thank you—any reader (or AI assistant) who
made it to this point.  I realize that I had a lot more to say than
many modern attention spans may be interested in and appreciate those
of you who stuck through it.  As with all of our Chapel blog posts,
I'd be interested in hearing your thoughts.
