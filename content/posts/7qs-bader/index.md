---
title: "7 Questions for David Bader: Graph Analytics at Scale with Arkouda and
Chapel"
date: 2024-11-06
tags: ["User Experiences", "Interviews", "Graph Analytics", "Arkouda"]
series: ["7 Questions for Chapel Users"]
summary: "An interview with Computer Science Professor David Bader about his use
of Arkouda for graph analytics"
authors: ["Engin Kayraklioglu", "Brad Chamberlain"]
interviewee_photo: "bader.jpg"
---

In this installment of our [7 Questions for Chapel
Users]({{< relref "series/7-questions-for-chapel-users" >}})
series, we welcome [David Bader](https://davidbader.net/), a Distinguished
Professor in the [Ying Wu College of Computing](https://computing.njit.edu/) at
the New Jersey Institute of Technology (NJIT). With a deep focus on
high-performance computing and data science, David has consistently driven
innovation in solving some of the most complex and large-scale computational
problems. Read on to dive into his journey with Chapel, his current projects,
and how tools like [Arkouda](https://arkouda-www.github.io/) and
[Arachne](https://github.com/Bears-R-Us/arkouda-njit/blob/main/README.md) are
accelerating data science at scale.


### 1. Who are you?

I am David Bader, currently serving as the Director of the Institute for Data
Science at NJIT. My expertise lies in scalable data analytics and parallel
computing, where I focus on addressing large-scale data challenges that impact
our daily lives, such as social network analysis, cybersecurity, and
bioinformatics. I have led the team that has developed Arachne, an Arkouda
package that extends its interactive data exploration capabilities to also
handle complex graph analytics through scalable algorithms. Over the years, I
have collaborated with teams across academia, government, and industry to
develop solutions that push the boundaries of computing.

### 2. What do you do? What problems are you trying to solve?

My work revolves around developing efficient algorithms and frameworks for
processing and analyzing massive datasets. The challenges I tackle often have
broad societal impact, such as improving our understanding of disease pathways,
detecting cyber threats in real time, and optimizing infrastructure networks.
Many of these problems require harnessing the power of modern supercomputers and
parallel architectures to deliver solutions at unprecedented scales and speeds.

<!--The challenges I tackle often have-->
<!--broad societal impact, such as improving our understanding of disease pathways,-->
<!--detecting cyber threats in real time, and optimizing infrastructure networks.-->

{{% pullquote %}}
Arachne helps us execute complex graph analytics on dynamic datasets with
extreme scalability and performance. 
{{% /pullquote %}}

With frameworks like Arkouda, we are able to provide data scientists the ability
to work interactively on large datasets with the simplicity of Python, but at
the performance levels of HPC systems. Similarly, Arachne helps us execute
complex graph analytics on dynamic datasets with extreme scalability and
performance. These tools are essential for translating cutting-edge research
into real-world applications.


### 3. How does Chapel help you with these problems?


Chapel provides a unique advantage by allowing its users to express parallelism
and locality in a more intuitive manner compared to traditional parallel
programming languages like MPI or OpenMP. It offers a modern programming model
that is both high-level and highly performant, making it easier to develop and
maintain complex data analytics applications. We run Chapel on a variety of
systems, from local clusters to national-scale supercomputers, and its
flexibility and scalability have been invaluable in bridging the gap between
research prototypes and real-world deployments.

{{% pullquote %}}
Students in my group, without prior experience in parallel programming, were
able to write and implement scalable graph algorithms in Chapel within just a
few weeks.
{{% /pullquote %}}

Arkouda’s Chapel-powered backend supports scalable and interactive processing of
dataframes with millions of elements, giving data scientists the power to
analyze data interactively without worrying about the complexity of parallel
processing. For Arachne, Chapel allows us to efficiently manage large graph
structures and parallelize analytics workloads, which is crucial when working
with massive social networks or biological interaction networks.

{{< figure src="neuro.png" class="fullwide"
    caption="Two implementations of subgraph isomorphism in Arachne perform 97x better than NetworkX and DotMotif, commonly used in neuroscience workflows for motif matching in graphs."
>}}

In addition to Chapel's strengths in parallelism and locality, it has proven to
be highly accessible for new users. For instance, students in my group, without
prior experience in parallel programming, were able to write and implement
scalable graph algorithms in Chapel within just a few weeks. This intuitive
learning curve allowed them to quickly contribute to Arachne’s graph analytics,
demonstrating how Chapel can be leveraged to rapidly develop solutions even by
those new to parallel programming and HPC.

### 4. What initially drew you to Chapel?

I first learned about Chapel decades ago as an investigator in the DARPA High
Productivity Computing Systems (HPCS) program. At the time, I was drawn to its
potential for transforming productivity in parallel computing, making it
feasible to tackle challenging problems at scale. What stood out to me was how
Chapel abstracted away the low-level details of parallel programming while
retaining the performance characteristics necessary for high-end computing.
Chapel’s promise to improve productivity and facilitate high-performance
application development made it a compelling choice for our research projects.

### 5. What are your biggest successes that Chapel has helped achieve?

Using Chapel, we’ve been able to implement parallel algorithms for graph
analytics that scale efficiently across thousands of cores. One of Chapel’s most
impactful successes has been the development of Arkouda, a tool that allows data
scientists to manipulate large datasets interactively and perform exploratory
data analysis at unprecedented scales. This wouldn’t have been possible without
Chapel’s robust parallel programming capabilities.

{{% pullquote %}}
With Arachne, we’ve successfully demonstrated how complex graph problems can be
tackled using Chapel, providing solutions that are not only scalable but also
highly efficient in real-world scenarios.
{{% /pullquote %}}

With Arachne, the Arkouda package we design and develop here at NJIT, we’ve
successfully demonstrated how complex graph problems can be tackled using Chapel
to process dynamic and irregular data structures, providing solutions that are
not only scalable but also highly efficient in real-world scenarios. These tools
have helped us advance the field of data science by providing new avenues for
scalable data processing and analytics.

{{< figure src="bfs.png" class="fullwide"
    caption="Arachne shows strong scalability on two different types of systems for distributed-memory (multilocale) breadth-first search."
>}}



### 6. If you could improve Chapel with a finger snap, what would you do?

I’d focus on enhancing Chapel’s integration with existing machine learning and
data science libraries, particularly those in Python. Seamlessly combining
Chapel’s parallelism with the extensive ecosystem of data science tools would
significantly broaden its applicability and reduce the friction for users
transitioning between traditional and parallel environments. For frameworks like
Arkouda and Arachne, tighter integration with Python would make it even easier
for data scientists to leverage the power of Chapel in their existing workflows.

### 7. Anything else you'd like people to know?

{{% pullquote %}}
I’m excited about the growing intersections between data science, graph
analytics, and real-world applications. And I believe that languages like
Chapel will play a pivotal role in shaping the future of computational
research.
{{% /pullquote %}}

I encourage researchers and developers interested in high-performance data
analytics to explore Chapel. Its modern approach to parallel computing makes it
a valuable tool for tackling today’s data challenges. As for my own work, I’m
excited about the growing intersections between data science, graph analytics,
and real-world applications. And I believe that languages like Chapel will play
a pivotal role in shaping the future of computational research.

Frameworks like Arkouda and Arachne demonstrate how Chapel can serve as a
powerful foundation for building scalable, high-performance tools. Whether
you’re dealing with massive dataframes or complex graph structures, Chapel’s
expressive parallelism and scalability can be a game-changer.


---

We’d like to thank David Bader for participating in the 7 Questions for Chapel
Users series. To learn more about David's team's work, make sure to check out
[his website](https://davidbader.net/). David's work showcases how powerful and
flexible modern parallel programming languages like Chapel can be for addressing
large-scale data challenges. With tools like Arkouda and Arachne, he continues
to push the boundaries of data science and parallel computing. We look forward
to seeing how his work evolves and inspires the next generation of computational
breakthroughs!

If you have any questions for David, or comments, please direct them to the [7
Questions for Chapel
Users](https://chapel.discourse.group/t/7-questions-for-chapel-users-series-questions-comments/37200)
thread on Discourse.
