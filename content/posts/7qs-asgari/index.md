---
title: "7 Questions for Marjan Asgari: Optimizing Hydrological Models with Chapel"
date: 2025-09-15
tags: ["User Experiences", "Interviews", "Hydrology"]
series: ["7 Questions for Chapel Users"]
summary: "An interview with Dr. Marjan Asgari about her use
of Chapel for hydrological research"
authors: ["Engin Kayraklioglu", "Brad Chamberlain"]
interviewee_photo: "asgari.jpg"
---

Welcome to the [7 Questions for Chapel Users]({{< relref
"series/7-questions-for-chapel-users" >}}) series! In this edition, we
welcome Dr. Marjan Asgari. As an expert in computational hydrology,
Marjan used Chapel to improve hydrological models as part of her
Ph.D. at University of Guelph. Read on to learn more about her journey
using Chapel!

### 1. Who are you?

My name is Dr. Marjan Asgari, and I am a Physical Scientist at Natural Resources
Canada, Government of Canada. My primary expertise lies in the parallelization
of large-scale geospatial tasks and working with extensive geospatial datasets.
I regularly work with HPC clusters and enjoy tackling projects that face
challenges with execution speed and memory exhaustion, applying "parallelization
magic" to optimize them.

{{% pullquote %}}
It is important to choose approaches that are not only easy to implement, but
also easy for scientists—whose focus is not on computer science—to understand.
{{% /pullquote %}}

### 2. What do you do? What problems are you trying to solve?

My main role involves solving computational and memory-related issues in
geoscience, particularly when using machine learning models for large satellite
datasets. When dealing with large datasets and complex tasks, the need to
transition to novel computational approaches becomes evident. However, it is
equally important to choose approaches that are not only easy to implement, but
also easy for scientists—whose focus is not on computer science—to understand.
So, constantly researching for novel approaches in parallel computing and
implementing them for geoscience projects is my daily job.


### 3. How does Chapel help you with these problems?

I think the most important feature of Chapel is its ease of use. Parallelization
is not an easy task to accomplish; the whole concept of how to parallelize your
work efficiently is complex enough. Coding this concept in a language that is
difficult to use only adds to the challenge and discourages scientists from
giving it a try. Chapel makes coding engaging and increases curiosity about how
to enhance parallelization in your code. I have only run Chapel on a multi-node
cluster with CPU-based compute nodes, but with the increasing popularity of deep
learning models in my field, I believe the next step for me will be GPU
processing.

{{% pullquote %}}
Chapel makes coding engaging and increases curiosity about how to enhance
parallelization in your code.
{{% /pullquote %}}

### 4. What initially drew you to Chapel?

Before working with Chapel, I was using parallel computing frameworks like Spark
and Hadoop. The challenge of simply setting up a distributed system and
scheduling tasks among parallel workers was immense. Then, I started researching
other possible ways of doing parallel computing. I came across Chapel, ran a
coforall loop, gathered all the results outside the loop, and I thought, "Wow,
this is it!".

### 5. What are your biggest successes that Chapel has helped achieve?

My Ph.D. dissertation represents a significant success. I was able to develop a
method for the optimization of hydrological models using Chapel. There were no
publications on the use of PGAS (Partitioned Global Address Space) models in the
calibration of hydrological models, and Chapel enabled me to contribute to this
field with my work.


### 6. If you could improve Chapel with a finger snap, what would you do?

I really wish the installation of Chapel on HPC systems were easier and more
straightforward. Relying heavily on SSH as the start-up method can be
insufficient, as many HPC systems don't permit SSH between compute nodes.  I
put in a lot of effort to {{% sidenote right "install Chapel on the HPC systems" -10 %}}
After Marjan completed this work, we developed a <a
href="https://chapel-lang.org/docs/main/usingchapel/QUICKSTART.html#building-from-source-via-spack">Spack
package for Chapel</a>, which should significantly simplify the process of
installing Chapel on HPC systems.  Sorry we didn't have it at that time, Marjan!
{{% /sidenote %}} we had, but unfortunately, it didn’t work in the end.

Another item on my wish list is that Chapel would support geospatial data. If
Chapel could work with data structures {{% sidenote right "like NumPy arrays or XArrays" %}}
Chapel doesn't natively support NumPy arrays or XArrays. However,
<a href="https://arkouda-www.github.io/">Arkouda</a> does!  We recommend
checking Arkouda out if you are interested in a NumPy-like interface for big
datasets, including <a href="youtube.com/watch?v=v8p0T-RJTCU&embeds_referring_euri=https%3A%2F%2Fdiscourse.pangeo.io%2F&source_ve_path=Mjg2NjY">multi-dimensional ones</a>.

{{% /sidenote %}}
, it would be
a game-changer. In the field of Geomatics, there is immense potential for using
parallel computing with languages like Chapel, which are not difficult for
Python programmers to learn. The lack of spatial data support is a significant
limitation in this regard.

### 7. Anything else you'd like people to know?

As a scientist working in the field of parallel computing, Chapel has amazed me
several times. The only thing I hope for is that the items on my wish list in
question 6 come true at some point. If that happens, I believe working with
Chapel will be a blast every day.


---

We’d like to thank Marjan Asgari for participating in the [7 Questions
for Chapel Users]({{< relref "series/7-questions-for-chapel-users"
>}}) series. If you have any questions for Marjan, or comments, please
direct them to the [discussion
thread](https://chapel.discourse.group/t/7-questions-for-chapel-users-series-questions-comments/37200)
for this series on Discourse.
