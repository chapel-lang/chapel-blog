---
title: "Navier-Stokes in Chapel — Distributed Poisson Solver"
tags: ["Math", "Differential Equations", "How-to", "Computational Fluid Dynamics"]
series: ["Navier-Stokes in Chapel"]
authors: ["Jeremiah Corrado"]
summary: "Introduction to Chapel's distributed programming concepts used in Navier-Stokes Simulation"
date: 2024-10-28
---

This is the third article in a series that's been leading up to implementing a 2D Navier-Stokes simulation in Chapel. So far, we've ported a couple of the Python codes from the [12 steps to Navier-Stokes](https://lorenabarba.com/blog/cfd-python-12-steps-to-navier-stokes/) tutorial to demonstrate Chapel's productivity and performance for scientific computing. Several features and concepts were covered in the process; however, we haven't yet gone over one of the things that makes Chapel especially unique among other programming tools---namely, its distributed programming capabilities.

This article will cover a series of topics that will inform our implementation of a distributed and parallel Navier-Stokes solver:

1. Locality and Locales
2. Distributed Domains and Arrays
3. Compiling and Executing Multi-Locale Programs
4. Using the Stencil Distribution to Minimize Inter-Locale Communication

To demonstrate the above concepts in action, we'll modify the Poisson solver from the [previous article]({{< relref bns2 >}}) to run across multiple compute nodes. In the next and final article in this series, we'll expand on the distributed Poisson solver to write a full Navier-Stokes solver in Chapel, and compare its performance to an equivalent program written in C++, MPI, and OpenMP.

### Locality and Locales

Programs that run on a single computer only need to worry about a single pool of memory, which is accessible from each CPU core with a bandwidth and latency that is {{< sidenote "right" "more-or-less equivalent" >}} Cores within a particular NUMA-domain on the CPU have relatively slower access to memory pages that belong to other NUMA domains. This is particularly true for modern high-core-count processors that feature a chiplet architecture. However, over-network memory speeds are still much slower than a local memory access with a NUMA penalty. {{</ sidenote >}}. In contrast, distributed-memory programs must consider the separate pools of memory on each of the computers they are running on, as well as the fact that the CPU cores local to a particular memory pool have much faster access to it than the CPU cores located on other computers. This is because accessing non-local memory requires sending messages over a network to retrieve/deposit data. Chapel's model for distributed programming has two fundamental features that give the programmer control over where memory is allocated and where computations are run (i.e., which computer's memory and which computer's CPU). Those are the `locale` type and the `on`-statement, respectively.

A [locale](https://chapel-lang.org/docs/primers/locales.html#locales) is an abstraction for any unit of hardware that has memory and compute resources. In {{< sidenote "left" "most cases" >}} It is possible to run a distributed Chapel program with multiple locales per compute node using a feature called [co-locales](https://chapel-lang.org/docs/usingchapel/multilocale.html#co-locales). This can be useful for optimizing things like NUMA affinity or NIC usage. Additionally, the locale type is used to represent GPU hardware using a concept called sub-locales. See the articles on [GPU programming]({{< relref "series/gpu-programming-in-chapel/" >}}) for more. For the purpose of this article, assume that each locale represents a single compute node. {{</ sidenote >}}, the locale type is used to represent a single compute node in a cluster or supercomputer. Chapel programs have a globally accessible array of `locale` values, named `Locales`, which contains one entry for each of the compute nodes allocated to the program when it's launched. This array gives the program an abstract view of the hardware resources available to it.

Programs begin execution on the first locale, meaning memory allocations and computations will occur on that compute node to start. From there, they can use [`on` statements](https://chapel-lang.org/docs/language/spec/locales.html#the-on-statement) to move program execution and memory allocation to one or more of the other locales. Additionally, Chapel's global namespace model allows for implicit communication across locale boundaries (where SPMD models like MPI require explicit communication). In other words, if a variable is within lexical scope, then it's accessible regardless of which locale it's allocated on. Chapel's compiler and runtime will automatically handle network communication as needed.

For example, the following program allocates a variable `x` on locale 0, moves execution to locale&nbsp;1 to allocate another variable `y`, and then prints their sum. At each step, `here`, an alias for the locale currently executing the code, is used to print out the locale's `id` (equivalent to its 0-based index in `Locales`).

```chapel
var x = 5;
writeln("x = ", x, " (on loc ", here.id, ")");
on Locales[1] {
    var y = 2;
    writeln("y = ", y, " (on loc ", here.id, ")");
    writeln("x + y = ", x + y);
}
```
This will print:
```console
x = 5 (on loc 0)
y = 2 (on loc 1)
x + y = 7
```

By composing these features with Chapel's various parallel programming features, one can write parallel and distributed applications that have very fine control over where data are allocated and where computations run. In this article, we'll use a higher-level abstraction provided by Chapel's standard library — implemented in terms of the lower-level features — that will handle many of the details involved in distributing data and computations for us.

### Distributed Domains and Arrays

Chapel's distributions specify patterns used to distribute domain and array indices across the memories of multiple locales. As a reminder, a Chapel `domain` represents a set of indices that can be iterated over and used to define arrays. Distributed domains have iterators that handle disseminating computations across multiple cores on multiple locales in parallel. As such, the kinds of data-parallel loops we've discussed in this series so far (the `forall` loops) can become distributed data-parallel loops simply by modifying how the arrays are defined — the array distribution and its {{< sidenote "right" "parallel iterator" >}} Importantly, these iterators are not "magical." They are implemented in Chapel using the on-clauses, discussed above, and other related features provided by the language. This means that Chapel users can define their own distributed and parallel iterators using those same features. {{</ sidenote >}} will handle the rest.

To provide some background, in previous articles we've discussed domain and array declarations that look something like this:

```chapel
const dom = {1..8, 1..8};
var A: [dom] int = 1;
```

Here, `A` is a 2D array defined over the indices $[1, 8]$ along both axes. Its elements are `int` values, all of which get initialized to `1`. Note that there is nothing in this code to indicate that `A` should take advantage of multiple locales, so all its elements will be allocated on whichever locale runs the code.

To distribute an array's elements across multiple compute nodes, we can define the array over a distributed domain. Chapel's standard library has multiple distributions; for now, let's focus on `blockDist`, which will distribute one rectangular block of contiguous indices to each locale, creating a grid-like distribution where each block is as equally-sized as possible.

This distribution pattern is optimal for our finite-difference application (as opposed to something like a cyclic distribution) because it maximizes the number of array elements that are grouped together in memory, minimizing the amount of inter-locale communication needed to apply stencil operations. To create a block-distributed domain over a given set of indices, `blockDist` has a [`createDomain`](https://chapel-lang.org/docs/modules/dists/BlockDist.html#BlockDist.blockDist.createDomain) type-method that takes a non-distributed domain and returns a block-distributed domain over the same set of indices:

{{< subfile fname="datapar-example.chpl" lang="chapel" lstart=1 lstop=4 section="first" >}}

Here, `A` will be distributed across the program's entire `Locales` array, meaning that each locale will have one block of `A`'s values in memory. Note that `Locales` is the default value for the `targetLocales` argument so it doesn't need to be specified explicitly here; however, doing so can be beneficial for clarity.

We can then iterate over `A` with a data-parallel `forall` loop. This invokes `blockDist`'s parallel iterator that will launch a task on each locale in parallel. Each of those tasks will typically launch one task per core on their respective compute nodes, each of which executes the body of the loop for a subset of array elements in that locale's memory:

{{< subfile fname="datapar-example.chpl" lang="chapel" lstart=6 lstop=9 section="last" >}}

In this case, we set each value to the `id` of the locale where it's stored (the `.locale` query returns the locale where a value is allocated). Printing `A` will give us a picture of how it's laid out in memory across locales. Now let's talk about how to compile and run distributed programs so we can see what the output looks like.

### Compiling and Executing Multi-Locale Programs

A nice aspect of writing distributed programs in Chapel is that a single computer can be used to emulate multiple locales during development. This allows programmers to develop and debug a massive-scale program on their laptop with a smaller problem size, and then seamlessly launch the program on a supercomputer using the real problem size without making any changes to the code. See [these docs](https://chapel-lang.org/docs/usingchapel/multilocale.html) for information about how to configure Chapel for multi-locale execution. To emulate multiple locales on a single machine, you can set the following environment variables before building Chapel from source:

```console
CHPL_COMM=gasnet
CHPL_COMM_SUBSTRATE=smp
GASNET_SPAWNFN=L
```

Alternatively, consider using the `chapel-gasnet` [docker image](https://hub.docker.com/r/chapel/chapel-gasnet/) to run the programs in this article. It's pre-configured to emulate multiple locales on a single machine.

With Chapel set up, the above program can be compiled and run as follows. The `-nl` argument specifies the number of locales to use (`4` in this case):

```console
chpl datapar-example.chpl --fast
./datapar-example -nl 4
```
Printing `A` shows us where each of the values are located. Changing the domain's size or the number of locales will change how the array is distributed.

{{< console fname="datapar-example.good" >}}

If you change the `forall` loop to the following and recompile the program, its output will show where each of the parallel tasks that execute the body of the loop run (remember that `here` is an alias for whichever locale the current task is executing on):

```chapel
forall a in A do
    a = here.id;
```

This will produce exactly the same output, meaning that the parallel iterator is designed such that the locality of task execution coincides with the locality of the array's data. Each CPU works on the data it has the fastest access to.

### The Stencil Distribution and Distributed Poisson Solver

Using the above concepts, we could start writing a distributed data-parallel Navier-Stokes simulation. However, before we get to the full code, which will be featured in the next article in this series, let's start by considering how we'd rewrite the Poisson solver from the previous article to be distributed. This will be a useful stepping stone, because the Poisson solver is used as a part of the full Navier-Stokes simulation.

#### The Poisson Stencil

The kernel used in the Poisson Solver is based on this equation:

$$ p_{i,j} = \dfrac{(p_{i-1,j} + p_{i+1,j}) \Delta y^2 + (p_{i,j-1} + p_{i,j+1}) \Delta x^2 + b_{i,j} \Delta x^2 \Delta y^2}{2 (\Delta x^2 + \Delta y^2)} $$

We can think of it as a 5-point stencil computation, meaning that the value of each point in $p$ is computed in terms of the four surrounding points in $p$ as well as the same point in $b$. If $p$ and $b$ are both represented by block-distributed 2D arrays with the same 4-locale layout as above, the 5-point stencil computation for a given point in $p$ would look something like this:

{{< figure src="stencil-local.png" >}}

The blue lines represent boundaries between locales. So, for the above $i,j$ pair, $p_{i,j}$ is computed using values stored in memory on the same locale. In other words, all of the teal boxes in the figure represent local memory accesses on locale 0. The picture is more complicated when computing the value one point to the right:

{{< figure src="stencil-remote.png" >}}

Here, the value $p_{i,j+1}$ belongs in a different locale's memory, and thus computing $p_{i,j}$ will involve retrieving that value over the network. This is something that Chapel's compiler and runtime will handle for us, but the memory access will be significantly slower than the other 4 neighboring points in the stencil.

A downside of relying on the implicit communication is that an individual network operation will be kicked off for each array element along the locale borders. For a (realistically) large problem size, we'll end up with many single-element communication events over the system's network — this is typically bad for performance. Instead, we should try to maximize the network's efficiency by doing a small number of large communication operations (i.e., groups of elements should be communicated over the network in bulk instead of one at a time). To help facilitate this, Chapel provides the Stencil Distribution.

#### The Stencil Distribution

The [Stencil Distribution](https://chapel-lang.org/docs/modules/dists/StencilDist.html) is essentially a variation on the Block Distribution. It distributes array elements across locales in exactly the same fashion, but also maintains local copies of neighboring locales' elements on each locale. For our 2D case, you can think of these copies as a "halo" of neighboring elements around each block. This way, when applying a stencil operation to an array element along a locale boundary, no communication over the network is required.

With stencil-distributed arrays, the same computation as above would look like this:

{{< figure src="stencil-stencil.png" >}}

The array access that had previously resulted in communication now accesses a halo element in local memory, represented with a dotted blue border. Note that in the above figure, the halo regions on the boundary are grayed out because they {{< sidenote "left" "are not used" >}} `stencilDist` supports cyclic boundary conditions where these halos would contain elements from the neighboring locale on the other side of the domain, but we won't use them here since the Poisson Equation Solver uses Neumann boundary conditions. {{</ sidenote >}}.

Each time we compute an updated state in the finite-difference computations, those strips of elements need to be updated with their latest values from the neighboring locales. This is done by calling the `updateFluff` method provided by the Stencil Distribution. The following diagram shows what that looks like, where a whole group of elements is transferred in bulk instead of one at a time. Only one pair of edges is shown here, but in reality, all pairs of edges (and the corner elements) will be exchanged.

{{< figure src="stencil-update.png" height=250px >}}

### Converting the Poisson Solver to use Distributed Arrays

To see how `stencilDist`, and distributed arrays in general, look in code, let's modify the Poisson Solver from the previous article to use a 2D stencil-distributed array. This only requires three simple changes:

1. Import the `StencilDist` module
2. Replace the `space` domain's definition with the following line (where `fluff` specifies how large the halo region should be along each dimension):

    ```chapel
    const space = stencilDist.createDomain({0..<nx, 0..<ny}, fluff=(1,1)),
    ```

2. Add calls to `pn.updateFluff()` before calls to `poissonKernel` to refresh the data in the halo regions.

With those adjustments, the code will be able to run efficiently on a cluster/supercomputer, taking advantage of the processing power and memory of multiple compute nodes. The full modified code can be downloaded below:

{{< file_download_min fname="nsPoissonStencil.chpl" lang="chapel" >}}

Note that you'll need the `surfPlot` module provided in the [previous article]({{< relref "bns2#running-and-generating-plots" >}}) to compile. Additionally, you'll want to run the program with a much larger problem size than the default in order to reap the benefits of using distributed memory — more on this in the next article.

To show just how minor the above changes are, here is the entire diff between the previous article's shared-memory Poisson solver and the distributed one above:

{{< figure src="nsPoissonDiff.png" class="fullwide" >}}

<!-- ```diff
1a2
> use StencilDist;
20c21
< const space = {0..<ny, 0..<nx},
---
> const space = stencilDist.createDomain({0..<ny, 0..<nx}, fluff=(1,1)),
55d55
>         pn.updateFluff();
75d74
>         pn.updateFluff();
``` -->

Notably, only one line needed to change in our 92-line program, with just three new lines being added. Even more importantly, none of the science of the computation needed to change: the code for the kernel, boundary conditions, and termination conditions remained exactly the same.

### Conclusion

This article gave an overview of some of Chapel's distributed programming features, starting from the more foundational concepts (locales and on-clauses), and moving up to higher-level features like distributions and distributed arrays. We saw that these high-level features in particular can be used to concisely express multi-node stencil computations without modifying the program's mathematical kernels, but only changing how the relevant arrays are defined.

Amazingly, we were able to convert the single-node Poisson solver from the previous article to use distributed data-parallelism by changing a total of only 4 lines of code. As we'll see in the next article, that is not something that can be said of other distributed-memory programming tools like MPI. And to demonstrate that these productivity benefits don't come at a performance cost, we'll also show a performance comparison with a MPI+OpenMP Navier-Stokes solver.

The Chapel Team would like to express its sincere gratitude towards the [Barba Group](https://lorenabarba.com/) for creating and maintaining the CFD Python tutorials.
