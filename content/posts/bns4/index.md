---
title: "Navier-Stokes in Chapel — Distributed Cavity-Flow Solver"
tags: ["Math", "Differential Equations", "How-to", "Computational Fluid Dynamics", "Language Comparison"]
series: ["Navier-Stokes in Chapel"]
authors: ["Jeremiah Corrado"]
summary: "Writing a distributed and parallel Navier-Stokes solver in Chapel, with an MPI performance comparison"
date: 2024-11-14
featured: True
weight: 1
---

This article is a direct continuation of [Part 3]({{< relref "bns3" >}}) in this series, where we discussed several aspects of Chapel's distributed programming capabilities, and used those to create a distributed version of the code from [Part 2]({{< relref bns2 >}}). If you haven't already, you may want to read the previous article before continuing.

Here, we'll use those distributed-programming features to port one of the full Navier-Stokes simulation codes from the Barba Group's [12 steps to Navier-Stokes](https://lorenabarba.com/blog/cfd-python-12-steps-to-navier-stokes/) tutorial to Chapel, allowing us to efficiently run simulations on any hardware ranging from a laptop to a supercomputer. And by comparing with a version written with C++, MPI, and OpenMP, we'll see that the Chapel code, which is only slightly longer than the original Python code, is able to match the performance of the industry-standard HPC software stack.

### Distributed Cavity-Flow Simulation Code

[Step 11](https://nbviewer.org/github/barbagroup/CFDPython/blob/master/lessons/14_Step_11.ipynb) of the Tutorial discusses Cavity flow. This kind of Navier-Stokes simulation shows how a fluid moves and evolves in a closed cavity (a rectangle in our case) given some boundary conditions. Each step of our simulation will compute a momentum vector for all of the finite difference points in our 2D grid (this is a composition of the `u` and `v` arrays discussed below). It also uses the Poisson Solver to compute the fluid's pressure, `p`, at each finite difference point. Both quantities will be rendered in the final solution plot.

The full Navier-Stokes code follows a very similar structure to the Poisson code from the previous articles, and only takes a few deviations from Step 11 of the tutorial. As such, I'll give a high-level summary of the code that only calls out the areas where those differences pop up, rather than going through it line-by-line.

#### Simulation Constants and Settings

There are now two time-step constants `nt` and `nit`, where the Poisson solver only had one. The first corresponds to actual time, and the second is the number of iterations to use for solving the Poisson equation during each time step (we also could have used the tolerance-based approach from the previous articles, but a constant number of iterations is used here for simplicity and to follow the Python tutorial more closely). This means that for every real time step, the program will run 50 Poisson iterations by default.

{{< subfile fname="nsStep11.chpl" lang="chapel" lstart=6 lstop=14 section="first" >}}

There is also a new `downSampleFactor` constant (not included in the Python tutorial) that tells the plotting code which fraction of array elements to use in the final plot. The default of `2` means that 1/2 of the indices along each axis are used to generate the figure (i.e., 1/4 of the indices are included in the plots). For realistically large data sizes, this value should be increased to avoid generating very large plots and data files.

{{< subfile fname="nsStep11.chpl" lang="chapel" lstart=20 lstop=21 section="middle" >}}

#### Domain Distribution

Instead of defining the `space` domain over the `Locales` array directly, as we did in the distributed Poisson solver, we use a 2D version of `Locales` that has a shape of `(Locales.size, 1)`. This indicates to the distribution that we only want to distribute blocks along the first dimension. For a small number of locales, this will give us better performance because each locale only has to communicate with two neighbors instead of four.

{{< details summary="What about for larger numbers of locales?">}}

For problem sizes and locale counts that are larger than what we'll discuss in this article, using the default 2D distribution makes more sense because it avoids high surface-area-to-volume ratios on each locale's block (i.e., with many locales, the blocks would be very long and skinny rectangles). In that case, each locale would spend a sub-optimally large portion of its time communicating with neighbors instead of running stencil computations, which would result in reduced overall performance.

{{</ details >}}

</br>

{{< subfile fname="nsStep11.chpl" lang="chapel" lstart=24 lstop=26 section="middle" >}}

#### Arrays & Boundary Conditions

We now have three distributed arrays: `p`, `u`, and `v` defined over `space`, representing pressure, x-directed momentum, and y-directed momentum respectively.

The boundary conditions are modified such that there is a rightward flow on the top of the domain (like in the tutorial), and also a leftward flow on the bottom of the domain (instead of the Dirichlet condition). This deviation from the tutorial isn't particularly important, but results in an interesting final solution.

{{< subfile fname="nsStep11.chpl" lang="chapel" lstart=29 lstop=34 section="middle" >}}

#### Halo Updates

As with the distributed Poisson solver, calls to `updateFluff` are included before each array is used in a stencil computation. This ensures that the "halo" regions in the arrays have the latest data from their neighboring locales:

{{< subfile fname="nsStep11.chpl" lang="chapel" lstart=59 lstop=80 section="last" >}}

#### The Full Code

The remainder of the code includes some familiar infrastructure and some new stencil computations which are pretty mathematically intensive: `computeB`, `computeU`, and `computeV`. This article won't get into the details of the math; however, the original Python tutorial is an excellent resource for understanding what those computations are doing.

The full Chapel code can be viewed/downloaded here:

{{< file_download_min fname="nsStep11.chpl" lang="chapel" >}}

The following scripts are used for generating plots (enabled with the `--createPlots=true` command line argument). Note that your Python environment must have Numpy and Matplotlib installed for plotting to work.

{{< file_download_min fname="FlowPlot.chpl" lang="chapel" >}}
{{< file_download_min fname="flowPlot.py" lang="python" >}}

### Compiling and Running

With the above files downloaded into the same directory, the following commands will compile the program and execute it on four locales:

```console
chpl nsStep11.chpl --fast
./nsStep11 -nl 4 --createPlots=true
```

A figure named `Solution.png` should appear in the same directory:

{{< figure src="cavity-flow-solution.png" title="Cavity Flow Solution" width=1000 >}}

The opposing boundary conditions on the top and bottom of the domain create an hourglass-shaped flow through the cavity. Modifying the boundary conditions and other simulation parameters can result in very different looking solutions.

The program also prints the mean value of `p`, and the running time for the `solveCavityFlow` procedure. Note that if you are emulating multiple locales on a single computer, peak performance should not be expected. To see performance advantages from distribution, the code should be run with a large problem size across multiple nodes of a cluster or supercomputer. Also note that Chapel 2.2 includes some {{< sidenote "right" "performance optimizations" >}} As of 2.2, the Chapel compiler and library work together to analyze parallel loops that access stencil-distributed arrays. If the accesses are known to be local ahead of time (i.e., they are within that locale's region of the array, or its halo buffers), then a fast path is used that does not check for locality before accessing memory. There were also improvements to the stencil distribution itself to reduce communication overhead, as well as improvements to Chapel's array slicing expressions that reduced overhead in this code's boundary-condition computation. See the [2.2 Release Announcement]({{< relref "announcing-chapel-2.2#stencil-optimizations" >}}) for more information. {{</ sidenote >}} related to the Stencil Distribution, so using version 2.2 or later is recommended for running this code.

### Comparison with C++/MPI/OpenMP

The C++/MPI/OpenMP {{< sidenote "left" "counterparts" >}}
Caveat: I am not an expert with C++/OpenMP/MPI, so there are certainly places where the performance, and perhaps readability, of the C++ code could be improved; however, the purpose of this exercise is to show how a straightforward Chapel implementation compares to a straightforward C++/OpenMP/MPI implementation without pulling out all the stops for either technology.
{{</ sidenote >}}
to the Chapel code can be viewed and downloaded here:

{{< file_download_min fname="nsStep11.cpp" lang="c++" >}}
{{< file_download_min fname="nsStep11.h" lang="c++" >}}

And the other files needed to build and run the C++ code are here:

{{< file_download_min fname="utils.cpp" lang="c++" >}}
{{< file_download_min fname="utils.h" lang="c++" >}}
{{< file_download_min fname="CMakeLists.txt" lang="cmake" >}}

As with our [comparison]({{< relref "bns2#performance-comparison-with-copenmp" >}}) between the non-distributed Poisson solver and its corresponding C++ code, this code is noticeably more verbose than the Chapel version. It weighs in at 280 source lines of code, whereas the Chapel version has only 120 source lines (plotting utilities included). Importantly, the Chapel version also allows for easy modification of the 2D distribution, while major updates would be required to make the arrays distributed across both dimensions in the C++ code.

A particularly striking example of the difference in succinctness is the section used for printing the mean value of the pressure array after the simulation.  I include this as a sanity check and to validate the correctness of both codes against the original Python version. The following line of Chapel code:

{{< subfile fname="nsStep11.chpl" lang="chapel" lstart=47 lstop=47 >}}

corresponds to this block of C++ code:

{{< subfile fname="nsStep11.cpp" lang="c++" lstart=124 lstop=141 >}}

Chapel is benefiting from several things here:
* the `+ reduce` operator makes use of `p`'s distribution to execute an efficient distributed and parallel sum-reduction behind the scenes
* the array is a single cohesive object (rather than a collection of small arrays allocated by each MPI process), so we can do operations like `+ reduce` on the full array
* Chapel's global execution model (where the program starts on locale 0) removes the need for checks like `if (rank == 0)`

### Performance Experiment Setup and Results

Code clarity aside, let's see how Chapel stacks up against C++ in terms of performance. The following experiments were run on a Cray XC system with the default number of iterations (`500` and `50`) and a variety of problem sizes. To keep the simulation numerically stable, the ratio of physical length per finite-difference point was held constant at 20 points per unit length.

{{< details summary="system/software specs and environment..." >}}

**Cray XC Supercomputer**:
* 48 core Intel Xeon 8160 CPU (96 threads)
* 192 GB memory per node
* Aries network

**Chapel**: version 2.2

<details>

<summary>Chapel environment...</summary>

    CHPL_TARGET_PLATFORM: cray-xc
    CHPL_TARGET_COMPILER: llvm
    CHPL_TARGET_ARCH: x86_64
    CHPL_TARGET_CPU: x86-cascadelake
    CHPL_LOCALE_MODEL: flat
    CHPL_COMM: ugni
    CHPL_TASKS: qthreads
    CHPL_LAUNCHER: slurm-srun *
    CHPL_TIMERS: generic
    CHPL_UNWIND: none
    CHPL_MEM: jemalloc
    CHPL_ATOMICS: cstdlib
    CHPL_NETWORK_ATOMICS: ugni
    CHPL_GMP: bundled
    CHPL_HWLOC: bundled
    CHPL_RE2: bundled
    CHPL_LLVM: system *  (version 14)
    CHPL_AUX_FILESYS: none

</details>

**MPI**: OpenMPI version 3.1

**OpenMP**: version 4.5

    OMP_NUM_THREADS=96
    OMP_PROC_BIND=true

**GCC**: version 12.1

{{</ details >}}

First, looking at strong-scaling, we test the running time of both programs with a range of node counts on two grid sizes: $4096 \times 4096$ and $8192 \times 8192$. Times in this plot show the average of three runs:

{{< figure src="strong-scaling.png" >}}

Strong-scaling plots like this one essentially show how much faster you can get a simulation of a particular size to run by throwing more compute resources at it. For both languages, similar speedup characteristics are achieved. For the larger problem size, Chapel comes out {{< sidenote "right" "ahead" >}} The difference in overall performance could be attributed to the difference in memory allocation strategy for the arrays across the two programs. Chapel's distributed multidimensional arrays lay out each locale's block of data in a contiguous region in memory (on that locale), whereas the strategy used to create 2D arrays in the C++ code (nested vectors) can allocate each of the inner vectors in its own region on the heap, not necessarily contiguous with the others. This can lead to poorer cache performance (i.e., more misses) when accessing the  arrays. {{</ sidenote >}} in terms of overall performance, while C++ is slightly ahead for most node counts with the smaller problem size.

Next, keeping the total number of finite-difference points per compute node constant, we have the following weak-scaling results:

{{< figure src="weak-scaling.png" >}}

Two problem sizes are shown: $1024^2$ elements per node and $2048^2$ elements per node. The weak-scaling analysis gives an indication of how efficiently one can take a small simulation — perhaps one that would run easily on a single compute node — and scale it up to take advantage of more compute resources. For both programming models, the smaller problem size scales quite linearly up to 16 nodes where C++ is ahead in terms of overall performance. For the larger problem size, the scaling is less consistent and performance is generally neck and neck between the two models, except at 16 nodes where Chapel comes out ahead.

### Conclusion

Chapel's powerful distributed programming features allowed us to write a concise distributed and parallel 2D Navier-Stokes cavity flow solver that runs efficiently on a supercomputer. The program was developed and tested using a small problem size on a laptop, and then scaled up to run across many nodes without making code changes. Additionally, the vast majority of the code was written without needing to consider any of the technical details of distribution or parallelization apart from the use of the stencil distribution and its update calls. Through the above performance comparison, we saw that Chapel was able to match the performance of an industry-standard software stack for doing distributed scientific simulations. Not only that, but the Chapel code was about half the length, and arguably much more readable.

The Chapel Team would like to express its sincere gratitude towards the [Barba Group](https://lorenabarba.com/) for creating and maintaining the CFD Python tutorials.
