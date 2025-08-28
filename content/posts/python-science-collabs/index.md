---
title: "Doing science in Python?  Wishing for more speed or scalability?"
subtitle: "Can we help accelerate your Python-based computational science?"
date: 2024-04-30
tags: [Community, User Experiences]
summary: "A call for computational science collaborations around Chapel and Python"
authors: [Brad Chamberlain]
weight: 5
---

Our team at HPE is seeking scientists who are using Python in their
work, yet wishing for more speed or scalability from their
computations.  Specifically, we are interested in pair-programming to
see whether we can help make your computations go faster and/or handle
larger problem sizes.

Here are four quick questions to gauge whether such a collaboration
might be of interest to you:

* Are you a computational scientist whose project seeks to benefit the
  planet and its population?  (e.g., health science, climate science,
  earth sciences, green engineering, ...)

* Are you currently using {{< sidenote "right" "Python"
  >}}Or potentially R, Matlab, or another high-level scripting
  language?{{< /sidenote >}} for your computations?

* Do you ever wish that your computations ran faster or were capable
  of handling larger data sets?  Or that they ran on GPUs?

* Would you consider using a language other than Python to obtain such
  benefits?

If you answered "yes" to these questions, we'd be interested in
hearing from you, to see whether we can help you run at faster
speeds or larger scales.  To register your interest, see the link at
the end of this article.

But first, let's address some questions you might have:


### Wait... who are you?

We are a team of computer scientists and software engineers at Hewlett
Packard Enterprise with strong backgrounds in performance-oriented
scientific computing.  In addition to our day-to-day technical work, we are
interested (and experienced) in helping scientists in diverse fields
achieve greater performance and scalability in their computations.

Due to our personal interest in benefiting the planet, combined with
HPE's culture of seeking out creative ways to do so, we are
particularly interested in working with computational scientists whose
code has the potential to run faster, but who may not have the
experience or background to achieve that on their own.


### So, how can you make my computations faster?

Our team develops an open-source programming language named
[Chapel](https://chapel-lang.org) that is often compared favorably to
Python in terms of the ease of reading and writing code.  However,
where native Python code has inherent barriers to performance and
scalability, Chapel was designed with such concerns in mind from the
outset.

We also contribute to a software framework called
[Arkouda](https://github.com/Bears-R-Us/arkouda/blob/master/README.md),
which permits Chapel computations to be invoked from Python code,
optionally running in Jupyter notebooks.  This means that while Chapel might be
the means by which your computations run faster, you can still
interact with them in a familiar setting.

Chapel and Arkouda focus on leveraging parallel hardware effectively.
This can mean targeting the multicore processors and/or GPUs available
on a laptop, a departmental cluster, a cloud instance, or the world's
largest supercomputers.  In practice, some scientists have been happy
reaping Chapel's benefits on their laptops, while others have scaled
to thousands or even millions of processors.



### What are you proposing?

We understand that learning a new programming language or tuning for
performance can be daunting, particularly when you're trying to
get your science done.  And we also know that our team is unlikely to
be able to learn enough about other scientific fields to make a
meaningful contribution on our own.  So we're proposing meeting in the
middle through a virtual {{< sidenote "right" "pair-programming session" >}}
Or a small-group programming session if you're part of a team.{{< /sidenote >}}.

You bring your knowledge of your field and computation, while we'll
bring our expertise in performance-oriented parallel computing and
Chapel.  We'll use the session to hear about your computation, sketch
out some code, introduce you to Chapel, and see how far we can get
applying it to your computation.

If that initial session seems productive and promising, we can
consider doing more.  If it isn't, at least we'll each have learned a
bit more about the other's field, while likely gaining a new
perspective on our own.



### So... What's in it for the Chapel team?

Beyond the potential to help scientists solve problems faster or
larger than they might otherwise be able to, our motive is to
grow the Chapel community.  Larger user communities make new
languages healthier and more successful.  Our hope, of course, is that you love
Chapel and become part of the community going forward.  Yet even if that
doesn't happen, we'll hopefully gain insights into how Chapel could
improve and evolve to help users in your field in the future.



### Have other groups benefited from Chapel?

We obviously think Chapel is great, and happily, other groups who've
used it in their respective fields agree.  The following comments are
from scientists in the community describing Chapel's impact on their
work:

{{< quote person="Nelson Luís Diaz" position="Professor of Environmental Engineering, Federal University of Paraná (Brazil)" >}}
Chapel is fast. Parallelization is really easy! __I didn’t know I
could get so much from my desktop until I used Chapel__.
{{< /quote >}}

{{< quote person="Marjan Asgari" position="Physical Scientist at Natural Resources Canada" source="(on her experience using Chapel as a PhD student at the University of Guelph)" >}}
With Chapel, I found myself seamlessly transitioning every
potentially parallelizable aspect of my work from sequential to
parallel execution. For me, who had worked with Spark and Hadoop
before, __discovering that implementing parallelism among CPUs and
computers was as easy as defining a variable, was a big deal and so
exciting.__
{{< /quote >}}

{{< quote person="Scott Bachman" position="Scientist II, National Center for Atmospheric Research<br>Technical Modeling Lead, [C]Worthy, LLC" >}}
I have now written three major programs for my work using Chapel, and
each time I was able to significantly increase performance and achieve
excellent parallelism with a low barrier to entry. __Chapel is my go-to
language if I need to stand up a highly performant software stack
quickly, and I have truly enjoyed working with members of the Chapel
team__ if the technical requirements of my work went beyond what I could
program on my own.
{{< /quote >}}


{{< quote person="Simon Bourgault-Côté" source="(on his use of Chapel as a Research Associate, Polytechnique Montreal)" >}}
Chapel allowed us to train highly qualified personnel on the
development of an efficient parallel fluid dynamics simulation
software __in a short time without the hurdle of conventional parallel
programming languages.__
{{< /quote >}}


### Sounds great, what's next?

If this article's proposal intrigues you, [let us know about your
project and interest using this **online
form**](https://forms.gle/E5R9cwPjXDiwXm4aA).  As responses come in, we
will set up virtual meetings with as many users as we're able to.

In the meantime, if you'd like to learn more about Chapel, please see:

* Our recent announcement of [Chapel 2.0]({{< relref
  "announcing-chapel-2.0/index.md" >}})

* This recent blog post on writing [Navier-Stokes in Chapel]({{<
  relref "bns1/index.md" >}})

* The website for
  [ChapelCon'24](https://chapel-lang.org/ChapelCon24.html), the upcoming Chapel
  event of the year (June 5–7)

* [This LinuxCon 2023
  talk](https://www.youtube.com/watch?v=UxXqo8lYsI4) introducing
  Chapel (or [its
  slides](https://chapel-lang.org/presentations/ChapelForLinuxCon-presented.pdf))

* [This Open Source Connector
  talk](https://www.youtube.com/watch?v=gwrbBQiP5HQ), including a
  [live demo of
  Chapel and Arkouda](https://youtu.be/gwrbBQiP5HQ?si=CFd_KHB_JG560lXH&t=1380) (or
  [its
  slides](https://chapel-lang.org/presentations/chapel-open-source-connector.pdf))

Finally, if you know of colleagues or other groups that you think
would benefit from Chapel, please share this post with them as well!
