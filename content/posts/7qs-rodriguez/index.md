---
title: "7 Questions for Oliver Alvarado Rodriguez: Exploiting Chapel's Distributed Arrays for Graph Analysis through Arachne"
richtitle: "7 Questions for Oliver Alvarado Rodriguez:<br>Exploiting Chapel's Distributed Arrays for Graph Analysis through Arachne"
date: 2026-01-21
tags: ["User Experiences", "Interviews", "Graph Analytics", "Arkouda", "Sparse Arrays"]
series: ["7 Questions for Chapel Users"]
summary: "An interview with Dr. Oliver Alvarado Rodriguez about his use
of Chapel in writing graph analytics computations"
authors: ["Engin Kayraklioglu", "Brad Chamberlain"]
interviewee_photo: "Oliver.jpg"
---

Welcome to the first interview in our [7 Questions for Chapel
Users]({{< relref "series/7-questions-for-chapel-users" >}}) interview
series for 2026!  In this edition, we hear from Dr. Oliver Alvarado
Rodriguez about his experiences using Chapel in his Ph.D. thesis to
write [Arachne](https://github.com/Bears-R-Us/arkouda-njit), a graph
analytics package for [Arkouda](https://arkouda-www.github.io/).  This
article is a logical successor to our [earlier interview with David
Bader]({{<relref 7qs-bader>}}), who served as Oliver's Ph.D. advisor.
After Oliver graduated, we were very happy to have the opportunity to
continue working with him within HPE's Advanced Programming Team that
Chapel is a part of.


#### 1. Who are you?

My name is Oliver Alvarado Rodriguez, and I am a software engineer at
Hewlett Packard Enterprise. I received my Ph.D. in Computer Science
from the New Jersey Institute of Technology in Newark, NJ. My
dissertation, _On the Design of a Framework for Large-Scale
Exploratory Graph Analytics_, focused on extending the Arkouda framework
to handle more complex and sparse problems such as graph
analysis. Rather than modifying Arkouda directly, we implemented an
add-on module called Arachne.

#### 2. What do you do? What problems are you trying to solve?

Since I started my Ph.D. in September 2020, and continuing into my
current role, I live and breathe graph data structures and
algorithms. The great thing about graphs is that anything modeled as
an interconnected network can be represented and analyzed with graph
algorithms. Once you’re comfortable with graph data structures and
algorithms, you’re well-equipped to tackle a wide range of problems in
computer science and related fields.

During my Ph.D., I focused on making graph analysis more accessible to
Arkouda users. At Hewlett Packard Enterprise, I’ve been improving
communication and performance for distributed graph patterns via
sparse matrices, and now I’m working on accelerating simulation
software by improving underlying distributed graph data structures as
well as building tools to facilitate hierarchical simulation models.

{{<pullquote>}}

Chapel’s biggest benefit for me is how quickly it lets me prototype
high-level parallel and distributed code, and then incrementally
optimize it.

{{</pullquote>}}


#### 3. How does Chapel help you with these problems?

Chapel’s biggest benefit for me is how quickly it lets me prototype
high-level parallel and distributed code, and then incrementally
optimize it. For graph algorithms, Chapel allows you to represent a
graph with built-in arrays and standard library containers in a single
line, for example: `var G: [0..<n] list(int)`. That gives you a
compact, high-level representation you can iterate over in parallel
with a simple `forall` loop. If you want a distributed graph and don’t
want to do special partitioning, you can make that array
block-distributed and still use the same `forall` loop; the
distribution is handled for you.

This rapid prototyping is invaluable for producing working
implementations and for onboarding people who are new to parallel
programming or graph algorithms. Once an algorithm is prototyped, you
can dig into optimizations. For instance, instead of an
array-of-lists, you can use Chapel’s standard library to represent the
graph as a sparse matrix and automatically apply CSR, CSC, or COO
layouts, giving you bespoke sparse graph representations essentially
out of the box.

#### 4. What initially drew you to Chapel?

Before Chapel, my experience with parallel programming was limited to
simple task and thread-based programs in C. I didn't know Chapel
existed—or much about OpenMP or MPI—until I began my Ph.D. I came to
NJIT intending to do network analysis, but I hadn’t expected the depth
of parallel and distributed programming involved.

Chapel made it easy to learn general parallel programming and to see
parallelism clearly without wrestling with the more verbose or
cumbersome syntax of OpenMP and MPI. That clarity helped me understand
how parallel and distributed codes work, and later made it much easier
to read and work with codes written in other parallel frameworks.


{{<pullquote>}}

Chapel helped me see how parallelism maps to real problems without
needing to first understand every detail of message passing, the
underlying runtime, etc.

{{</pullquote>}}

#### 5. What are your biggest successes that Chapel has helped achieve?

The code I developed for my dissertation was written entirely in
Chapel, and that is the biggest success Chapel helped me achieve. I
went from knowing little about parallel programming to becoming
comfortable both as a graph scientist and a parallel
programmer. Chapel let me learn parallel programming within the domain
I love, graphs, and that foundation makes it significantly easier to
understand and port ideas to OpenMP, MPI, or other frameworks. At the
end of the day, these tools are all about parallelizing operations,
and Chapel helped me see how parallelism maps to real problems without
needing to first understand every detail of message passing, the
underlying runtime, etc.

#### 6. If you could improve Chapel with a finger snap, what would you do?

I would add a general aggregation framework that lets users define
their own buffer-flushing functions and apply them to any distributed
data structure—even their own user-defined ones. Relatedly, I’d like
to see a wider variety of distributed data structures in the
standard library that can be used with custom aggregators for moving
data into and out of them.

#### 7. Anything else you'd like people to know?

Chapel is awesome, and it’s created by some of the most helpful,
friendly, and passionate people I’ve ever met. I was fortunate to
intern with the Chapel team in the summer of 2024 and work with them
when I joined Hewlett Packard Enterprise. Those experiences rank among
the best in my career. Even though I’m no longer directly on the
Chapel team, I still lurk in the communication channels and learn
something new almost every day. It takes a truly dedicated team to
build a language packed with features like Chapel's. After all, what
other language has dedicated, parallel, distributed sparse matrix data
structures with all your favorite layouts? (I’ll wait).

---

We’d like to thank Oliver for participating in this [7 Questions for
Chapel Users]({{< relref "series/7-questions-for-chapel-users" >}})
interview.  Stay tuned for future installments of the series!
