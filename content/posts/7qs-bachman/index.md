---
title: "7 Questions for Scott Bachman: Analyzing Coral Reefs with Chapel"
date: 2024-10-01
tags: ["Earth Sciences", "Image Analysis", "GPUs", "User Experiences", "Interviews"]
series: ["7 Questions for Chapel Users"]
summary: "An interview with oceanographer Scott Bachman, focusing on his work to measure coral reef biodiversity using satellite image analysis"
authors: ["Brad Chamberlain", "Engin Kayraklioglu"]
featured: true
interviewee_photo: "bachman.jpg"
---

In this second installment of our [Seven Questions for Chapel
Users]({{< relref "series/7-questions-for-chapel-users" >}}) series,
we're looking at a recent success story in which Scott Bachman used
Chapel to unlock new scales of biodiversity analysis in coral reefs to
study ocean health using satellite image processing.  This is work
that Scott started as a visiting scholar with the Chapel team at HPE,
and it is just one of several projects he took on during his time with
us.  Since wrapping up his visit at HPE, Scott has continued to apply
Chapel in his work, which he describes below.

One noteworthy thing about the computation Scott describes here is
that it is just a few hundred lines of Chapel code, yet can be used to
drive the CPUs and GPUs of the world's largest supercomputers.  This
serves as a sharp contrast with the 100+k lines that make up the
CHAMPS framework covered in our [previous interview]({{< relref
"7qs-laurendeau" >}}).  Together, the two demonstrate the vast
spectrum of code sizes that researchers are productively writing in
Chapel.

This interview was conducted live (online) on August 23rd, and was
edited for clarity with Scott's assistance.


### 1. Who are you?

My name is Dr. Scott Bachman.  I am an oceanographer currently at the
National Center for Atmospheric Research (NCAR), and also at
[[C]Worthy](https://www.cworthy.org/) where I'm the technical modeling
lead.  I have been an oceanographer for just about 10 years since my
Ph.D.  I have expertise in physics, fluid dynamics, and large-scale
computing, at least within the scope of computational oceanography.
I'm not necessarily an HPC computer whiz, but I'm pretty good by
scientist standards.  At NCAR we use HPC heavily—NCAR owns its own
clusters.  At [C]worthy we also do that, although we kind of bounce
between clusters operated by DOE and NSF.


### 2. What do you do? What problems are you trying to solve?

In my position at NCAR, I solve problems related to ocean physics,
understanding how the ocean behaves, making connections to climate
change, and how we can prepare for it and mitigate risk.  So one thing
that I've done with Chapel specifically is that I wrote, or
essentially translated, a code that has been used to calculate
biodiversity in coral reefs.

Previously that was done serially in MATLAB, and it was creating an
enormous bottleneck for the scientists because it was just not
performing at all, and they were not able to do these biodiversity
analyses at any kind of interesting scale—they were limited to very,
very small islands and atolls.  And the challenge with reefs is that
they're very scattered and also very small.  This means you have to
cover a massive footprint even though the individual reefs are pretty
tiny.

{{% pullquote %}}
Coral reefs are home to about 25% of all marine life at some stage of
their life cycle, so even though they cover a tiny, tiny area, they
are massively important for the entire oceanic food web, and
therefore, so many other things.
{{% /pullquote %}}

I consider this work to benefit humankind, though I think a lot of
people who don't live near reefs don't even understand that they're
living things.  Coral reefs are home to about 25% of all marine life
at some stage of their life cycle, so even though they cover a tiny,
tiny area, they are massively important for the entire oceanic food
web, and therefore, so many other things.  I think their value in
monetary terms has been calculated at something like $10 trillion.
And they provide coastal protection, they provide fisheries, they can
provide so many more things.

So it's very, very important to try to conserve what reefs are left,
and we're losing them very rapidly.  People in Florida, for the most
part, don't even recognize that their state has lost practically all
of their reefs, which used to be world-renowned.  So it's the
unfortunate property that coral reefs are hidden underneath the water,
and unless you go into the water and go under, you won't ever see
them.  But they're there and they're really, really important.

{{% pullquote %}}
It's understandable that a lot of people are limited to the domain of
running their programs serially, which is fine for the most part until
you run into a problem that requires an enormous scale or enormous
speed.
{{% /pullquote %}}



### 3. How does Chapel help you with these problems?

Chapel has helped with this particular problem due to its speed and its
ease of use.  As you know, climate scientists tend not to be computer
scientists, even though we use computers a lot.  Most of us have skill
in some kind of scientific software or programming language—usually
it's Python or MATLAB.  But as a community, we tend to achieve only
such a level of skill with those languages that we never really get
deep into the weeds unless we're very much on the computational
physics side.  So it's understandable that a lot of people are limited
to the domain of running their programs serially, which is fine for
the most part until you run into a problem that requires an enormous
scale or enormous speed.

This problem that I have been working on for coral biodiversity was
one such problem where they had really high-resolution satellite
imagery with tons and tons of data; but they weren't able to work
through the data fast enough to do anything really useful.  So I
picked up that problem when I started working with the Chapel team at
HPE, and I was able to stand up a highly, highly parallelized version
of their biodiversity solver without too much trouble.  I had some
guidance from developers on the Chapel team like Ben Harshbarger, but
otherwise Chapel's ease-of-use was perfect for it.  It let me split up
these satellite images very naturally into sub-images that could be
mapped to different nodes, and it was pretty much embarrassingly
parallel, so it broke the door open to so much progress.

I generally ran the simulations on the NCAR supercomputer.  Basically
my colleagues fed me imagery to work with, and I could give it back to
them in a matter of minutes after the preprocessing.  So yeah, it's
this really powerful, potent thing that is only about 300 lines of
code, and they're still so excited about it.  And I'm so excited about
it too.


### 4. What initially drew you to Chapel?

My case is a bit unique in that I applied for the visiting scholar
position and was able to
{{< sidenote "right" "coerce you guys into giving it to me" >}}
Editors' note: No coercion was needed!  Scott was a great match for
what we were looking for, which was for someone to bring their domain
expertise and see what they could accomplish with Chapel while working
within our team.{{< /sidenote >}}. I've worked with HPC code and HPC
clusters quite a lot in my career, and I've felt the pain of working
in Fortran and C and MPI.  I was not super-familiar with Chapel at all
prior to applying, but when I saw what it was purporting to offer as
far as low barrier-to-entry and super-high performance, it definitely
caught my attention—especially having encountered situations where
parallel libraries like Dask with Python can be really finicky and
really hard to use.  It's just like, man, there are a lot of easy
problems that people can't attack without something like Chapel.  And
so, yeah, I got really intrigued by it.


{{% pullquote %}}
With the coral reef program, I was able to speed it up by a factor of,
like 10,000. I would say some of that was algorithmic... but again,
Chapel had the features in the language that allowed me to do it
pretty succinctly.
{{% /pullquote %}}


### 5. What are your biggest successes that Chapel has helped achieve?

With the coral reef program, I was able to speed it up by a factor of,
like 10,000.  I would say some of that was algorithmic; I exploited
some properties of this problem that sped it up tremendously, not even
including the parallelism part.  But again, Chapel had the features in
the language that allowed me to do it pretty succinctly.

{{< figure src="Reef.png" caption="Reef classification as performed by Scott's code, along with the speedup achieved" >}}

I think that right now we're at two or three journal papers that have
been submitted, and are at various stages of review and revision, that
were made possible by this program.  The code continues to be a
cornerstone of this grant that we're just starting.  It's like a
three-year grant to continue this and link biological sampling with
remote sensing.  So they're really leaning on me for the remote
sensing and processing of that stuff, and eventually it's going to
lead to a global data set that we'll put online.  So it's already
borne a lot of fruit, and it will definitely continue to do so.  And I
don't expect that the usefulness of a Chapel program like this is
going to expire anytime soon.  If anything, I think it'll grow.


### 6. If you could improve Chapel with a finger snap, what would you do?

Oh boy, if I could improve Chapel with a finger snap, what would I do?
Wishlist item one would be full GPU support.  I know that's [currently
in-progress](https://chapel-lang.org/blog/series/gpu-programming-in-chapel/),
and that when I was working with you guys you wanted to take my coral
program and use it as patient zero, which was cool.  I don't know how
far it's come since then but the bottom line is that the vast majority
of the work we do is based on arrays and looping over arrays and
stencils, doing the same operation on a bazillion points.  Just having
the ability to say "this problem is embarrassingly parallel, let's run
it on 15,000 GPU cores" without any real modification to the code
would be nice.  Having forall loops that could target multiple GPUs in
this way, similar to how current ones can target multiple compute
nodes...that would be amazing.

Another wishlist item, [one which I know you guys are working on]({{<
relref "announcing-chapel-2.1/#installationportability-improvements"
>}}), is to simplify building it on some arbitrary cluster.  That, to
me, is one thing that, when people inquire about Chapel, I always have
to tell them that once it works, it's amazing; but that getting that
first program compiling and running on a new system can be a job.
This relates to the way Chapel currently exists in the programming
language ecosystem.  For a scientist like me, when we come to a
cluster, you get on, and they've already got Python, Perl, C, Fortran,
all the compilers, all that stuff.  But Chapel, unless it's an HPE
cluster, Chapel usually does not come with it, and you have to put it
on there yourself.  If every system just had it available out of the
box, this whole item would be a moot point.

The last one, which I think of as more of an inter-language issue,
would be to ease the difficulty of reading and writing simple things
like binary and text files.  I wish Chapel were more like Python where
you have an array and can just do `array.toFile()` and it's done.
With Chapel, it's like you have to open buffers and I don't know what
else, but it's more complex.

{{% pullquote %}}
I told them 'Don't hire software engineers.  I'll do it, and I'll
write it in Chapel because I can do it by myself, and I can stand this
thing up really fast.'  And that is exactly what happened.
{{% /pullquote %}}


### 7. Anything else you'd like people to know?

Working with Chapel made such an impression on me that when I started
at [C]worthy the next year, my boss wanted to pick my brain about how
to do this really cutting-edge project that no-one's ever done before.
I told them "Don't hire software engineers.  I'll do it, and I'll
write it in Chapel because I can do it by myself, and I can stand this
thing up really fast."  And that is exactly what happened.

So I think, as far as my use cases, Chapel has proved itself multiple
times, and I'm using it now, and next time we talk in one of these
interviews, I'll tell you about the [C]worthy project.

---

Thanks very much to Scott for participating in this interview series!
To read or hear more about Scott's work in coral reef biodiversity,
check out his [PAW-ATM 2023
paper](https://dl.acm.org/doi/abs/10.1145/3624062.3624599), which was
[presented at
SC23](https://chapel-lang.org/presentations/Bachman-PAW-ATM.pdf), or
[watch an earlier version of the talk](https://youtu.be/lJhh9KLL2X0),
presented at [CHIUW 2023](https://chapel-lang.org/CHIUW2023.html).

And if you have any other questions for Scott, or comments on this
series, please direct them to the [7 Questions for Chapel
Users](https://chapel.discourse.group/t/7-questions-for-chapel-users-series-questions-comments/37200)
thread on Discourse.
