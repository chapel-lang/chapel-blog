---
title: "7 Questions for Bill Reus: Interactive Supercomputing with Chapel for Cybersecurity"
date: 2025-02-12
tags: ["User Experiences", "Interviews", "Data Analysis", "Arkouda"]
series: ["7 Questions for Chapel Users"]
summary: "An interview with Bill Reus about the creation of Arkouda, a Python library supporting interactive data analysis on HPC systems"
authors: ["Engin Kayraklioglu", "Brad Chamberlain"]
interviewee_photo: "reus.jpg"
featured: True
---

We're very excited to kick off the 2025 edition of our [Seven
Questions for Chapel Users]({{< relref
"series/7-questions-for-chapel-users" >}}) series with the following
interview with Bill Reus.  Bill is one of the co-creators of
[Arkouda](https://arkouda-www.github.io/), which is one of Chapel's
flagship applications.  To learn more about Arkouda and its support
for interactive data analysis at massive scales, read on!

### 1. Who are you?

My name is Bill Reus, and I live near Annapolis, MD and the beautiful
Chesapeake Bay. I am currently a data scientist doing statistical
modeling and simulation for the United States government, but I began
my career as an experimental chemist. In graduate school, I measured
electron transport through thin films of organic molecules using an
apparatus that our group invented to collect large volumes of noisy
data quickly and with low cost. This approach contrasted with the
typical means of studying molecular electronics, which was to spend
weeks or months collecting a small number of exquisite measurements in
ultra-high vacuum and at ultra-low temperature.

As it turned out, the key to making the quick-and-dirty method work
was applying robust statistical analysis to the resulting noisy data,
so on the path to my Ph.D., I taught myself the basics of programming
and data analysis. I enjoyed these activities so much that, after
graduating, I decided to switch to the burgeoning field of data
science. Joining the civil service offered me the opportunity to give
back to my country while launching my new career, and I have been in
or around government ever since (for the last two years, I have been
doing contract work for the government through a private company).

### 2. What do you do? What problems are you trying to solve?

{{% pullquote %}}
Spotting malicious activity requires bringing together massive amounts
of data and understanding it well enough to separate weak signal from
voluminous noise.
{{% /pullquote %}}

The work I’m writing about today began in late 2018 as an exploratory
effort to test the utility of data science in defending against the
malicious digital activities of competing nations. Such activities
regularly make the news, e.g. Russia’s hacking campaign in advance of
the 2022 invasion of Ukraine and the recently reported espionage by a
Chinese group dubbed [Salt
Typhoon](https://crsreports.congress.gov/product/pdf/IF/IF12798). These
groups take sophisticated measures to cover their tracks, and spotting
their activity requires bringing together massive amounts of data from
various sources and understanding it well enough to separate weak
signal from voluminous noise.

From a computational perspective, this kind of exploratory analysis
requires two things: a)&nbsp;resources of the scale and composition
familiar to the high-performance computing (HPC) community, and b)
tight interaction between human and computer. Data scientists who use
tools like Jupyter and languages like Python, R, and Julia are well
acquainted with the indispensable benefits of interactive computing on
workstations. However, the typical front door to a supercomputer—the
slurm job—is a fire-and-forget affair not conducive to exploratory
analysis. What was (and still is) needed is interactive
supercomputing.

{{< figure src="prod-vs-power.png" class="fullwide left-caption"
    caption="**Image motivating interactive supercomputing by analogy to transportation. Modes of transportation are arranged on a 2-dimensional grid of flexibility vs. power. At high flexibility and low power is a sports car representing single-node Python. At medium-high power and low flexibility are a bus and an airliner, representing cloud and HPC technologies, respectively. What data science needs is high flexibility and high power, represented by a fighter jet. The question is how to get there.**"
>}}

<br>

Several technologies attempt to bridge this gap between flexibility and
power in the quest for interactive supercomputing. In 2018–2019, our
group tried using Spark and Dask to sift through our cybersecurity
data, but we quickly ran into issues with stability and scaling. These
tools have improved greatly in the last five years, but at that time
it was clear to us that, although existing tools had a solid
foundation in the interactive user experience, they had a ways to go
before effectively leveraging the HPC. To meet our needs, we
ultimately concluded that we needed to try a complementary approach:
begin with a technology known to scale to hundreds of HPC nodes and
build towards interactivity.


### 3. How does Chapel help you with these problems?

At this point, my friend and colleague Michael (Mike) Merrill supplied
the crucial technical vision that led us to success. A towering figure
in the HPC community, Mike was an early adopter of Chapel and had used
it to run enormous computations before, so he was familiar with
Chapel’s performance and scalability. Additionally, he had the
foresight to envision how we could build an interactive front-end to a
persistent Chapel server that would run parallel, distributed
computations on data. From this idea, project
[Arkouda](https://github.com/Bears-R-Us/arkouda) was born (pronounced
ar-KOO-duh, this somewhat unwieldy name is Greek for “bear” and was a
riff on our office’s penchant for bear-themed project names). Sadly,
Mike passed away two years ago, but not before seeing his idea mature
into a platform used by dozens of data scientists and analysts for
cutting-edge cybersecurity research.

{{% pullquote %}}
It typically took a skilled programmer with no background in Chapel
mere weeks or months to begin contributing performant, scalable code.
{{% /pullquote %}}

Chapel was really the perfect language for the HPC-facing component of
Arkouda. The computations supported by Arkouda run the gamut from
data-parallel to task-parallel, from compute-intensive to
communication-heavy, so we needed a language that could achieve
world-class performance on a wide variety of tasks with as few lines
of code as possible. The plot below is a
[comparison](https://chapel-lang.org/chapelcon/2024/chamberlain-clbg.pdf)
of Chapel against other languages on axes of code size and execution
time on a set of desktop benchmarks, and it showcases Chapel’s
combination of performance and productivity on a single node.


{{< figure src="clbg-dec2024.jpg" class="fullwide left-caption"
    caption="**Comparison of Chapel and other programming languages on axes of compressed code size and execution time on a set of benchmarks (see [this ChapelCon '24 talk](https://www.youtube.com/watch?v=U8KM8wv32js&t=2s) or [its slides](https://chapel-lang.org/chapelcon/2024/chamberlain-clbg.pdf) for details). Chapel occupies the lower left corner, implying high performance from a small amount of code.**" >}}

<br>

In an HPC setting, Chapel is competitive with C++/MPI/OpenMP and
maintains [scaling](https://chapel-lang.org/scalable/) to thousands of
nodes for the communication- and memory-intensive kernels that Arkouda
uses heavily, like the argsort kernel whose performance is shown
below.  Meanwhile, the desired scope of Arkouda was ambitious,
comprising anything that one might typically do with NumPy arrays or
Pandas DataFrames (or similar data structures in Spark and
Dask). Creating a minimum viable product in C++/MPI/OpenMP might have
taken years and hundreds of thousands of lines of code, whereas our
project had six months to demonstrate real results in
cyber-defense. Chapel’s design as a productivity-oriented HPC language
enabled us, within a few months (and approximately ten thousand lines
of code), to hand our data scientists a prototype with enough
functionality and performance for them to demonstrate the value of
interactive supercomputing for cybersecurity.

{{< figure src="../announcing-chapel-2.0/arkouda-argsort.png" class="fullwide left-caption"
    caption="**Plot showing the scalability of Arkouda's sort implementation on both Slingshot-11 and HDR InfiniBand.**"
>}}

<br>

Productivity and performance were our initial reasons for choosing
Chapel, but we soon came to appreciate other, less obvious features of
the language. For example, Chapel’s natural abstractions for reasoning
about data locality and parallelism helped us quickly engage new
developers as Arkouda grew, because it typically took a skilled
programmer with no background in Chapel mere weeks or months to begin
contributing performant, scalable code.

Another great facilitator of Arkouda’s development was Chapel’s
portability: we could write code with a large supercomputer in mind
but compile and test the code on a laptop simulating a multi-node
environment for debugging. Although some performance issues can only
be diagnosed _in situ_, Chapel’s portability allowed the developers,
who did not have access to HPCs on the scale of what Arkouda users
had, to catch the vast majority of issues that would have otherwise
derailed users’ workflows.

But perhaps the best “feature” of Chapel proved to be the helpfulness
of the team developing the Chapel language, who worked energetically
hand-in-glove with the Arkouda developers to help us make the best use
of Chapel functionality and maximize performance.


### 4. What initially drew you to Chapel?

{{% pullquote %}}
I was on the verge of resigning myself to learning MPI when I first
encountered Chapel. After writing my first Chapel program, I knew I
had found something much more appealing.
{{% /pullquote %}}


I first encountered Chapel a few years before the start of Arkouda and
the cybersecurity project that spawned it. I was a data scientist in
the Python tradition making my first forays into the world of HPC and
looking for the quickest and easiest ways to speed up my computations
on single-node systems (servers and symmetric multiprocessors). I had
sampled various Pythonic approaches and was not impressed, so I turned
to lower-level methods like writing C extensions, multithreaded with
OpenMP and callable from Python. This technique was functional if
clunky, but I knew it would not take me beyond single-node
execution. I was on the verge of resigning myself to learning MPI when
I first encountered Chapel. After writing my first Chapel program (a
parallel, distributed hello world), I knew I had found something much
more appealing.

{{% pullquote %}}
Chapel's separation of concerns immediately felt like the most natural
way to think about large-scale computing.  I would highly encourage
anyone wanting to get into HPC programming to start with Chapel.
{{% /pullquote %}}

I quickly realized that Chapel’s parallel idioms were applicable to
both threaded and node-based parallelism, and that in fact data
locality in distributed memory was a _separate_ concept in the
language from parallel execution. I was hooked. This separation of
concerns immediately felt—and still feels—like the most natural way to
think about large-scale computing. I wish I had learned things that
way from the beginning, and I would highly encourage anyone wanting to
get into HPC programming to start with Chapel.


### 5. What are your biggest successes that Chapel has helped achieve?

As detailed above, Chapel was critical to the rapid deployment of
Arkouda, which was in turn essential to pioneering interactive
supercomputing for cybersecurity. At the time, no other technology had
the right combination of productivity and performance, but thanks to
Chapel and Arkouda, our rapid establishment of this capability caught
the eye of leadership and secured a place for HPC-enabled data science
in cybersecurity within the U.S. government. Although I can’t talk
about specific results, I can say that the U.S. and its allies have
appreciated this angle of insight into such a high-stakes domain.


### 6. If you could improve Chapel with a finger snap, what would you do?

Probably the biggest improvement I would love to see in Chapel is
support for incremental compilation, i.e. the ability to create a
shared library (think `.so`) that future programs can link to without
recompiling. I am excited by reports that this functionality might be
on the horizon!

### 7. Anything else you'd like people to know?

I would encourage anyone, regardless of HPC experience, to [try
out](https://chapel-lang.org/download/) Chapel. And when you do, be
sure to [reach out](https://chapel-lang.org/community/) to the Chapel
team early and often—you’ll make friends with some great people.

<br>

---

<br>

We'd like to thank Bill for participating in this interview series!
If you'd like to learn more about Arkouda, check out [its
website](https://arkouda-www.github.io/), be sure to watch [Bill's
CHIUW 2020 keynote
talk](https://youtu.be/g-G_Z_3pgUE?si=2QZohghDUo0nNgpW), or browse
other [Arkouda-related
talks](https://www.youtube.com/playlist?list=PLuqM5RJ2KYFhFqqL5eo4SWHEA8pJV7QBD)
on Chapel's YouTube channel.

If you have other questions for Bill, or comments on this series,
please direct them to the [7&nbsp;Questions for Chapel
Users](https://chapel.discourse.group/t/7-questions-for-chapel-users-series-questions-comments/37200)
thread on Discourse.
