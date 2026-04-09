---
title: "Reflections on 30 Years of HPC Programming: So many hardware advances, so little adoption of new languages"
richtitle: "Reflections on 30 Years of HPC Programming:<br>So many hardware advances, so little adoption of new languages"
date: 2026-04-09
tags: ["Editorial", "History", "Hardware", "GPUs", "Portability", "Performance", "Safety", "HPSF"]
summary: "A written version of Brad's HIPS 2025 keynote talk"
authors: ["Brad Chamberlain"]
---

Last summer, I had the opportunity to give the keynote at [HIPS
2025](https://hips2025.github.io/)---the 30th International Workshop
on High-Level Parallel Programming Models and Supportive Environments.
This was quite an honor since, over its history, HIPS has been a key
workshop for projects like Chapel that strive to create {{<sidenote
"right" "productive approaches to scalable parallel programming"
-10>}}For readers unfamiliar with HIPS, its publications focus on
high-level programming of multiprocessors, compute clusters, and
massively parallel machines via language design, compilers, runtime
systems, and programming tools.  A long-term refrain from its call for
papers has been "We especially invite papers demonstrating innovative
approaches in the area of emerging programming models for large-scale
parallel systems and many-core architectures."{{</sidenote>}}.

To commemorate the 30th instance of HIPS, I took the approach of using
my talk to reflect on the past 30 years of programming within the
field of HPC, or High-Performance Computing.  This was a sobering
exercise, but one that was well-received.  In November, I reprised the
talk in a condensed lightning talk format for [CLSAC
2025](https://www.clsac.org/clsac25.html).  In this blog article, I'll
attempt to capture some of the main elements of those talks for a
wider audience.


### 30 Years of Top HPC Systems

Like so many "_n_ years of HPC" retrospectives, let's start by looking
to the {{<sidenote "right" "TOP500 list">}}The TOP500 is a ranking of
HPC systems, as measured by their performance on the Linpack
benchmark.  All TOP500 results and images in this article originate
from [top500.org](https://top500.org) and are used with permission.
Note that I've updated the original talk contents to reflect the
latest results from November 2025.{{</sidenote>}} to see how HPC
systems themselves have changed over the past three decades.  For
simplicity, I'll just focus on the top five systems from each list.

#### Top HPC Systems in 1995

Browsing the results from 30 years ago—November 1995—we see that
systems from Fujitsu, Intel, and Cray make up the top five, where
their network interconnects used crossbar, 2D mesh, and 3D torus
topologies, respectively.  Core counts ranged from 80 to 3,680, and
performance as measured by _Rmax_ values ranged from 98.9 to 170
GFlop/s.  The following screenshot from the TOP500 website summarizes
these systems and results:

{{<figure class="fullwide" src="Top500-Nov1995.png">}}

 

#### Top HPC Systems Today

Jumping forward to the latest TOP500 list, published in November 2025,
we see systems from HPE Cray, Eviden/Bull, and Microsoft.  These are
running using Slingshot-11 and InfiniBand NDR interconnects that
utilize topologies based on dragonfly[+] and/or fat-trees.  Core counts
have jumped to the millions (2,073,600–11,340,000 cores), and _Rmax_
values range from 561 to 1809 PFlop/s:

{{<figure class="fullwide" src="Top500-Nov2025.png">}}

 

#### HPC Systems: Then vs. Now

Summarizing the changes over these 30 years, core counts have
increased by a factor of 100s to 100s of thousands, while performance
has improved by factors of millions to 10s of millions—a massive
improvement!


{{< alttable >}}
|          | 1995 top 5            | 2025 top 5                       | Delta |
|:-------------|:---------------------:|:--------------------------------:|:-----:|
| **Cores**    | 80–3680              | 2,073,600–11,340,000             | ~563–141,750<small>$\times$</small> |
| **Rmax**     | 98.9–170 GFlop/s      | 561.2–1809 PFlop/s              | ~3,300,000–18,300,000<small>$\times$</small> |
| **Vendors**  | Fujitsu, Intel, Cray  | HPE, Eviden, Microsoft | ---</small> |
| **Networks** | crossbar, mesh, torus | dragonfly[+], fat-trees     | higher-radix, lower-diameter |       

 

Million-fold improvements like these don't happen without significant
effort, even with the passage of decades of time; so it's worth
reflecting on what changes in hardware and HPC system architecture
took place over this period to generate the massive gains seen here.
Though I'm not a hardware architect, from my perspective, I tend to
think of the main factors as having been:

* the commodification of processors with **vector instructions**
* the commodification of **multicore/manycore CPUs** and **chiplet**-based designs
* the advent of **multi-socket compute node** architectures
* the ability to create **high-radix, low-diameter networks** due to hardware trends
* the commodification of **GPUs** and successful applications of GPU computing in HPC

Beyond the performance improvements that can be attributed to these
changes, it's interesting to consider their impacts on programmers.
Specifically, which changes have made HPC programming easier, and
which have made it harder?  Think about your answers, and I'll return
to this question in a bit.


### 30 Years of HPC Programming

Next, let's consider the dominant HPC programming notations over this
same time period.  Unfortunately, there isn't an obvious analogue to
the TOP500 for HPC programming, so for this article, I'll give you my
take on things based on my experiences, research, and memory.

#### HPC Programming circa 1995

From my perspective in November 1995, the dominant and most broadly
adopted HPC programming languages were Fortran, C, and C++.  For
scripting, the dominant technologies seemed to be Perl, sh/csh/tcsh,
or Tcl/TK.

MPI, PVM, and SHMEM were the {{<sidenote "right" "dominant">}} It's
fair to wonder to what degree hindsight affects my characterizations
here.  Were MPI or SHMEM truly "dominant" in 1995?  Or is it only
because we can validate their longevity today that I consider them to
be?{{</sidenote>}} ways of programming distributed-memory systems at
the time.  High Performance Fortran (HPF) was getting a lot of
attention and funding, but my perception is that it was not really
getting a lot of use in practical applications developed outside of
the teams who were researching and developing it.

For shared-memory parallelism, I was surprised to be reminded that
OpenMP was still a few years in the future at this time, forming its
Architecture Review Board and publishing its 1.0 specification in
1997.  In 1995, you likely would have turned to POSIX threads or
vendor-specific compiler pragmas and markups (such as Cray
Microtasking) if you wanted loop- or thread-level parallelism.  Then
again, since processors were typically single-core at that time, you
also might not bother unless they supported vector instructions.


#### HPC Programming Today

If we think about what is broadly adopted in HPC today, the list is
disappointingly similar to 1995.  As far as programming languages go,
Fortran, C, and C++ still dominate the landscape in HPC.  Though PVM
has fallen off and HPF failed to catch on, MPI and SHMEM are still
alive and well, dominating distributed-memory HPC programming.  After
its 1997 launch, OpenMP quickly became dominant for shared-memory
programming and remains so today, making it a mainstay for most of the
past 30 years.  Kokkos, a C++ library-based notation is one of the
few programming models to make significant inroads towards HPC
adoption over the past decade or so, serving as an alternative to
OpenMP for shared-memory parallelism.

The biggest change in HPC programming notations since 1995 has been
caused by the advent of GPUs on HPC systems, and the resulting need to
program them.  Unfortunately, none of the 1995-era technologies were
sufficient to target GPUs, leading to a plethora of new technologies
being created to fill the gap.  These arrived in the form of language
extensions and libraries, such as CUDA, HIP, SYCL, OpenACC, OpenCL,
and Kokkos.  Other technologies like OpenMP evolved significantly in
order to support GPUs, becoming a bit more imperative by nature in the
process.

In the realm of scripting, Python largely displaced Perl and Tcl/TK,
while bash has generally replaced sh, csh, and tcsh as the dominant
shell scripting language.


{{<pullquote>}}

While HPC hardware has become far more capable over the past 30 years,
the HPC notations used in practice have largely stayed the same.
Notably, we have failed to broadly adopt any new compiled programming
languages.

{{</pullquote>}}


#### HPC Programming: Then vs. Now

Summarizing, I'd consider the broadly adopted HPC programming
notations of 30 years ago vs. today to be as follows:

{{< alttable >}}
| Category       | 1995 Notations                         | 2025 Notations    |
|:---------------|:---------------------------------------|:------------------|
| **Languages**  | Fortran, C, C++                        | Fortran, C, C++   |
| **Inter-node** | MPI, PVM, SHMEM                        | MPI, SHMEM        |
| **Intra-node** | Pthreads, vendor extensions<br>(with OpenMP on the horizon) | Pthreads, OpenMP, Kokkos |
| **GPUs**       | N/A                                    | CUDA, HIP, SYCL, OpenMP,<br>OpenACC, OpenCL, Kokkos |
| **Scripting**  | Perl, sh/csh/tcsh, Tcl/TK              | Python, bash      |

 


So, while HPC hardware has become far more capable over the past 30
years, resulting in amazing strides in terms of system performance,
efficiency, and scalability, the HPC notations used in practice have
largely {{<sidenote "right" "stayed the same">}}Champions of Fortran,
C++, MPI, or other entries on this list could argue that while the
names may be the same, the technologies themselves have evolved and
improved significantly over the past 30 years.  For example, Fortran
2008 evolved to support distributed programming, and C++ added
features for shared-memory parallelism.  While such advances are
important and notable, I'd say that the overall paradigm presented to
users by these models remains very similar, relying on SPMD
programming models, explicit communication, and relatively low-level
base languages compared to more modern alternatives.{{</sidenote>}},
modulo the introduction of GPU computing.  Perhaps most notably, as a
community, we have failed to broadly adopt any new compiled
programming languages for HPC.


### Standing Still?  Or Losing Ground?

In addition to not taking a great leap forward in the past 30 years,
HPC programming has arguably lost ground due to the increased
complexity of the hardware.  Of the hardware changes [listed
above](#hpc-systems-then-vs-now), most of them have made programming
more difficult.  Vector instructions, multicore processors, and GPUs
have introduced new styles of parallelism for programmers to express
in order to use their processors effectively.  Meanwhile, the growth
in cores per CPU, chiplet-based designs, and GPUs have introduced
Non-Uniform Memory Access (NUMA) characteristics, which require
greater sensitivity to data placement and affinity on the programmer's
part.

{{<pullquote>}}

The fact that most of our hardware advances have required us to
supplement programming notations of the past with new approaches
suggests that our programming models haven’t been sufficiently
abstracted from the hardware they target.

{{</pullquote>}}

In fact, of the hardware advances on my list, I'd say that only the
high-radix, low-diameter networks have been a boon to programmability,
in the sense that they have made sensitivity to network topology much
less of an issue than it was in the 1990's.  Back then, HPC
programmers would often spend effort optimizing for a particular
network topology—e.g., mesh, hypercube, or ring-of-rings.  Such
concerns are much rarer today, thankfully, where "local vs. remote"
tends to be the dominant issue rather than the specifics of which
nodes are communicating.

The fact that most of our hardware advances have required us to
supplement programming notations of the past with new features or
approaches suggests that our programming models haven't been
sufficiently abstracted from the hardware they target.  Arguably, if
they were able to express parallelism and locality in ways that were
more general-purpose and hardware-neutral, we wouldn't need to be
writing programs using a mix of programming notations, such as C++,
MPI, OpenMP and/or CUDA.


### Why the Stasis in HPC Languages?

Focusing on the 'Languages' row of the [summary table above]({{<relref
"#hpc-programming-then-vs-now">}}), it's interesting to speculate
about why no new programming languages have been broadly adopted in
HPC over the past 30 years.  Here are some possible explanations, as
well as why I don't think they necessarily hold up:


#### Is Language Design Dead?

Could the reason be that language design is dead, as was asserted by
an anonymous reviewer on one of our team's papers ~30 years ago?

{{<quote person="Anonymous reviewer, circa 1995 (paraphrased, from memory)">}}

"Programming language design ceased to be relevant in the 1980's."

{{</quote>}}

If we look to programming outside of HPC, the answer seems to be an
obvious "no."  Specifically, a plethora of new languages have emerged
or risen to prominence in the mainstream during the past 30 years,
including:

* Java (~1995)
* Javascript (~1995)
* Python (~1991 with v2.0 significantly increasing its prominence in ~2000)
* C# (~2000)
* Go (~2009)
* Rust (~2012)
* Julia (~2012),
* Swift (~2014)

Such languages have become favorite day-to-day languages of many users
across multiple disciplines, suggesting that language design is
far from dead.

Moreover, if we look at what motivated these language designs and why
they took hold, recurring themes include productivity, safety,
portability, and performance—things that are also very important and
desirable to HPC programmers:

{{< alttable >}}
| Language       | Productivity | Safety | Portability | Performance |
|:---------------|:------------:|:------:|:-----------:|:-----------:|
| **Java**       |              |  ✔     | ✔           |             |
| **Javascript** |  ✔           |        | ✔           |             |
| **Python**     |  ✔           |        |             |             |
| **C#**         |              |  ✔     | ✔           |             |
| **Go**         |  ✔           |        |             | ✔           |
| **Rust**       |              |  ✔     |             | ✔           |
| **Julia**      |  ✔           |        |             | ✔           |
| **Swift**      |  ✔           |  ✔     |             | ✔           |

 

Despite that thematic resonance, these languages aren't particularly
HPC-ready, at least without continuing to mix in other technologies
like MPI.  Although most of them have built-in features for
concurrency, parallelism, or asynchrony, they provide little to no
help with controlling locality or affinity, which is crucial for
scalable performance in HPC, and arguably where existing HPC notations
result in the most headache for users.


#### Maybe HPC Doesn't Need New Languages?

Another explanation might be that HPC doesn't really need new
languages; that Fortran, C, and C++ are somehow optimal choices for
HPC.  But this is hard to take very seriously given some of the
languages' demerits, combined with the fact that they are being (or
have been) supplanted by more modern alternatives in maintream
sectors.

I think it's definitely fair to say that Fortran, C, and C++ are
_sufficient_ for HPC, in the sense that the vast majority of notable
HPC computations from the past 30 years have been achieved using them
(in combination with libraries, directives, and extensions).  However,
to me, that's a bit like saying assembly programmers in the 1950's
didn't really _need_ Fortran.  Though assembly may have been
sufficient, raising the level of abstraction to provide cleaner syntax
and semantic checks, while also enabling compiler optimizations was, in
hindsight, pretty clearly the obvious right evolutionary step to take.

{{<pullquote>}}

Modern programmers would be shocked if they were expected to manually
move values in and out of registers.  We should be striving for
languages and compilers that similarly handle data transfers across
nodes, or between GPU and CPU memories.

{{</pullquote>}}


Continuing with the Fortran analogy, at their core, most HPC notations
tend to be fairly mechanism-oriented:

* "Run a copy of this program on each core/node/socket"

* "Allocate a chunk of this conceptually unified data structure here"

* "Send this message from here and receive it over there"

* "Launch this kernel on an accelerator"

This is arguably a big part of why we have to keep adding new
notations whenever system architectures evolve.  Though HPC
programming isn't literally assembly, it's similarly focused on
manually directing the use of system capabilities.  It's also similar
in its focus on explicitly moving data across the memory
hierarchy---simply at a different levels than before.  Where assembly
programmers move values between memory and registers, HPC programmers
express copies between distinct memories using various mechanisms like
`MPI_Send/Recv()`, `shmem_put()`, or `cudaMemcpy()`.

A good language would bring similar benefits to the HPC field as
Fortran did for assembly: improved syntax for productivity, semantic
checks for safety, and compiler optimizations for performance.  In the
same way that most modern programmers would be shocked if they were
expected to manually move values in and out of registers today, we
should be striving for languages and compilers that produce a similar
response in future HPC programmers by handling data transfers across
nodes, or between GPU and CPU memories.

The Fortran analogy also extends to programmer attitudes: Just as
assembly programmers were reluctant to give up their control and place
faith in optimizing compilers, so have HPC programmers been reluctant
to give up their Fortran, C++, and MPI—and not without reason!
Having control is important in HPC, since (in theory) it gives
programmers access to the system's raw capabilities with nothing
standing in the way.  But just as Fortran didn't remove the ability to
drop down to assembly when needed, good HPC languages would similarly
support calling out to existing low-level notations, or embedding them
directly.


#### Is it for Lack of Trying?

A third potential explanation for why new HPC languages haven't taken
off could be due to a lack of attempts to create them.  But as anyone
paying attention to the past 30 years of HPC research knows, this is
clearly not the case.  Focusing on what I'd consider to be the most
notable HPC programming language designs from the past 30 years,
we have:

* Mid-to-late 90's classics:
  - **High Performance Fortran (HPF)**
  - **NESL**
  - **Single-Assignment C (SAC)**
  - **ZPL**
* PGAS founding members:
  - **Coarray Fortran (CAF)**
  - **Unified Parallel C (UPC)**
  - **Titanium**
* HPCS-era languages:
  - **Chapel**
  - **Fortress**
  - **X10**
  - **Coarray Fortran 2.0**
* Post-HPCS languages:
  - **Regent**
  - **XcalableMP**
* Embedded pseudo-languages:
  - **Charm++**
  - **Coarray C++**
  - **COMPSs**
  - **Global Arrays**
  - **HPX**
  - **Lamellar**
  - **Legion**
  - **UPC++**

And there have been many more in addition to these.

In creating this list, I don't mean to imply that all of these
attempts were suitable for broad adoption.  As a personal example,
while I consider my graduate school team's work on ZPL to have been a
great academic project that made notable contributions, it's not a
language that was positioned to be broadly adopted for {{<sidenote
"right" "a variety of reasons">}}Among them: a lack of generality; a
lack of typical commonplace mainstream features like object-oriented
programming; insufficiently rich forms of parallelism for the
architectures that were on the horizon at the time; and insufficient
capabilities for programming at a lower level or interoperating with
other languages.  {{</sidenote>}}.

Failure to broadly adopt new HPC languages thus far doesn't mean that
we should stop trying.  Failures should be considered an opportunity
for learning and inspiration rather than "proof" that pursuing HPC
languages is pointless or without value.




#### OK, Then Why?

In my opinion, the relative stasis in HPC programming languages can be
attributed to a number of factors:

* **The HPC community is unique and has unique computational needs**

  For me, this is much more of a reason to develop HPC-oriented
  programming languages than not to do so, but I think it helps
  explain the status quo as well.  By being one of the few communities
  to care about distributed-memory parallelism, our chances of having
  another, larger community develop a language that happens to solve
  our problems for us are low.  Though HPC has tried leveraging
  popular mainstream technologies to meet its needs over the
  years---such as Java, Map-Reduce, Python, or Javascript---very few
  of these attempts have achieved the combination of portability,
  performance, scalability, and control that HPC tends to require.

* **HPC often has to prioritize maintaining legacy applications over
  writing new ones**

  A fact of life in HPC is that the community has many large,
  long-lived codes written in languages like Fortran, C, and C++ that
  remain important.  Such codes keep those languages at the forefront
  of peoples' minds and sometimes lead to the belief that we can't
  adopt new languages.  But this ignores the fact that new languages
  can interoperate with legacy ones, or even use them as a fallback,
  similar to how Fortran or C programmers might use assembly for key
  kernels.  It also neglects the benefits of writing new applications
  or rewriting old ones using modern technologies.

* **HPC's investment in, and attention span for, new hardware
  dramatically outpaces that of software**

  My perception, which may very well be biased, is that the HPC
  community's budgets and focus (think: funding opportunities, awards,
  keynote speakers, etc.) tend to place far more emphasis on novel
  hardware, systems, and architectures than on user-facing software.
  To some extent, this bias is perhaps inevitable since it's the
  hardware that has historically made HPC unique.  Yet hardware is
  barely usable without software, and by not investing in software
  more, we create a viscious cycle in which software remains an
  afterthought rather than a primary area of focus.  This is also
  somewhat unfortunate since investments in HPC software can compound
  across generations of hardware, whereas hardware has often seemed to
  involve starting back near square one with each new network toplogy,
  processor architecture, etc.

* **We tend to focus on what's sufficient rather than what's ideal**

  In large part because of the previous point, our programming
  notations tend to take a bottom-up approach.  "What does this new
  hardware do, and how can we expose it to the programmer from C/C++?"
  The result is the mash-up of notations that we have today, like C++,
  MPI, OpenMP, and CUDA.  While they allow us to program our systems,
  and are sufficient for doing so, they also leave a lot to be desired
  as compared to providing higher-level approaches that abstract away
  the specifics of the target hardware.

* **We tend to doubt that HPC is a sufficiently large or important
  community to warrant and sustain a language of its own**

  Related to the first point, there's a certain sense that we are a
  community that couldn't sustain a language of our own even if we
  wanted to.  While I understand that skepticism to an extent, I think
  it's more a product of our mindset, investments, and choices rather
  than an inevitability.  Consider: In these 30 years, we have moved
  from an era when HPC and parallelism were only available to a small
  fraction of programmers into one in which every processor supports
  parallelism and every cloud provider is happy to sell you time on
  their HPC-like systems.  Meanwhile, AI data centers increasingly
  dwarf traditional HPC ones.  Although HPC might be "niche" in the
  historical sense, the ability to do parallel computing is everywhere
  and the need only seems to be growing.  To that end, we ought to
  stop seeing ourselves as unworthy or unable to have a language, and
  to seize the opportunity to lead in directions that would be
  beneficial.

* **We tend not to develop support structures for HPC software beyond
  the research stage**

  This is perhaps one of the biggest challenges we face as a
  community.  Even if you believe in the funding imbalance between
  hardware and software that I mention above, opportunities for doing
  HPC software reseach have nevertheless been abundant.  Where things
  feel more lacking, however, is in providing paths to sustain HPC
  software over time, particularly as it moves from research to
  production.  I remember being shocked early in my career to learn
  about the funding challenges the MPICH group faced at Argonne
  National Laboratory at a time when MPI was already a dominant and
  crucial technology, with MPICH as the most important implementation.
  If we treat HPC software as a research activity only, we will never
  be able to go beyond the bare minimum, and we increase the
  likelihood of getting locked into incremental or vendor-specific
  solutions.

* **Typical social challenges of language adoption**

  On top of all the above, we have the typical social adoption
  challenges that all new languages face: "Will this language catch on
  and become popular, or will I be the only one to ever use it?"
  "Does it have sufficient backing from a company or institution that
  will keep it alive over time, once the initial flush of novelty
  wears off?"  While these concerns are regrettable, they are also a
  reality and completely understandable.  However, in mainstream
  programming we can see that compelling and well-funded languages can
  achieve the escape velocity needed to take off, as noted
  [above](#is-language-design-dead); and we shouldn't assume that the
  HPC community doesn't have the ability to create such success
  stories as well.

* **We increasingly live in a post-programming world**

  During the 90s and HPCS program in the early 2000s, the HPC
  community's appetite for a scalable parallel programming language
  seemed significant.  However, as time has passed, the disposition of
  HPC software engineers seems to have shifted from being
  programming-centric to relying increasingly on pre-existing
  libraries, to replicate the Python experience of creating
  applications by fusing together code written by others.  The advent
  of GenAI seems to have only increased doubts that programmers and
  programming are essential.  Despite these trends, I believe that
  good parallel programming language design remains important.  Even
  if most programmers are users of libraries or AI, good languages
  still ease the burdens of the programmers who are creating the
  libraries or trying to check, evolve, and maintain codes written by
  AI.


### So What Should We Do?

If you believe, as I do, that we can and should do more to nurture the
creation and adoption of new languages for scalable parallel
programming, here are some things for us to do:

* Rather than thinking of the HPC community as being too small,
  isolated, or niche to support a parallel programming language, we
  should **embrace the ubiquity of parallelism** and the needs for it
  outside of traditional HPC---from multicore desktops to the cloud
  and AI datacenters.  After all, fostering parallel computing
  communities at smaller scales can only benefit the HPC community by
  being welcoming to more users, introducing new use cases and
  opportunities for HPC, and enabling more computational science for
  the benefit of humankind.

* We should **create funding structures** that support the ability for
  promising software concepts to transition from research to
  production, and to sustain them long-term.  Willingness to pay for
  software seems to be at an all-time low, but software remains
  essential, and funding for it needs to come from somewhere.

* Similarly, we need to make sure people understand that **open-source
  software does not happen for free**.  It's wonderful that so many
  HPC software projects are now open-source, as this significantly
  helps with the adoption of new tools, and enables their continual
  improvement through community contributions.  However, we shouldn't
  forget that maintaining them, improving them, and porting them to
  the next generation of hardware (or system-level software) can be a
  full-time task that requires many engineering hours.  The recent
  formation of the High Performance Software Foundation (HPSF) within
  the Linux Foundation has been a notable step toward creating
  community among open-source HPC software projects.  Yet it's still
  not clear how to sustain such projects long-term without ongoing
  financial investment.

* We should establish mechanisms for doing **comparisons or bake-offs
  of HPC software technologies**, such as supporting forums for
  interactions between application developers and software teams, or
  establishing frameworks for cross-notation comparisons—for example,
  an HPC equivalent to the [Computer Language Benchmarks
  Game](https://benchmarksgame-team.pages.debian.net/benchmarksgame/index.html),
  an updated version of the [HPC
  Challenge](https://www.hpcchallenge.org/) competition, or a
  TOP500-style ranking that takes programming into account.

* As users, we should challenge ourselves to **avoid dismissing
  technologies prematurely** based simply on conventional wisdom or
  what "the experts" say.  We should try more things firsthand, and
  form our own opinions as to what our community should be building
  and how it needs to improve.


### Hold on, What About Chapel?

Those who know me, or my team's work on the [Chapel
language](https://chapel-lang.org), may be surprised not to see it
mentioned more in this article, and curious to know how it fits into
this narrative.  I didn't want Chapel to dominate this article, but I
would like to touch on its place in the landscape before wrapping up.

Chapel is a prime example of several benefits that languages can bring
to scalable computing that I mentioned in this article:

* It demonstrates how higher-level languages can be more **resilient
  to hardware changes** than notations that are more
  mechanism-oriented.  Apart from commodity vector processors, Chapel
  predates all of the hardware advances [listed above]({{<relref
  "#hpc-systems-then-vs-now">}}), including commodity multicore
  processors.  Yet, because its design focuses on the expression of
  parallelism and locality independently of specific hardware
  mechanisms, it has adapted very well to the massive changes in HPC
  compute nodes, networking, and architectures that have taken place
  over its lifetime.  This has played a big role in its longevity, as
  well as that of programs written in it.

* Chapel successfully **abstracts data movement** between compute
  nodes and memories, much as Fortran did for assembly programmers.
  It does this using a global namespace that permits variables to be
  read or written regardless of whether they live in local or remote
  memory.  This permits the programmer to focus on their algorithm
  rather than on explicit sends, receives, puts, gets, or mem-copies.

* It supports **programming at higher or lower levels**, including the
  ability to drop into C, interoperate with other languages and
  libraries, or perform explicit communication or copies when a user
  prefers to.

* Its features that support the clean expression of algorithms also
  support **compiler-driven optimizations**.  See Engin Kayraklioglu's
  recent HPSFCon talk, [_The Case for Compiled Languages for
  HPC_](https://youtu.be/e_8wuKXhm6A?si=jhaeFX60o7F2Mnc5) or [its
  slides](https://chapel-lang.org/presentations/EnginHPSFCon2026-Compiler.pdf)
  for a nice introduction to several such cases.

I didn't put Chapel on my list of broadly adopted HPC programming
notations [above](#hpc-programming-then-vs-now), in large part to
avoid being presumptuous.  But it's also because I don't consider
Chapel's support to be as solid as the others on my list.  Despite
those hesitations, I think Chapel is competitive with them in many
respects.  For example, I believe we have grown a larger and more
organic user community than some of the other notations on my list,
and with less help from public institutions.  Unfortunately, most of
Chapel's users tend to be academic groups who can afford to try an
emerging language in their work, yet without being in a position to
fund its development themselves.


{{<pullquote>}}

Chapel’s future in large part depends on the degree to which the
parallel programming community has an appetite for alternatives to the
status quo and a desire to support such an alternative.

{{</pullquote>}}

When I think of the biggest risks to Chapel's longevity, they overlap
heavily with the [factors above](#ok-so-then-why) related to stasis in
HPC language design.  Finding research funding for Chapel was not
terribly difficult, but finding funding to support users and improve
our implementation over the long-haul has been far more so.  Chapel is
considered an expensive software project, and perhaps it has been
relative to many HPC software teams; yet it's dwarfed by most HPC
hardware projects, despite continually building on its investments
rather than needing to start from scratch with each new hardware
generation.  Ironically, its longevity has also become something of a
hindrance because we're no longer the flashy new kid on the block, so
it's easy to lazily think things like "if it hasn't taken over the
world by now, something must be wrong with it;" or, on the opposite
end of the spectrum, "it's been around for quite awhile, so probably
will be forever."

Meanwhile, some of my factors for stasis are also to our advantage.
Chapel does meet the unique needs of HPC, while also having a role to
play in desktop, cloud, and AI computing.  There are not many other
languages vying for the title of general-purpose scalable language
anymore.  And given the choice of modifying or maintaining code
written for libraries and/or by AI in Chapel vs. conventional
languages, Chapel has distinct strengths and advantages.

At this point, Chapel's future depends primarily on our ability to
grow the community of contributors, stakeholders, and investors, which
in large part depends on the degree to which the parallel programming
community has an appetite for alternatives to the status quo, and a
desire to support such an alternative.


### In Closing

Though the lack of new, broadly adopted programming languages in HPC
over the past 30 years is disheartening to me, I still retain hope.  I
believe that the benefits of using a language that's purpose-built for
parallelism and scalability are significant.  I also believe they are
largely unknown to most HPC programmers, due to their not having had
the opportunity to try them.  In our project's experience, we've seen
the impact that Chapel can have on [users' ability to get things done
productively and efficiently]({{<relref
7-questions-for-chapel-users>}}), and we want to replicate that
experience from tens of applications to hundreds or thousands.

{{<pullquote>}}

I consider current and aspiring parallel programmers to be at least as
worthy of modern, post-Fortran/C/C++ languages as the Python, Rust,
Swift, and Julia communities are.

{{</pullquote>}}

I'd like to close by asserting that for all the reasons that new HPC
languages have not been adopted, I consider current and aspiring
parallel programmers to be at least as worthy of modern,
post-Fortran/C/C++ languages as the Python, Rust, Swift, and Julia
communities are.  I also desperately hope that when 30 more years have
passed—or ideally, well before then—we'll have at least one broadly
adopted language that supports scalable parallel programming rather
than our current count of zero.



### For More Information

On the Chapel website, you can browse the slides from the
[HIPS](https://chapel-lang.org/presentations/ChamberlainHIPS2025-presented.pdf)
and
[CLSAC](https://chapel-lang.org/presentations/Chamberlain-CLSAC2025-presented.pdf)
talks that this article was based upon.  If you'd like to read more
about why I think Chapel is well-positioned to be a broadly adopted
HPC language despite all the challenges around doing so, check out my
[10 Myths About Scalable Parallel Programming Languages
(Redux)]({{<relref
"10-myths-about-scalable-parallel-programming-languages-redux">}})
series on this blog, or jump to the [final article's
summary]({{<relref "10myths-part8#summary">}}) to get the takeaways
and pick an entry point that's attractive to you.  And, if you'd like
to discuss this topic more, I'm always interested in good
conversations on it.

---

**Acknowledgements:** I'd like to thank [Engin
Kayraklioglu](/authors/engin-kayraklioglu) for providing helpful
feedback and advice on this article, and also for encouraging me to
capture these talks in blog form to begin with.
