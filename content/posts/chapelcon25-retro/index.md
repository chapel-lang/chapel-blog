---
title: "Reflections on ChapelCon '25"
date: 2025-12-05
tags: ["ChapelCon", "Community"]
series: []
summary: "A retrospective on ChapelCon '25 from general chair Brandon Neth"
weight: 15
authors: ["Brandon Neth"]
featured: true
weight: -1
---

ChapelCon '25 has wrapped up, and another year of productive HPC programming lies ahead!
Don't worry if you missed a talk, you can find the recordings and slides on the ChapelCon '25 [webpage](https://chapel-lang.org/chapelcon25/#program).
Before reflecting on the conference, I'd like to thank everyone who made ChapelCon '25 the exciting week it was. 
Thank you to contributors and participants for the exciting dialogue during our demo sessions and conference days.
Thank you to the program committee for your support in reviewing a record-breaking number of submissions.
And, of course, huge _thank-yous_ to Luca Ferranti for his work as Program Committee Chair, Daniel Fedorin for his as Tutorial Days Chair, and Jade Abraham for theirs as Office Hours Chair.

### Second Conference, First Experiments

As the [second instance of ChapelCon](../chapelcon24), this year's conference was our first opportunity to experiment with some changes to the conference format.
We tried out four changes to the conference: 
- a season change from early summer to early autumn, 
- an expansion from three days to four,
- a new format for tutorial days, and
- a new approach to the submission and review process.

All four changes were largely successful, both in terms of improving the conference experience and teaching important lessons about what makes ChapelCon a valuable community gathering. I'd like to offer some reflections on a couple of them.

One of the first program decisions we made was to expand the conference from 3 days to 4.
This stemmed from two observations. 
First, last year's attendees were extremely enthusiastic about the introduction of tutorial and coding days.
Second, fitting all of the conference content into one day has created days with both too much content overall yet insufficient time for any individual submission. 
The solution was simple: keep two days for tutorial and demo sessions and spread the conference content over two days.
The outcome was positive: tutorials supporting different levels of expertise and conference days with enough time to absorb the material.

{{<pullquote>}}
All four changes were largely successful, both in terms of improving the conference experience and teaching important lessons about what makes ChapelCon a valuable community gathering.
{{</pullquote>}}

We also experimented with a change to the program for the tutorial/coding days.
Last year's schedule was a tutorial day comprising 2 self-contained, multi-hour tutorials on Chapel and Arkouda; then a separate coding day where participants could work on their own Chapel projects or on exercises provided by the organizers.
This was popular with the participants, with the caveat that the tutorials moved a bit too fast and lacked material for folks who already have some experience with Chapel.
This year, rather than dividing the days into one for tutorials and one for coding, we blended the tutorials and coding while making the first day more introductory and the second day more advanced.
Further, rather than running one long, self-contained tutorial, we broke the tutorial into pieces, focusing on individual skills a user needs to develop to use a programming language.
On the first (introductory) day, this included things like I/O and parallel loops. 
On the second (advanced) day, this included custom serialization, performance debugging, and parallel iterators.
Both days also included free-coding time where participants could work on tutorial exercises or their own code.
This was also a great success, and a favorite feature of many participants in the post-conference feedback survey.

Finally, a short note on some experiments with the review process. 
Like previous years, we used EasyChair to manage the submissions and reviewing. 
This year, we experimented with a more free-form review process, allowing program committee members to review any and all submissions they'd like.
While the free-form experiment was a nice change to the difficulties of bidding and assignment, it was not compatible with EasyChair, leading to technical difficulties and delays.
Next year, either the review process needs to revert to the more traditional bidding and assignment method or the platform needs to change. Luca, the Program Committee Chair, recommends [pretalx](https://pretalx.com/p/about/).


### Keynote Address and Invited Talks

With an extra conference day, we also had more time on the program to invite speakers from the HPC community, adding two invited talks to the traditional lineup of a keynote address and a [State of the Project talk](https://youtu.be/g937R7zXRGQ). 

The first invited talk, from Emanuele Vitali of CSC and Jorik van Kemenade of SURF, introduced us to the LUMI supercomputer and its support for Chapel. 
We learned about the international collaboration that developed the system, its technical configuration, and the user support offerings from the LUMI team. 
They closed it out with a demo of how to set up and use Chapel on the system. Check out the recording [here](https://youtu.be/5eZCzeObUBc).

[Our second invited talk](https://youtu.be/owj3cCVoc54) was from LLNL and HPSF's Todd Gamblin on Spack, the open-source HPC package management software. The talk, detailing Spack's path to version 1.0 was full of advice for open-source projects looking to expand their reach. 
With the perfect mix of technical and social focus, Gamblin's talk was an audience favorite. 

This year, our keynote address came from JuliaLab's Chris Rackauckas and told the story of the rise of scientific machine learning (SciML) in the Julia programming language. 
The main idea of SciML is to combine our scientific models with data sources, enabling efficiency and accuracy at levels unavailable to either source alone.
This is backed by the technical story of Julia's relentless focus on composability, combined with the non-technical focus on sustainable, open-source development.
Lessons for the Chapel community and inspiration for libraries and modules abound.
Check it out [here](https://youtu.be/5ornbvwZJp8).

### More Contributors Than Ever

This year's ChapelCon had a record-breaking 20 presentations from community members across two days.
The talks covered a wide range of topics, from machine learning and AI, to novel graph algorithms, to performance comparisons, and language interoperability. 
While there are too many for me to cover here (I encourage you to check them all out [on this YouTube playlist](https://www.youtube.com/playlist?list=PLuqM5RJ2KYFgTmbn3PmOocfu5Sh2wEcAb)), I'd like to bring attention to some that were especially enjoyed by the community.

One contribution that succinctly demonstrated Chapel's strengths in delivering both performance and productivity was [Mohammad Dindoost's talk on HiPerMotif](https://youtu.be/acvyLakS6gA).
HiPerMotif is a hybrid parallel algorithm for identifying subgraph "motifs" within large-scale property graphs. 
Implemented using Arachne (an Arkouda/Chapel-based graph library developed at NJIT), it provides up to 66x speedup compared to state-of-the-art methods, and processes graphs large enough to cause memory failures in other technologies. 

The second highlight came from Daniel Fedorin and demonstrates the expansive power of Chapel's type system. 
Using Chapel's compile-time `param` values and a bit of clever thinking, his approach makes it possible to encode complex data structures and specialized functions, all at compile time. 
This has wide-reaching implications, including eliminating runtime overhead and expanding compile-time error checking for functions like `printf`. 
Check out the recording [here](https://youtu.be/zfPo0TIzPhQ).

{{<pullquote>}}
This year's ChapelCon had a record-breaking 20 presentations from community members across two days.
{{</pullquote>}}

Third, from our PC chair Luca Ferranti, was a talk on [automatic differentiation in Chapel](https://youtu.be/ioqxdmSprBM).
Useful in domains including machine learning, scientific computing, and optimization, automatic differentiation computes derivatives without the numerical error of finite-difference or the complexity of symbolic differentiation. 
The `ForwardModeAD` library uses Chapel's operator overloading to support derivatives, gradients, jacobians, and more, all in a composable way.
The cherry on top? A Chapel integration for Enzyme, a library for automatic differentiation at the LLVM-level!

Finally, closing out the conference, was [Iain Moncrief's talk on his machine learning library ChAI](https://youtu.be/Y0YaLtZ-0lc).
ChAI offers a set of tools to support high- or low-level ML programming, defining/loading existing models, and distributed inference.
Integrated with PyTorch, ChAI supports developers at all levels, including those looking to load existing models as black boxes, build their own models entirely from scratch, or some combination of the two.
Iain ended the talk with a live demo of one of the examples using ChAI: live video style transfers. 

There's only room in this post to cover a few of the talks from ChapelCon this year, but I can't recommend strongly enough: [check out the rest](https://www.youtube.com/playlist?list=PLuqM5RJ2KYFgTmbn3PmOocfu5Sh2wEcAb)!

### Looking to the Future: ChapelCon '26 and Beyond

For those of you looking for ideas for next year's conference, the survey responses included some topics you might want to consider!
First, the community wants to see more work comparing Chapel's approach to parallelism with those used in relational databases.
Second, continuing a theme present in ChapelCon '25, the community is interested in seeing more work on language interoperability. 
Will 2026 be the year where we see Chapel interoperability with Rust, or even C++? 
We'll have to find out!
Finally, participants were interested in the possibility of using Chapel alongside quantum computing systems, combining traditional HPC programming models with emerging approaches for programming these boundary-expanding systems.
Whether you choose one of these topics, or another of your own, I'm excited to see all the exciting things folks put together for next year.

Thanks again to everyone who participated in ChapelCon this year. 
It was, as always, rewarding to see how the community is using Chapel to solve big problems. 
Until next year!
