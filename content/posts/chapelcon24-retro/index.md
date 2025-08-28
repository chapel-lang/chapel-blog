---
title: "Reflections on ChapelCon '24: A Community Growing Together"
date: 2024-07-01
tags: ["ChapelCon", "Community"]
series: []
summary: "This post is a retrospective on ChapelCon '24"
weight: 15
authors: ["Engin Kayraklioglu"]
---

The Chapel event of the year, ChapelCon '24, has concluded! If you missed it,
don't worry; contents including slides and video recordings of all talks are
available on the [ChapelCon '24
webpage](https://chapel-lang.org/ChapelCon24.html). This year, our main focus in
organizing the event was to make it more community-oriented than its predecessor,
{{< sidenote "right" "CHIUW" >}}
CHIUW stands for "Chapel Implementers and Users Workshop". If you are curious to
learn more about CHIUW, or its rebranding, check out [my previous article on
ChapelCon](https://chapel-lang.org/blog/posts/chapelcon24/).
{{< /sidenote >}}. It was amazing to serve as the General Chair
of ChapelCon&nbsp;'24, especially with the aim of increasing community
involvement and participation. That starts with the organization. I would like
to thank everyone involved in the ChapelCon organization, spanning 13
institutions across 6 countries. And a special shout out to Josh Milthorpe
(ORNL/ANU) for chairing the Program Committee --- a first for ChapelCon/CHIUW
where the Program Committee was not led by a Chapel team member.

In this article, I will share some big-picture highlights, parts that the
participants appreciated, and new ideas for next year's ChapelCon.


### A Keynote for the Ages

Our keynote speaker was Paul Sathre from Virginia Tech. For me, Paul's
keynote, _A Case for Parallel-First Languages in a Post-Serial, Accelerated
World_, was one of the best talks in 11 years of CHIUWs and ChapelCon. Paul
discussed the prevalence of parallelism and the shortcomings of traditional
programming models that form the basis of de facto parallel programming. His
talk was very supportive of thinking about parallelism early in programming
education. The ChapelCon audience has made it crystal clear that Paul's keynote
was the highlight of ChapelCon. Here is the  word cloud for the answer to the
question “Please identify the best parts of ChapelCon&nbsp;'24 for you”:

{{< figure src="wordcloud.png"
           class="fullwide"
           title="The Word Cloud of the Best Parts of ChapelCon '24 for Attendees" >}}

I strongly encourage checking out Paul Sathre's keynote. The
[slides](https://chapel-lang.org/ChapelCon/2024/sathre.pdf) and
[video recording](https://www.youtube.com/watch?v=G0LneLP1-Ko&list=PLuqM5RJ2KYFi2yV4sFLc6QeRYpS35UeKl&index=9&ab_channel=ChapelParallelProgrammingLanguage)
are available alongside the rest of the content from ChapelCon.


### Participation in Numbers

One of the big efforts this year was an increased focus on
publicity. With the addition of tutorials and structured coding events to the
schedule, it was key for us to reach potential Chapel users from all over the
world, with different backgrounds, and with different expectations from
their programming languages. As a result of these changes, we are excited that
we had about 50% more registrants at ChapelCon '24 compared to last year's
CHIUW.

Our 162 registrants spanned 28 countries from the Americas to the Middle East,
and from Africa to Europe. As the general chair of the event, seeing such
diversity among our participants has been a great highlight for me. Our
registrants have also listed 55 different affiliations including those from
industry, government, and academia.

{{< figure src="participants.png"
           class="fullwide"
           title="ChapelCon '24 Reached a More Numerous and Diverse Community Than Ever" >}}

Such diversity of backgrounds also underlines another shift in our messaging ---
Chapel is not a language just for HPC users; Chapel is for everyone who wants to
write fast and parallel applications more productively.

### Diving into Chapel: Tutorial and Coding Days

As I mentioned, adding tutorials to the agenda was one of the biggest changes
this year. Our first Tutorial Day featured a pair of 2-hour tutorials on Chapel
and Arkouda. We welcomed 56 different participants throughout the Tutorial Day,
who found the day informative. The hands-on parts of the tutorials also featured
more modern ways of using Chapel through GitHub Codespaces, and Arkouda through
Jupyter notebooks.

The following day was the Coding Day where the demo sessions were the stars of
the show. While we had similar events in the past, we expanded this year's
Coding Day significantly with the introduction of an Open Lab session. The Open
Lab was the place to be for those who wanted to learn more about Chapel by coding
and asking questions along the way. To supplement the more active learning style
of the Open Lab, we hosted
{{< sidenote "right" "5 demo sessions" -5>}}
These demo sessions were highly appreciated by the participants. We have also
been asked whether there will be recordings of the sessions. While we did not
record those sessions, we are currently planning to start recurring community
sessions where Chapel developers will demo different features of the language
through live coding, which we will record. Stay tuned on our Blog, Social Media,
and Discourse for further details!
{{< /sidenote >}},
where Chapel developers demonstrated different features of the language (such as
GPU support and IO) to the participants. The Open Lab ran alongside Office
Hours, where Chapel developers met with users in peer-programming sessions to
help with their specific Chapel applications. All in all, on the Coding Day, we
interacted with more than 30 Chapel users; new and experienced alike.

Both of these days were an experiment for us, and that experiment was largely
successful. Next year, based on suggestions from the attendee survey, we plan to
make our tutorials spread out a bit more and cover more areas of the language.
Furthermore, we are also considering making tutorials and coding events more
intertwined to create an even more engaging schedule and foster a better
learning environment.


### Expanding our Horizons: Conference Day

The final day of ChapelCon '24 was the Conference Day. For the experienced CHIUW
audience, this was a familiar setting --- invited and submitted talks from the
community, with Q&As and community interactions.

Beyond the keynote, the Conference Day featured the traditional State of the
Project talk by Brad Chamberlain. Opening the day, Brad summarized highlights
from the Chapel community since CHIUW 2023. As a widely-anticipated
talk by the community, the State of the Project was called out in several
attendee survey responses as one of the best parts of the Conference Day.

{{< figure src="sop.png"
           class="fullwide border"
           title="The Summary Slide from Brad's State of the Project Talk">}}

Brad's [slides](https://chapel-lang.org/ChapelCon/2024/chamberlain-sop.pdf) and
[video
recording](https://www.youtube.com/watch?v=nfxJ-tOsgrY&list=PLuqM5RJ2KYFi2yV4sFLc6QeRYpS35UeKl&index=2&ab_channel=ChapelParallelProgrammingLanguage)
are also available for those who want to have a 30-minute summary of Chapel
highlights from the last year.

The Conference Day would not be what it is if it wasn't for talks from our
community. This year, we had 5 sessions for talks: Tooling, Performance,
Outreach, Algorithms, and Chapel in the HPC Ecosystem. Being able to have a
program with these categories was another highlight for me. Why?

I view the Performance and Algorithms sessions as representative of fundamentals
of Chapel — delivering good performance on a wide variety of hardware across
distinct application fields are key goals of Chapel. Let me give a quick summary
of the talks in those sessions.

* The [Performance](https://chapel-lang.org/ChapelCon24.html#performance)
  session featured performance studies on sequential execution, multicore CPUs,
  single GPU, and GPU-based top supercomputers like
  [Frontier](https://www.olcf.ornl.gov/frontier/) and
  [Perlmutter](https://docs.nersc.gov/systems/perlmutter/architecture/). Seeing
  such a variety in four talks is a statement for Chapel delivering on its
  promise to achieve good performance across a wide variety of hardware.

* The [Algorithms](https://chapel-lang.org/ChapelCon24.html#algorithms) session
  had talks on tree and graph analytics, support for faster imaginary
  mathematical operations, and a study on using Chapel in meteorological
  research applications. As a general-purpose programming language, Chapel is
  already being used in many different types of applications.

What about other sessions? Tooling, outreach, and integration with other
technologies are essential for a healthy and mature software project. Seeing a
variety of talks from our community in those areas highlights the growing
momentum within our community that ignited with Chapel&nbsp;2.0. Let's take a quick
look at those sessions in more detail:


* The [Tooling](https://chapel-lang.org/ChapelCon24.html#tooling) session
  featured talks on a gdb-based Chapel debugger to help with debugging parallel
  Chapel applications in a familiar setting, and advanced editor support, which
  can make writing Chapel codes in modern IDEs like VSCode a breeze.

* The [Outreach](https://chapel-lang.org/ChapelCon24.html#outreach) session had
  a talk on an [Exercism](https://exercism.org/) curriculum in Chapel, aiming to
  provide a medium to learn Chapel as a first programming language. Another
  talk featured in this section gave a retrospective of an internship with the
  Chapel team at HPE.

{{< figure src="exercism.png"
           class="fullwide"
           title="A Snapshot of the Upcoming Chapel Page on Exercism" >}}

* Finally, the [Chapel in the HPC
  Ecosystem](https://chapel-lang.org/ChapelCon24.html#ecosystem) session. In
  this session, we had talks on using Chapel in a petabyte-scale,
  GPU-accelerated database engine, alongside HPX (a C++-based parallel
  programming library), and finally with Python (have you heard of it? I hear it
  is pretty cool) for HPC workflows.  What a nice variety of fields where
  Chapel can be used alongside other tools.

I hope you all can see what I see here --- a programming language with strong
fundamentals spreading its wings. I recommend checking out all the talks to
learn more about the varied and amazing work being done by the Chapel community.

### Want to Be Involved?

We are already looking forward to the next ChapelCon. One of the key points for
us will be to digest the survey results from this year again to make sure we
target areas of improvement noted by our attendees as a way to make ChapelCon
even more welcoming, from those who don't know Chapel at all, to those who have
been around for a while.

We want to increase our community's participation in planning as well.
Organizing events such as ChapelCon constitutes many small decisions and
associated work. The more diverse voices we have in such decisions and the work,
the better ChapelCons we will have. While we don't have anything concrete for
that at the moment, that is kind of the point --- we want to call for volunteers
to take part in the discussions and the organizational work. So, let this also serve
as an early call: if you are interested in helping organize the next ChapelCons,
please reach out!

