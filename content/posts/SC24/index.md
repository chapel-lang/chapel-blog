---
title: "SC24 from the Chapel Language Perspective"
tags: ["SCxy Conference", "Trip Reports", "Community", "Arkouda"]
summary: "A summary of highlights at SC24 relating to Chapel and Arkouda"
date: 2024-12-18
authors: ["Engin Kayraklioglu"]
---

_Supercomputing_, or simply _SC_, is a prestigious event for the HPC community.
Held annually for more than three decades, SC is where thousands of HPC users,
researchers, enthusiasts, and salespeople get together to share their work,
pitch new systems, network, and socialize. Both its technical track and
exhibition are among the most respected in the HPC community.  This year's SC
had a record attendance of over 18,000 participants as well as the largest-ever
exhibition floor.

As a reflection of our growing community, this year we had a busy roster of
Chapel events at SC24.

### Chapel/Arkouda at the HPE Booth

For the first time in Chapel's history, there was a Chapel/Arkouda demo at
the HPE booth. From Monday to Thursday, the HPE booth was never short of
activity. Festivities began as soon as the exhibition floor opened with the
announcement of El Capitan as the world's fastest supercomputer. With El Capitan
online, HPE bolstered its position as the industry leader in supercomputing. The
top three supercomputers in the [TOP500 list](https://top500.org/) (which happen
to be the only ones to break the exaflop barrier) are HPE Cray Supercomputing EX
systems.

{{< figure src="demo.png" caption="Our booth demo slides are [available online](https://chapel-lang.org/presentations/SC24/SC24-Booth-Demo.pdf)" >}}

Thanks to the espresso bar, fresh popcorn, El Capitan swag, and scavenger
hunts, there were no dull moments in the HPE booth for the rest of the event.
During this period, we demonstrated Chapel and Arkouda to many visitors at
our demo station. We also had the chance to chat with many of our fellow HPE
colleagues in person. We are looking forward to continuing our conversations
with Chapel and Arkouda enthusiasts, and with other groups at HPE. Our slides, which
also include two recorded demos, are [available
online](https://chapel-lang.org/presentations/SC24/SC24-Booth-Demo.pdf).


### Éric Laurendeau's Distinguished Talk at PAW-ATM

[PAW-ATM](https://sourceryinstitute.github.io/PAW/) is a workshop where HPC
technologies that are alternatives to the conventional MPI+X paradigm are the
main focus. PAW-ATM's popularity has kept it on the SC agenda for more
than a decade now, where it's been a forum for HPC users, developers,
researchers, and enthusiasts of Chapel and other programming paradigms to get
together and exchange ideas.

This year's PAW-ATM hosted the CHAMPS team's PI, Éric Laurendeau, as the Distinguished
Speaker. For those who haven't heard of CHAMPS before, it is a multiphysics
simulation software framework for aerodynamics developed by Professor Laurendeau's team at
Polytechnique Montreal. Boasting more than 150,000 lines of Chapel code,
CHAMPS is the largest application written in Chapel, to our knowledge.

{{< figure src="eric.png" caption="Éric's slides are [available online](https://chapel-lang.org/presentations/SC24/SC24-Eric-PAW-ATM.pdf)" >}}

Éric took the audience through a tour of what building an aircraft entails, from
the initial design to the final certification, highlighting the importance of computational
modeling. CHAMPS, entirely developed by his graduate students of mechanical
engineering, competes with other industry-grade modeling and simulation
solutions in terms of its fidelity to the real-world data. Éric also
demonstrated how Chapel makes parallel programming easy for his team. His slides
are
[available](https://chapel-lang.org/presentations/SC24/SC24-Eric-PAW-ATM.pdf) on
the Chapel website. Éric is a great speaker, and {{< sidenote "right" "if you registered for the SC24 Digital Experience" -3>}}If you don't have access to the SC24 recording, check out Éric's excellent [CHIUW 2021 keynote](https://www.youtube.com/watch?v=wD-a_KyB8aI&t=2s)
instead.  {{< /sidenote >}}, you can
[watch his
talk](https://sc24.conference-program.com/presentation/?id=misc202&sess=sess734).  We also recommend
reading his recent interview, [7 Questions for Éric Laurendeau: Computing Aircraft
Aerodynamics in Chapel](https://chapel-lang.org/blog/posts/7qs-laurendeau/) on
the Chapel Blog.


### Chapel and Arkouda Talks in the SC24 Technical Program

The Chapel team had several talks in the SC schedule as well. Materials from
these talks are now all available online. Read on for the full list with quick
summaries.

#### Bioinformatics and Chapel
Michael Ferguson presented __Exploring Suffix Array Algorithms in Chapel__ at
the Parallel Applications Workshop (PAW-ATM). Michael summarized how suffix
array algorithms can be implemented in parallel in Chapel to help metagenomics
research. This work was a summary of a collaboration with Bonnie Hurwitz, a
professor at the University of Arizona. You can find Michael's
[slides](https://chapel-lang.org/presentations/SC24/SC24-Michael-Suffix.pdf) on
our website. His [code](https://github.com/femto-dev/femto) is also available
online.

#### Python for Science at Scale: Arkouda
Ben McDonald presented __Exploring Data at Scale with Arkouda: A Practical
Introduction to Scalable Data Science__ at the [High Performance Python for Science
at Scale (HPPSS)](https://hppss.github.io/SC24/) workshop. Ben demonstrated how Arkouda's
Python client/Chapel server architecture can enable interactive exploratory data
analytics at scale. His slides are
[available](https://chapel-lang.org/presentations/SC24/SC24-Ben-Arkouda-HPPSS.pdf).
We also recommend checking out [his live
demo](https://www.youtube.com/watch?v=__pXYW359Ws&list=PLuqM5RJ2KYFhFqqL5eo4SWHEA8pJV7QBD&index=3&ab_channel=ChapelParallelProgrammingLanguage)
where he processes hundreds of GBs of data interactively, using only a couple of nodes 
and Arkouda.

#### Chapel's Take on GPU Programming
I presented __Productive, Vendor-Neutral GPU Programming Using
Chapel__ at the [Workshop on Accelerator Programming and Directives
(WACCPD)](https://waccpd.org/). I went through examples with less than 10&nbsp;lines of code to showcase how applications can easily be made parallel,
distributed, and GPU-enabled. You can check out [my
slides](https://chapel-lang.org/presentations/SC24/SC24-Engin-GPU-WACCPD.pdf) on
the Chapel website. Alternatively, you can watch a live [GPU programming
demo](https://www.youtube.com/watch?v=5OqjQhfGKes&list=PLuqM5RJ2KYFjYgOStSfrNshIQ0I-AibHY&index=5&ab_channel=ChapelParallelProgrammingLanguage)
or
[presentation](https://www.youtube.com/watch?v=nj-WqhGEy24&list=PLuqM5RJ2KYFin_PkkaAJWJF1KjcVGnagh&index=2&ab_channel=HewlettPackardEnterprise)
to learn more about GPU programming in Chapel.

#### Applications-First Approach in HPC Education
I also presented __Consider an Applications-First Approach for PDC__
at the Workshop on [Education for High-Performance Computing
(EduHPC)](https://tcpp.cs.gsu.edu/curriculum/?q=eduHPC24) on behalf of Michelle
Strout. This talk proposed an alternative approach in Parallel and Distributed
Computing whereby teaching parallel programming is not approached from the
bottom up, as is typically done today (with OS and hardware knowledge as
prerequisites), but top-down where relatable parallel applications are used to
introduce parallelism concepts to highlight their benefits.
[Slides](https://chapel-lang.org/presentations/SC24/SC24-Michelle-AppFirst-EduHPC.pdf)
from this talk are online. If you are interested in using Chapel in teaching,
please reach out to the Chapel team at HPE and check our [upcoming
events](https://chapel-lang.org/events.html) page for monthly educator meetups, which
take place on the 2nd Wednesday of each month.

### Closing Thoughts

The Chapel team has been working on preparing for SC24 for months, alongside many
other teams at HPE. Beyond preparing Chapel-related material, Michelle Strout
and myself served on the Technical Program Committee, and I also served on the
Organizing Committee for PAW-ATM.

The Chapel community didn't forget to have fun and socialize this year either.
During our annual [Chapel Users Group happy hour
(CHUG)](https://chapel-lang.org/CHUG.html), we got to know each other better,
where some members of the community met for the first time in person after
years of close collaboration.

The Chapel team had a very productive SC24. Above, we've summarized the
Chapel-related events at a variety of venues within SC24. However, business
cards being passed around, community discussions, hallway conversations, and
exchanges during loud parties are what ignite new collaborations at SC. And we
had countless of those.  We are very excited to foster those relationships
and grow our welcoming community even further. We hope to see you all at SC25!

