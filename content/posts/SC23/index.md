---
title: "SC23 from the Chapel Language Perspective"
tags: ["SCxy Conference", "Trip Reports", "Community"]
summary: "A summary of highlights at SC23 relating to Chapel and Arkouda"
date: 2023-12-07
authors: ["Michelle Strout", "Engin Kayraklioglu"]
---

The year 2023 has been an exciting one for the Chapel programming
language community, and the Chapel/Arkouda presence at
[SC23](https://sc23.supercomputing.org/) was a good indication of that
excitement spreading amongst a growing user base.

The highlight at SC23 for our team was a pair of Chapel application
presentations by Tom Westerhout and Scott Bachman at [**PAW-ATM
2023**](https://sourceryinstitute.github.io/PAW/)&mdash;the 6th Annual
Parallel Applications Workshop, Alternatives to MPI:

* Tom Westerhout, a PhD student at Radboud University, presented his
  [`lattice-symmetries`](https://github.com/twesterhout/lattice-symmetries)
  package that leverages Chapel to simulate small quantum systems in
  [a paper](https://dl.acm.org/doi/10.1145/3624062.3624597)
  co-authored with [Brad Chamberlain]({{< relref "brad-chamberlain"
  >}}).  Tom reports:

  > Our implementation outperforms the state-of-the-art MPI-based
  > solution by a factor of 7&ndash;8 on 32 compute nodes, or 4096
  > cores, and scales well through 256 nodes, or 32,768 cores.

  He goes on to say that "the implementation has 3 times fewer
  software lines of code than the current state of the art, but is
  still able to handle generic Hamiltonians."  Tom indicated that his
  main motivation for using Chapel was that the main algorithm ended
  up being just seven lines of Chapel code.

* Scott Bachman, a scientist at NCAR and now
  [[C]Worthy](https://cworthy.org/), presented [_High-Performance
  Programming and Execution of a Coral Biodiversity Mapping Algorithm
  Using Chapel_](https://dl.acm.org/doi/10.1145/3624062.3624599)
  that he wrote in collaboration with five other
  co-authors including Ben Harshbarger, an engineer on the Chapel
  project at HPE.  Scott developed this application to analyze satellite
  images of coral reefs in about 3 months, and now people are publishing
  papers based on the data being produced by this program.  He talked
  about how he developed the program, how he evolved it to run on GPUs
  with some help from the Chapel GPU subteam, and how he used C
  interoperability to write out NetCDF files.

Both Tom and Scott said extremely positive things about how much they
enjoyed programming in Chapel.  Their talk slides are available from
the [PAW-ATM website](https://sourceryinstitute.github.io/PAW/).

Engin Kayraklioglu, leader
of the GPU subteam for the Chapel project at HPE, was a
co-organizer for PAW-ATM; and Michelle Strout, lead of the Chapel
project at HPE and associate professor of Computer Science at the
University of Arizona, led the panel at PAW-ATM titled _Charting Paths
to Success with Alternatives to MPI+X._

Some stories about Chapel and Arkouda resonated at SC23.  Folks were
quite impressed hearing that
[**Arkouda**](https://github.com/Bears-R-Us/arkouda) had been clocked
at nearly 9 TiB/s on 8K nodes doing a parallel radix sort in about 100
lines of Chapel code.  We talked with some people whose use cases
involved analyzing data from simulations that Arkouda could help with,
especially once Arkouda supports the [Python Array
API](https://data-apis.org/array-api/).  At both the [Sparse
Computation
workshop](https://sc23.conference-program.com/session/?sess=sess460)
and [Compiler Optimization
panel](https://sc23.conference-program.com/presentation/?id=pan131&sess=sess199)
on Friday, the need for **PGAS languages** to help with sparse and
graph computations was mentioned.  The idea of potentially having
Chapel code be a more succinct and understandable output from
AI-generated parallel, distributed code was also brought up.

Learning Chapel and helping others learn about Chapel was also a topic
at SC23.  Michelle Strout gave a one-hour **Chapel tutorial** on Sunday as
part of _Introduction to High-Performance Parallel Distributed
Computing Using Chapel, UPC++, and Coarray Fortran._  Jeremiah
Corrado, an engineer on the Chapel project at HPE, presented a Peachy
Assignment about writing parallel and distributed 1D heat diffusion in
Chapel as part of the [**EduHPC**](https://sc23.conference-program.com/session/?sess=sess454) workshop.
There were hallway discussions about a possible HPC for Data Science
course based on Arkouda/Chapel, a second semester Computer Science
course that introduces parallelism and data structures in Chapel, and
gathering Arkouda/Chapel course materials to help build a community of
Arkouda/Chapel instructors.  For slides and example codes from an
all-day Chapel tutorial given in October 2023, see the [Chapel
tutorials](https://chapel-lang.org/tutorials.html) page.  For an
Arkouda tutorial, check out the half-day tutorial, [_Interactive
Large-Scale Data and Graph
Analytics_](https://www.oliveralvaradorodriguez.net/talk/interactive-large-scale-data-and-graph-analytics/),
given by Oliver Alvarado Rodriguez et al. at PPoPP 2022.

Michelle, Engin, and Jeremiah really
enjoyed meeting people, learning about related technologies, and
sharing information about the Chapel programming language and the
Arkouda data analytics framework powered by Chapel at SC23.  One
opportunity to hang out in a more informal setting was a meeting of
the Chapel Users Group, [**CHUG**](https://chapel-lang.org/CHUG.html), where we took over a couple of tables at
Rhein Haus and chatted before going to the opening of the exhibits
floor at SC23.
The Chapel team at HPE looks forward to
participating in SC24 next year in Atlanta!
