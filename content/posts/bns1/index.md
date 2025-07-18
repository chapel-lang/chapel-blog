---
title: "Navier-Stokes in Chapel — Introduction"
tags: ["Math", "Differential Equations", "How-to", "Computational Fluid Dynamics", "Language Comparison"]
series: ["Navier-Stokes in Chapel"]
authors: ["Jeremiah Corrado"]
date: 2024-04-10
summary: "A starting point for applying Chapel to scientific computing problems using the CFD Python tutorial."
---

The [CFD Python: 12 steps to Navier-Stokes](https://lorenabarba.com/blog/cfd-python-12-steps-to-navier-stokes/) tutorial created by the *Lorena A. Barba Group* is a basic introduction to writing computational fluid dynamics software in Python. It covers everything from simple 1D convection to a fully functional 2D Navier-Stokes simulation and is widely used as a teaching tool for students in various sub-fields of computational physics.

This blog post aims to offer a starting point for using the Chapel Programming Language in scientific computing applications by translating portions of the CFD Python tutorial into Chapel. It aims to show how easy that translation process is (even for a Chapel beginner) and how practical it can be to use Chapel's parallel programming features to fully take advantage of parallel hardware, like a multi-core laptop.

I don't assume that you've gone through the entire CFD Python tutorial; however it may be useful as a reference on occasion, especially if you're interested in learning more about the math and theory behind the code discussed below.

### Where We're Going

The next posts in this series will leverage the material here and use the more complex examples in the CFD Python tutorial to explore advanced Chapel topics. In those posts, we'll see some more realistic and exciting results like those from a 2D cavity-flow simulation depicted below.

In this series' third and fourth posts, we'll explore using Chapel for multi-node (or distributed memory) execution of larger CFD simulations. This will be especially useful for scientists/researchers/students who are interested in using Chapel to expand the size of their simulations beyond the limits of a single computer. They'll also be useful for those who have achieved scale with other CFD stacks like C++/MPI, but would prefer to work with a friendlier and more productive language.

{{< figure src="cavity_flow_example.png" title="2D Cavity Flow Example" >}}

### Porting 1D Diffusion to Chapel

The first four steps of the CFD Python tutorial all adhere to a similar code structure. Here, we'll focus on [**step 3**](https://nbviewer.org/github/barbagroup/CFDPython/blob/master/lessons/04_Step_3.ipynb) specifically, noting that the same process could be used to translate any of the first four steps into Chapel.
#### Quick Rundown of the Math

Step 3 covers the process of creating a 1D diffusion simulation using the *Finite Difference* (FD) method. The diffusion behavior is defined by a partial differential equation that operates on a fluid's scalar density, $ u $, as a function of space ($ x $) and time ($ t $). The intensity of that change is mediated by the fluid's viscosity ( $ \nu $ ). These quantities have the following relationship:

$$ \dfrac{\partial u}{\partial t} = \nu \dfrac{\partial^2 u}{\partial x^2 } $$

Or, to think about this relationship conceptually: the rate at which the fluid's density (at a particular point in space) changes over time is directly proportional to its concavity (its second derivative with respect to $ x $). This means that adjacent regions of fluid with significant differences in density will change quickly, and those with small differences in density will change more slowly.

To simulate this behavior, we'll use the Finite Difference Method. Here, the fluid's density is represented by an array of numbers where each element is a discrete point in space, and the fluid's evolution in time is divided into discrete steps. So, for our purposes, the diffusion equation is discretized as follows, with the derivatives being replaced by "finite differences" over finite spatial and temporal intervals ($ \Delta t $, and $ \Delta x $ respectively):

$$ \dfrac{u_i^{n+1} - u_i^n}{\Delta t} = \nu \dfrac{u_{i+1}^n - 2u_i^n + u_{i-1}^n}{\Delta x^2 } $$

Here, the "$_i$" subscripts represent discrete points in space and the "$^n$" superscripts represent discrete states in time.

With the mathematical background established, we'll get into the tutorial's [original Python code](https://nbviewer.org/github/barbagroup/CFDPython/blob/master/lessons/04_Step_3.ipynb), and how it can be translated into Chapel.

#### Simulation Constants

To get started, we define some constants that dictate the behavior of our simulation. By reusing these throughout the program, we'll be able to easily tune the simulation's behavior by changing the values here. The Python CFD code defines the following constants:

```python
nx = 41                     # Number of Finite Difference points
dx = 2 / (nx - 1)           # Spatial step-size (Delta-x)
nt = 20                     # Number of time steps
nu = 0.3                    # The fluid's viscosity
sigma = 0.2                 # A simulation stability parameter
dt = sigma * dx**2 / nu     # Temporal step-size (Delta-t)
```

This can be translated quite directly into Chapel, with the primary difference being the need for the `const` keyword. Whenever declaring a new variable in Chapel, either `var` or `const` is needed (where `const` designates that the variable's value cannot be changed once set):

```chapel
const nx = 41;                   // Number of Finite Difference points
const dx = 2 / (nx - 1);         // Spatial step-size (Delta-x)
const nt = 20;                   // Number of time steps
const nu = 0.3;                  // The fluid's viscosity
const sigma = 0.2;               // A simulation stability parameter
const dt = sigma * dx**2 / nu;   // Temporal step-size (Delta-t)
```

Although valid, the above can be modified further to take advantage of some additional features in Chapel:
1. The `config` keyword can be added before `const` to make the variables command-line configurable (more on this later)
2. The repetition of the `const` keyword isn't necessary and can be condensed by combining multiple declarations into a single statement

With those incorporated, we have the following start to our program:

{{< subfile fname="nsStep3.chpl" lang="chapel" lstart=4 lstop=11 section="first" >}}

Given that `dx` and `dt` are defined by the other constants, they are separated onto their own lines, and are not marked as configurable.

#### Arrays and Initial Conditions

Next, we define a 1D array of floating-point values to represent the state of our simulated fluid at any one time. Each entry in this array represents the density of the fluid at that one point in space. As we progress forward in simulated time, a new array will be computed to represent the fluid's state at that next time step.

In Python, we use a NumPy array to hold these values:

```python
u = numpy.ones(nx) # an array with 'nx' elements all set to 1
```

We also want to set up some initial conditions. Think of this as the simulation's input. Without it, we'd only be simulating a perfectly uniform fluid, which would not change over time.

Following the tutorial, we'll use a square-wave as an initial condition for $u$:

$$
u(x) = \begin{cases}
2 &\text{if } 0.5 \le x \le 1.0 \\
1 &\text{otherwise}
\end{cases}
$$

This is done by setting a sub-region of the array to `2`:

```python
u[int(0.5 / dx):int(1 / dx + 1)] = 2 # Set u = 2 between x = 0.5 and 1.0
```

The array creation translates into Chapel as follows:

{{< subfile fname="nsStep3.chpl" lang="chapel" lstart=13 lstop=13 section="middle" >}}

Here, we are creating a variable `u`, whose type is `[0..<nx] real`, and assigning the value `1` to it. The square-braces designate that the variable is an array, the `0..<nx` portion of the expression means that the array will be defined over the indices `0` though `nx` (non-inclusive), and the `real` means that the array has an element type of 64-bit real numbers.

{{< details summary="**more on defining arrays...**" >}}

One benefit of this syntax for defining arrays, is that it allows us to use any range of indices. For example, let's say we have a preference towards 1-indexing (maybe we are porting an application from Matlab or Fortran). The above would be rewritten as:

``` chapel
var u : [1..nx] real = 1;
```

In other words, the range `1..nx` dictates that `u`'s indices are the integers `1` through `nx` (inclusive).

With one-indexing, the expression to set initial conditions would also change:

```chapel
u[((0.5 / dx):int + 1)..(1.0 / dx + 1):int] = 2;
```

For more on this topic, see the introductory documentation about [Ranges](https://chapel-lang.org/docs/primers/ranges.html) and [Arrays](https://chapel-lang.org/docs/primers/arrays.html) in Chapel.

{{< /details >}}

The initial conditions can then be set with the following expression, which is nearly identical to the Python code:

```chapel
u[(0.5 / dx):int..<(1.0 / dx + 1):int] = 2;
```

However, since Chapel's range expressions allow for an inclusive upper-bound (by omitting the&nbsp;`<`), we'll use a slightly simplified expression instead:

{{< subfile fname="nsStep3.chpl" lang="chapel" lstart=14 lstop=14 section="middle" >}}

#### Loops and Stencil Computations

With our simulation parameters and initial conditions in place, we can set up a finite difference simulation. For this purpose, the discretized differential equation from above rearranges into a more useful form:

$$ u_i^{n+1} = u_i^n + \dfrac{\nu \Delta t}{\Delta ^2x} (u_{i+1}^n - 2u_i^n + u_{i-1}^n)$$

Here, the state of any value in the array with spatial index `i` at the next time step `n+1` ($u^{n+1}_i$) is defined in terms of its current state ($u^n_i$) as well as the state of the two adjacent entries.

To implement the equation above, our program will need a temporary copy of `u`. We'll call this one `un` to represent the state of the fluid at the current time step $u^{n}$. The array `u` will be used to represent the state of the fluid at the next time step ($u^{n+1}$). This way, at the end of our simulation, `u` will contain the results from the final time step.

At each iteration through time, we'll take the results from the previous iteration (`u`) and store them in `un`. Think of this as swapping `u` and `un`. We'll then apply the finite difference equation to all the sets of three adjacent points in `un` and store the results in `u`. This process is summarized in the following figure:

{{< figure src="stencil_diagram.jpg" title="1D Stencil Loop Structure" >}}

It is also notable that the outer elements of `u` are never updated, meaning that we have an implicit Dirichlet boundary condition (the fluid at the edges of our domain must maintain their initial density of 1).

In Python, the finite difference computation is implemented as follows, where the outer `for` loop corresponds to the time-arrow in the above diagram, and the inner `for` loop corresponds to the space-arrow:

```python
un = numpy.ones(nx)  # temporary copy of u
for n in range(nt):  # simulate 'nt' time steps
    un = u.copy()    # copy the results of the previous iteration into 'un'
    # apply FD equation:
    for i in range(1, nx - 1):
        u[i] = un[i] + nu * dt / dx**2 * (un[i+1] - 2 * un[i] + un[i-1])
```

The translation into Chapel is quite straightforward:

{{< subfile fname="nsStep3.chpl" lang="chapel" lstart=21 lstop=27 section="last" >}}

You'll notice a couple of minor differences:
1. The swap operator `<=>` is used to populate `un` with the previous iteration's `u` values. Not only does it look cleaner (in my opinion), it's also more performant than an explicit copy because it uses a pointer-swap under the hood
2. Unlike Python, Chapel does not use indentation to designate code blocks. For multi-line code blocks, like the outer loop, curly braces are used. For single-line blocks, like the inner loop, the `do` keyword *can* be used in place of curly-braces. Similar keywords are allowed in other control-flow operators (i.e., `if condition then doSomething();`).

And there is one *minor-looking* difference with significant implications.

Rather than a traditional `for` loop, the inner loop uses `forall` — a Chapel feature that results in parallel iteration. It can be used in any order-independent loop like this one, where the order of execution doesn't affect the meaning of the program. By using `forall`, we indicate to the compiler that the iterations in the range `1..<(nx-1)` can be split up and executed by separate tasks in parallel. This simple change allows our program to fully take advantage of the hardware, as Chapel's runtime will automatically generate enough tasks to saturate all CPU cores by default.

Note that this works by simply invoking the range type's parallel iterator, which is implemented in terms of Chapel's lower-level parallel programming features. This means that user-defined types can also implement their own parallel iterators which can then be invoked by a `forall` loop. More information about `forall` loops can be found in the [documentation](https://chapel-lang.org/docs/primers/forallLoops.html).

### Compiling and Running

And finally, we are ready to put things together and test our program. If you don't already have Chapel set up on your system but you'd like to follow along, there are several ways to get started — take a look at this ["how can I try Chapel"]({{< relref "announcing-chapel-2.0.md#try-chapel-instructions" >}}) section for details.

Combining the code segments from above, along with some calls to an external plotting function, we have the following Chapel source file:

{{< file_download fname="nsStep3.chpl" lang="chapel" >}}

Where `simplePlot` is a helper function (for demonstration purposes) that creates an ASCII plot in the terminal output. It is imported from the following file (which you may find useful as an example of formatted IO in Chapel):

{{< file_download_min fname="plotUtil.chpl" lang="chapel">}}

In upcoming posts in this series, we'll discuss how to use external tools to generate high quality visualizations. For now, `simplePlot` should get the job done!

Overall, our code is very similar in length and composition to the full Python code. This means that we get the benefits of a high performance compiled language without the typical complexity associated with HPC libraries/languages. Not only that, but as we'll see in upcoming posts, modifying this program to run across multiple compute nodes is an almost trivial process requiring only a few lines of changes, which is not something that can be said about other high-productivity and high-performance tools.

#### Compiling

In your terminal, navigate to a directory with `nsStep3.chpl` and `plotUtil.chpl` present. Use the following command to compile:
{{< terminal_command >}} chpl nsStep3.chpl --fast {{< /terminal_command >}}

The `--fast` flag ensures that performance optimizations are enabled. Without it, your program will do some extra work like bounds-checking, which can be useful during development but tends to slow things down noticeably.

Also, note that we did not have to point the compiler to `plotUtil.chpl`; it was automatically included because `chpl` searches the surrounding directory for imported modules.

#### Running

Run the resultant binary by calling it in your terminal:
{{< terminal_command >}} ./nsStep3 {{< /terminal_command >}}

This will produce the following output:
{{< console fname="nsStep3.0-1.good" >}}

As you can see in the upper plot, our initial conditions match the square wave specified in the code. And in the second plot, we can see that the fluid's density has clearly spread out into the surrounding area.

Running again with some command line arguments to increase the number of iterations and the number of simulated points (making use of the `config` constants discussed above),
{{< terminal_command >}} ./nsStep3 --nt=100 --nx=60 {{< /terminal_command >}}

we get similar results, except the plot is clearly wider to accommodate more points, and the diffusion has progressed further due to the increased number of time-steps:
{{< console fname="nsStep3.0-2.good" >}}

### Conclusion

The goal of this tutorial was to provide a window into the world of scientific computing with Chapel. With a simplified fluid-dynamics example, we provided a brief introduction to the language and highlighted some of the unique features that Chapel offers. These included the `config` keyword, which is especially useful for iteratively tuning a simulation, the powerful array syntax that allows a high degree of flexibility, and `forall` loops — one of the many powerful parallelism abstractions in Chapel.

We have also set the stage for the later posts in this series where we will use some of the more complex [CFD Python](https://lorenabarba.com/blog/cfd-python-12-steps-to-navier-stokes/) steps to explore some other more advanced Chapel features.

The Chapel Team would like to express its sincere gratitude towards the [Barba Group](https://lorenabarba.com/) for creating and maintaining the CFD Python tutorials.

### Updates to this article

{{< changetable >}}
  | Date         | Change                                                      |
  |:-------------|:----------------------------------------------------------------------------------|
  | Apr&nbsp;16,&nbsp;2024 | Fixed error in "Cavity Flow Example" figure due to improper boundary conditions |
  | Apr&nbsp;16,&nbsp;2024 | Removed incorrect note about the Poisson equation |
