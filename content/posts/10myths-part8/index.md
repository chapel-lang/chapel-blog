---
title: "10 Myths About Scalable Parallel Programming Languages (Redux),  Part 8: Striving Toward Adoptability"
date: 2025-11-12
tags: ["Editorial", "Archival Posts / Reprints"]
series: ["10 Myths About Scalable Parallel Programming Languages Redux"]
summary: "The eighth and final archival post from the 2012 IEEE TCSC blog series with a current reflection on it"
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
originally published on October 15, 2012.  Comments in the sidebar and
[the sections that follow the reprint]({{<relref
"#reflections-on-the-original-article">}}) give a few of my current
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
language (http://chapel-lang.org).

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
outreach—making the rounds to let people to know what you’re doing and
why; and, in doing so, trying to get feedback from potential users.
When you’re out proselytizing for your language over a period of time
like this, it can often give the unfortunate impression that you
believe your design to be flawless.  And this, in turn, can have the
effect of becoming a barrier that prevents audience members from
keeping an open mind about your language if they find something flawed
or less-than-perfect about its design.

In my opinion, all emerging languages of a certain size and
practicality are likely to have flaws, some due to a compromise that
was made in favor of another capability, others due to lack of
sufficient time or expertise within the design team to flesh out
certain feature areas, still others due to myopia caused by working
too close to the language.  In Chapel’s case, we’ve certainly had
missteps that fall into each of these categories.  Early users have
pointed out seemingly obvious improvements to which we’d become blind
due to prolonged exposure to the language; other features—exceptions
and hierarchical representations of locality, for example—were
intentionally omitted from the original design simply due to the fact
that we knew our plate was already quite full.  As we moved them to
the back burner, we would refer to these as “excellent features for
version 2.0.”

Having occasionally encountered this attitude of “it’s not perfect, so
it’s not worth my time,” my suggestion to those who dismiss emerging
languages on such a basis would be to avoid considering any perceived
flaws in the language as a personal affront to your intelligence, or a
failed test that necessitates the language’s dismissal.  If one of our
goals as a community is to create better parallel programming models
over time, then the limited time that any of us has would be better
spent discussing such flaws to help the language team improve upon
them rather than writing off the language simply due to the fact that
it is imperfect.  Who among us has ever done flawless work?

As described in [last month’s article]({{< relref 10myths-part7
>}}#the-original-article-reprinted), my personal belief is that any
plausibly adoptable scalable language is necessarily going to be quite
large; and for this reason, it’s not at all difficult for me to
believe that our modest-sized Chapel team has made mistakes and
oversights along the way.  For this reason, it is always my intention
to be grateful when users point out perceived flaws constructively,
particularly when they already have a proposed solution in hand.

While I don’t think of Chapel as being perfect, and fully expect more
flaws to be identified over time, I believe that most of these can be
addressed as we go.  I also believe that we have made a number of
design decisions with Chapel that have improved its chances of
adoption and forward portability compared to other parallel
programming models; and this is why I’m personally interested in
persevering and striving to address Chapel’s flaws rather than
throwing in the towel and moving on.  Here are some of the design
choices that, in combination, I believe make Chapel notable:

* A multithreaded execution model: The continuing dominance of static
  Single-Program, Multiple-Data (SPMD) execution models in a world
  that is increasingly dynamic and hierarchical seems like a
  significant problem to me, and a symptom of developing programming
  models that only support a common case rather than supporting the
  general case and optimizing for the common one.  In contrast, I
  think programming models like Chapel’s that support a fully dynamic
  execution model through multithreading, while still supporting SPMD
  as an important common case, are far better prepared to handle
  future architectures and algorithms.

* Distinct concepts for parallelism and locality: A related flaw that
  I think conventional parallel programming models share is that most
  have no way to talk about locality distinctly from parallelism
  (assuming locality is represented at all).  In MPI and UPC, for
  example, there is no way to create a parallel activity within the
  model without also creating a new process/thread, which also serves
  as the unit of locality within these models.  To the Chapel team’s
  thinking, parallelism and locality are distinct properties, and
  therefore should be treated as such within scalable parallel
  languages.

* Support for a multiresolution design: In our work, supporting a
  multiresolution language design means providing both higher- and
  lower-level features within a single language, permitting users to
  move between layers as necessary, or to provide their own
  implementations of higher-level features [[1]({{< relref 10myths-part7
>}}#the-original-article-reprinted)].  This seems essential
  in any parallel language where productivity, performance, and
  forward portability are desired since it provides a means of trading
  off abstraction for control, and for creating new abstractions that
  a compiler can reason about and optimize.

* User-defined layouts, distributions, and parallel iterators: In
  Chapel, I think the specific choice of permitting users to provide
  their own local and distributed array implementations [[2, 3]({{<
  relref 10myths-part7 >}}#the-original-article-reprinted)], as well
  as the ability to control the implementation of data parallel loops
  [[4]({{< relref 10myths-part7 >}}#the-original-article-reprinted)]
  is incredibly important in terms of making the language
  forward-portable and adaptable to emerging parallel architectures
  and algorithms.

* Unification of Data- and Task-Parallelism: While most previous
  languages have restricted themselves to support either data- or
  task-parallelism, others have strived to support both, often
  resulting in a somewhat haphazard mash-up between the two feature
  sets.  Chapel’s approach of specifying data parallelism using task
  parallel features via its multiresolution design permit the two
  modes of parallelism to coexist quite well compared to previous
  efforts.

* Productive base language features: While Chapel’s base language
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
and “this.” If the statement were intended to mean, “The Chapel team
in its current configuration will never succeed in getting Chapel as
it is currently defined adopted,” then I would tend to agree, with
regret.  But if it’s meant in the more pessimistic sense of “the HPC
community will never succeed in creating a new, more productive
language that is adopted by users,” then I vehemently disagree.

My opinions on this topic crystalized a few years ago while taking my
daughter to the Smithsonian National Air and Space Museum for her
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
of will, cooperation, and resources—social challenges, really—than of
technical impossibilities.  So if, as a parallel computing community,
we truly believe that we would benefit from improved parallel
programming models, then we should get to work creating them rather
than standing around wringing our hands or prophesying their doom out
of sheer force of habit after years of disappointment.

Sometimes when looking back on a period with little discernable
progress, it can feel as though a goal is unattainable.  But it
doesn’t take many concrete steps toward a goal to realize that it’s
within reach after all.  Parallel programming is hard.  Designing good
parallel languages is hard.  But neither is impossible given
sufficient will, cooperation, and community mindedness.

What would the emergence of a plausibly adoptable parallel language
look like?  In my opinion, it wouldn’t spring from the forehead of
Zeus, fully formed on day one.  You’d see it approaching from a ways
off, be around during its awkward years, encounter its shortsighted
flaws before they were all ironed out, become impatient with the rate
at which its performance improved, and perhaps even fail to notice its
advancement over time due to the amount of time required.  So, when
you come across a new language that’s on a path you generally like,
try to extrapolate forward, help keep it on a productive path, make
your feedback constructive, find ways to support it if you can,
suggest milestones that will demonstrate capabilities and progress
prior to completion, and exercise patience.  As a community, we have
important problems to solve and smart people to work on them; surely
we can find the will and expertise to create a plausibly adoptable
parallel language.

Jumping back to the other interpretation of “we’ll never pull this
off,” regarding whether or not Chapel will succeed…  Change the
definition of “we” from “a modest-sized Cray-centric team” to “the
Chapel team as it could become—a broad community effort, leveraging
the best HPC has to offer;” and change “this” from “Chapel today” into
“Chapel as it could be, improved by the efforts of the broader
community;” and in those terms, yes, I believe we do have a fighting
chance of making Chapel successful.  And if, in the end, Chapel joins
the legions of failed parallel languages, hopefully it will have moved
the ball forward in a way that aids the languages that follow, much as
we’ve learned from HPF, ZPL, NESL, and the like.

This brings us to the conclusions for this final article’s myths:

#### Counterpoint #10:  With appropriate force of will, cooperation, resources, and effort, the HPC community should be able to successfully create a viable and adoptable scalable parallel programming language.

#### Counterpoint #9: While Chapel almost certainly has flaws, its design also has a number of reasonably unique strengths that make it worth pursuing and striving to perfect.  To that end, we appreciate having users point out missteps in a constructive manner that helps lead us to a better design.

To summarize the series as a whole, the ten myths and counterpoints have been as follows:

   {{< alttable >}}
   | **Article**    | **Myth** | **Counterpoint** |
   |:---------------|:---------|:-----------------|
   | [Part 1: Productivity and Performance]({{< relref 10myths-part1 >}}) | #1: Productivity is at odds with performance. | A smart selection of language features can improve programmer productivity while also having positive or neutral impacts on performance. |
   | [Part 2: Past Failures and Future Attempts]({{< relref 10myths-part2 >}}) | #2: Because HPF failed, your language will not succeed	| Past language failures do not dictate future ones; moreover, they give us a wealth of experience to learn from and improve upon. |
   | [Part 3: New Languages vs. Language Extensions]({{< relref 10myths-part3 >}}) | #3: Programmers won’t switch to new languages.  To be successful, a new language must be an extension of an existing language. | The surface benefits of extending an existing language are often not as deeply beneficial as we might intuitively believe.  Moreover, when well-designed languages offer clear benefits and a path forward for existing code, the programming community is often more willing to switch than they are given credit for.  Thus, we shouldn’t shy away from new languages and the benefits they bring without good reason. |
   | [Part 4: Syntax Matters]({{< relref 10myths-part4 >}}) | #4: Syntax doesn’t matter. | Syntax does matter and can greatly impact a programmer’s productivity and creativity in a language as well as their ability to read, maintain, and modify code written in that language. |
   | [Part 5: Productivity and Magic Compilers]({{< relref 10myths-part5 >}}) | #5: Productive languages require magic compilers. | Well-designed languages should not require heroic compilation to be productive; rather, they should provide productivity through an appropriate layering of abstractions, while also providing opportunities for future compiler optimizations to make that which is merely elegant today efficient tomorrow. |
  | [Part 6: Performance of Higher-Level Languages]({{< relref 10myths-part6 >}}) | #6: High-Level languages can’t compete with MPI. | Well-designed high-level languages can outperform MPI while also supporting better performance, portability, programmability, and productivity. |
  | | #7: If a parallel language doesn’t have good performance today, it never will. | The performance potential of a novel language should be evaluated by studying ways in which the features enable and/or limit its ability to achieve good performance and projecting its implementation strategy forward in time; not by simply measuring the performance that it happens to produce at a given point in time. |
  | [Part 7: Minimalist Language Designs]({{< relref 10myths-part7 >}}) | #8: To be successful, scalable parallel programming languages should be small/minimal. | Many of the successful software systems we use are large in order to be general and productive.  More important than minimalism is the language’s approachability and documentation—i.e., can one make effective use of it without being familiar with all of its features? |
| [Part 8: Striving Toward Adoptability]({{< relref 10myths-part8 >}}) | #9: The Chapel team believes that Chapel is perfect. | While Chapel almost certainly has flaws, its design also has a number of reasonably unique strengths that make it worth pursuing and striving to perfect.  To that end, we appreciate having users point out missteps in a constructive manner that helps lead us to a better design. |
| | #10: We’ll never pull this off. | With appropriate force of will, cooperation, resources, and effort, the HPC community should be able to successfully create a viable and adoptable scalable parallel programming language. |

In concluding this series, I’d like to express my gratitude to the IEEE TCSC blog editors and leadership—Yong Chen, Pavan Balaji, and Xian-He Su—for giving me the opportunity to write and publish this series.  And a special thanks to Dr. Chen’s student, Jialin Liu, for publishing these articles to the web, typically under tight deadlines due to my procrastination.  Upon receiving the original invitation to submit a 500-1000 word article, I naïvely thought that I would address most of these ten myths in a single article; but upon exceeding my space budget on just the first myth, it quickly morphed into this series.  Timed as they were with the final months of the DARPA HPCS program that spawned Chapel, the articles became a perfect opportunity to reflect on community skepticism about scalable parallel languages and to collect in one place the thoughts and rebuttals I’d assembled over the course of HPCS.  The blog format was particularly appealing due to its casual/conversational format.  Whether the resulting manifesto is ultimately viewed as advocacy for a better future or simply self-indulgent venting, I leave to you.  Meanwhile, I’ve got a scalable language to finish.

#### Bibliography

[1] B. Chamberlain, [Multiresolution Languages for Portable yet Efficient Parallel Programming](https://chapel-lang.org/papers/DARPA-RFI-Chapel-web.pdf), position paper, October 2007.
 
[2] B. L. Chamberlain, S.-E. Choi, S. J. Deitz, D. Iten, V. Litvinov, [Authoring User-Defined Domain Maps in Chapel](https://chapel-lang.org/publications/cug11-final.pdf), CUG 2011, May 2011.

[3] B. Chamberlain, S. Deitz, D. Iten, S.-E, Choi, [User-Defined Distributions and Layouts in Chapel: Philosophy and Framework](https://chapel-lang.org/publications/hotpar10-final.pdf), 2nd USENIX Workshop on Hot Topics in Parallelism (HotPar '10), June 2010.

[4] B. L. Chamberlain, S.-E. Choi, S. J. Deitz, A. Navarro, [User-Defined Parallel Zippered Iterators in Chapel](http://pgas11.rice.edu/papers/ChamberlainEtAl-Chapel-Iterators-PGAS11.pdf), PGAS 2011: Fifth Conference on Partitioned Global Address Space Programming Models, October 2011.


#### Acknowledgements:

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


#### Wrapping Up

