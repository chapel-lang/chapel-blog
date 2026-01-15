// Introduction to GPU Programming in Chapel
// tags: ["GPUs", "How-To"]
// series: ["GPU Programming in Chapel"]
// summary: "This post gives a beginner's introduction to Chapel's GPU programming features"
// featured: true
// authors: ["Daniel Fedorin"]
// date: 2024-01-10
// weight: 70

/*
  Chapel is a programming language for productive parallel computing.
  In recent years, a particular subdomain of parallel computing has exploded
  in popularity: GPU computing. As a result, the Chapel team has been hard at
  work adding GPU support, making it easy to create vendor-neutral and performant
  GPU programs. This aspect of the Chapel compiler has seen rapid improvements since
  its initial release, and continues to receive enhancements and performance fixes over time.
  This tutorial will provide an introduction to Chapel's GPU programming features.

  Although frameworks such as CUDA and HIP are commonly used for programming
  GPUs, this tutorial does not assume familiarity with them. Examples will
  make use of some general-purpose features of Chapel, and this post will
  explain them along the way. For a more deliberate introduction to Chapel,
  see the [Advent of Code](/series/advent-of-code-2022/) series on this blog,
  or check the [Learning Chapel](https://chapel-lang.org/learning.html) page
  for more resources.



  In this post, we'll jump right in to using Chapel's GPU programming features. If
  you're interested in a refresher on what problems GPUs are useful for,
  check out the [_Appendix_ section containing this information]({{< ref "#appendix-what-sorts-of-problems-benefit-from-gpus" >}}).

  ### Locales and `on` Statements: The Foundation of Chapel
  When GPUs are in play, it's possible for code to be executing
  in different places: it could be running either on a CPU, as most programmers
  are used to, or on a GPU. GPUs and CPUs differ significantly;
  code well-suited for one may not be well-suited for the other.
  Chapel gives the programmer control over where their code is running through
  its notion of _locales_. Quoting from the
  [Chapel specification](https://chapel-lang.org/docs/primers/locales.html):

  > In Chapel, the `locale` type refers to a unit of the machine resources on
  > which your program is running.

  In other words, a locale is a part of the computer that can run code;
  this might represent a GPU or a CPU. Chapel's _`on` statement_, when given
  a locale, can be used to explicitly state where a particular piece of code
  should be executed. For example, the following code computes and prints the
  even numbers up to ten, running the computation on the first GPU locale.

 */

config const n = 5; // use 5-element arrays in examples by default, for brevity

on here.gpus[0] {
  var A: [1..n] int; // declare an array with n elements
                     // (to benefit from GPUs, you'd probably want n >> 5)
  foreach i in 1..n do
    A[i] = i * 2;

  writeln("The whole array A is: ", A); // hugo-tag="writeln"
  for i in 1..n do
    writeln("A[", i, "] = ", A[i]);
}
writeln("__BREAK__");

/*
  The code starts with an `on` block targeting a GPU _sub-locale_.
  This block references `here`, a special variable that refers to the
  locale currently running the code. When GPU support is enabled, locales
  include a field called `gpus`, which is an array of sub-locales, each
  representing an installed GPU. On a locale with a single GPU, `here.gpus`
  will be a single-element array. On locales with more than one GPU (which is
  {{< sidenote "right" "common in supercomputers" -3 >}}
  I mentioned supercomputers here for a reason. Chapel's GPU support
  has been tested on large machines, including Frontier, the only
  exascale supercomputer in the TOP500 list at the time of publishing.
  {{< /sidenote >}}), `here.gpus` will have as many elements as
  there are GPUs. Thus, `here.gpus[0]` is the machine's first GPU.

  {{< details summary="**(How do I enable GPU support?)**" >}}
  To enable GPU support, Chapel must be built with with the `CHPL_LOCALE_MODEL`
  environment variable set to `gpu`. In a Bash session, the variable can be
  set as follows:

  ```bash
  export CHPL_LOCALE_MODEL=gpu
  ```

  If you have an NVIDIA GPU, this should be enough to compile and run GPU-enabled
  programs. For AMD GPUs, you will also need to specify your GPU's architecture
  using the `CHPL_GPU_ARCH` environment variable:

  ```bash
  export CHPL_GPU_ARCH=your_arch_here
  ```

  Finally, even if you don't have a GPU, Chapel provides a mode called
  'cpu-as-device'. In this mode, you still get a `here.gpus` array, and
  can write code targeting GPUS; however, your computer's CPU will be used
  to execute all code. This makes it possible to develop GPU-enabled programs
  without access to a GPU. Setting the `CHPL_GPU` environment variable to
  `cpu` enables 'cpu-as-device' mode:

  ```bash
  export CHPL_GPU=cpu
  ```

  Please see the page on [building chapel](https://chapel-lang.org/docs/usingchapel/building.html)
  as well as the [GPU technical note](https://chapel-lang.org/docs/technotes/gpu.html)
  for more information on GPU-related environment variables.
  {{< /details >}}

  The code generates even numbers by iterating over the indices
  one through five, multiplying each by two. GPUs are good at solving the same
  sub-problem many times in parallel; doubling each number can be its own sub-problem,
  making the loop in the example well-suited for GPU execution. The multiplication
  loop is written using the `foreach` keyword, which tells Chapel that it
  is safe to execute in parallel. The language takes care of the rest.
  Chapel has traditional `for` loops as well, like the second loop in the example.
  We'll talk about the difference between the two further down.

  Whereas the `foreach` loop in the example runs on the GPU, the `writeln`
  on line {{< get_line_anchor tag="writeln" >}}
  doesn't. Unlike the multiplications, printing a single string to the
  console is not a good match for the GPU. Generally, code that's
  suitable for GPU execution can be broken up into many similar and independent
  pieces. For a loop, this translates into _order-independence_. A loop
  is order-independent if no iteration affects any of the others.
  Thinking back to our example, let's examine the multiplication loop again:

  ```Chapel
    foreach i in 1..n do
      A[i] = i * 2;
  ```

  We can observe that the result of `5*2` does not affect the
  computation of `3*2`. Each iteration accesses a different element of `A`,
  so there are no data races. Thus, our example is an instance of an
  order-independent loop. Chapel leaves it up to the programmer to indicate
  which loops have this property; to assert that a loop is order-independent, it
  should be written {{< sidenote "right" "using the `foreach` keyword." >}}
  Chapel also features `forall` loops. These loops allow the
  the data structure being traversed to decide how iteration is parallelized.
  Data structures that ship with the Chapel standard library are smart enough
  to make use of order-independence, so an eligible `forall` loop on
  a GPU locale would also be executed on the GPU.

  See the [loops primer](https://chapel-lang.org/docs/main/primers/loops.html)
  to learn more about Chapel's various types of loops.
  {{< /sidenote >}}

  It's not hard to see why order-independent loops lend themselves well to
  GPU execution. If it doesn't matter in what order the loop's iterations are executed, then
  we can think of each iteration as an independent sub-problem to be handed off
  to a GPU core. This observation is the foundation of Chapel's GPU support:
  __order-independent loops can be executed in parallel on the GPU__. In fact,
  Chapel will automatically convert order-independent loops into GPU code
  whenever it can.

  {{< details summary="**(I know CUDA/HIP. Can you tell me more about how this works?)**" >}}
  In CUDA and HIP, writing a GPU-enabled program generally involves creating a function
  marked as `device` or `global`, and using this function in a
  kernel launch. Under the hood, Chapel
  does the same.

  When Chapel encounters a GPU-eligible loop, it converts its body into a function,
  named something like `chpl_gpu_kernel_filename_linenumber`. If the loop
  body / newly defined kernel function contains calls to other functions or
  methods, Chapel also generates `device` versions of these.

  Chapel inserts a kernel launch alongside the original loop. Since
  the same code could be executed from `here.gpus[0]` (GPU) or the default
  locale (CPU), Chapel preserves the loop as well. Thus, on a GPU it performs
  the kernel launch, and on a CPU, it falls back to the loop.
  {{< /details >}}

  In comparison, the second loop in the example is _order-dependent_.

  ```Chapel
    for i in 1..n do
      writeln("A[", i, "] = ", A[i]);
  ```

  We specifically intend for the elements of `A` to be printed in order. Because of this,
  the iteration that prints the fifth element has to happen after printing the
  fourth; there's a dependency. In Chapel, loops whose iterations need to be
  executed one after another (called _serial loops_) are written using the `for`
  keyword. Loops written using `for` are not considered by the compiler for GPU
  execution.

  We have now scrutinized almost every piece of the example. One significant
  piece remains: we also declared an array `A` to contain the even numbers:

  ```Chapel
  on here.gpus[0] {
    var A: [1..n] int;

    // ... the rest of the even numbers example
  }
  ```

  An important aspect of the `on` statement is that variables declared inside an `on`
  block logically live on the locale targeted by the statement. Typically, this
  means that it's faster to access these variables from that same locale,
  and slower from other locales. Here's an example:

  ```Chapel
  on firstLocale {
    var A: [0..10] int;
    A[0] = 1;   // Cheap to access 'A':
                // 'A' is accessed from the same locale that it lives on

    on anotherLocale {
      A[0] = 2;   // More expensive to access 'A':
                  // 'A' is accessed from another locale
    }
  }
  ```

  {{< sidenote "right" "Currently," >}}
  In the future, Chapel aims to make it possible for GPU code to access arrays
  declared outside of the GPU locale. However, this would require some
  communication between the GPU and CPU, initiated by the GPU. _GPU-driven
  communication_ like that is on our roadmap, but not supported at the
  time of writing.
  {{< /sidenote >}}
  to make an array accessible from code that runs on the GPU (such as
  our `foreach` loop), the array must live on the GPU locale. This is why
  we declare `A` inside the `on` block, rather than outside of it. Had `A`
  been declared outside the `on` block, it would've been on the CPU locale,
  allocated in CPU memory.

  Now we've gone over the whole introductory example, demonstrating how GPUs
  can be targeted in Chapel using `on` blocks and `foreach` loops. However, this example
  is a very simple program, meant to introduce key concepts in Chapel's
  GPU support. What we've seen so far is only the beginning. In the next
  section, we'll take a look at other features of Chapel that mesh seamlessly
  with GPU programming.

  ### What Else Can You Do on a GPU?
  A large portion of the Chapel language can run on the GPU. In this section,
  I'll give a bit of a whirlwind tour of what can be done. To learn more about
  the individual language features I'll be showing off, please take a look
  at the resources mentioned at the beginning of this article.

  As we go through examples, the reader might wonder: how can we be sure that
  the code ran on the GPU? Tracking which code runs where is a slightly more
  advanced topic. For the sake of simplicity, I will define a custom function,
  `numKernelLaunches`. The word _kernel_ typically refers to bits of
  code that run on a GPU. A _kernel launch_ is the process of a CPU starting
  the execution of a kernel on the GPU. You don't have to understand how my helper
  function works; it's sufficient to think of `numKernelLaunches` as
  returning the total number of kernel launches since the last time we checked.
  I'll be using this function to ensure that code ran on the GPU when we expected
  it to.

  {{< details summary="**(I do want to see how the function is defined!)**" >}}
*/

use GpuDiagnostics;

proc startCountingKernelLaunches() {
  resetGpuDiagnostics();
  startGpuDiagnostics();
}

proc numKernelLaunches() {
  stopGpuDiagnostics();
  var result = + reduce getGpuDiagnostics().kernel_launch;
  startCountingKernelLaunches();
  return result;
}

startCountingKernelLaunches();

/*
  {{< /details >}}

  All examples in this section will be performed on the GPU locale.
 */

on here.gpus[0] {

/*
  Let's start with something fun. At the beginning of this article, we used
  the GPU to multiply some numbers by two using a `foreach`. We can do
  this even more succinctly using a Chapel feature called
  [_promotion_](https://chapel-lang.org/docs/users-guide/datapar/promotion.html).
  Promotion allows us to pass an array to an operation that requires a scalar
  value. When we do so, the operation is automatically performed on each element
  of the array. This is automatically done in parallel ---
  potentially on the GPU.

  If our operation is "multiply by two", we can write code as follows:

 */

  var Evens = 2 * [1,2,3,4,5];
  writeln(Evens);

  // One kernel launch from the promoted initializer
  assert(numKernelLaunches() == 1);
  writeln("__BREAK__");


/*
  In just one simple line, we were able to write code that runs on the GPU.

  Let's move on to our next example. We can call most Chapel functions from
  code running on the GPU.
  The following example samples the built-in sine function `sin` on ten
  increments within the interval \([0, 2\pi)\):
 */

  use Math; // Include the 'Math' module for access to 'sin' and 'pi'

  const numSamples = 10;
  var A = [i in 0..#numSamples] sin(2 * pi * i / numSamples);

  writeln(A);

  // One kernel launch from the loop expression initializer
  assert(numKernelLaunches() == 1);
  writeln("__BREAK__");

/*
  Functions called from the GPU can be user-defined and arbitrarily complex.
  In the following example, we use promotion again to compute the first 20 Fibonacci numbers.
  This example
  {{< sidenote "right" "is not at all optimized," >}}
  The example is unoptimized in both an algorithmic and GPU-specific sense.

  On the algorithmic side, those familiar with the analysis of algorithms will
  likely know that there exists an \(O(n)\) algorithm to compute the \(n\)th
  Fibonacci number. Meanwhile, our naive algorithm is \(O(2^n)\) — quite bad.
  Furthermore, our implementation doesn't make use of any memoization, performing
  a lot of redundant computations between array elements.

  On the GPU-specific side, we are writing code that will cause <em>thread
  divergence</em>. Each thread will perform a slightly different sequence of steps,
  which makes it much harder for the GPU to execute them.
  {{< /sidenote >}}
  but serves as a good demonstration of using arbitrary functions in a
  kernel, including recursive ones.

 */

  proc fib(x: int): int {
    if x <= 1 then return 1;
    return fib(x-1) + fib(x-2);
  }

  var Fibs = fib(0..#20);
  writeln(Fibs);

  // One kernel launch from the promoted expression in the initializer
  assert(numKernelLaunches() == 1);
  writeln("__BREAK__");

/*
  Here, `fib` is a normal Chapel function that is being promoted by calling
  it with the integer range `0..#20`.
  Note that we are able to use it in a GPU kernel without needing to do anything special.
  This is true in general: in Chapel, once a function has been defined, it can be
  called from both the GPU and the CPU.

  Loops can also be executed as part of a kernel. For our last example, we'll
  define a two-dimensional array `Square`, then sum each of its columns on
  the GPU. The following code will initialize, populate, and print this new
  square array:
 */

  var rows, cols = 1..5;
  var Square: [rows, cols] int;
  foreach (r, c) in Square.indices do
      Square[r, c] = r * 10 + c;

  writeln("Original array:");
  writeln(Square);

  // Two kernel launches: one from initializing Square, one from the loop
  assert(numKernelLaunches() == 2);
  writeln("__BREAK__");

/*
  With the new `Square` array in hand, we move on to summing its columns. Inside
  the `foreach` loop, we use another `for` loop as we normally would.
 */
  var ColSums: [cols] int;
  foreach c in cols do {
    var sum = 0;

    for r in rows do
      sum += Square[r, c];

    ColSums[c] = sum;
  }
  writeln("Column sums:");
  writeln(ColSums);

  // Two kernel launches: one from initializing ColSums, one from the loop
  assert(numKernelLaunches() == 2);
  writeln("__BREAK__");

/*
  Having gone through a few examples, we can conclude our `on` block
  and return to computing on the CPU.
 */

} // end of `on here.gpus[0]`

/*
  Now we have seen several example computations using Chapel's GPU support.
  Where can we run all of this code? Let's talk about that next.

  ### Where Can I Run Chapel Code for GPUs?
  You might recall from the introduction that Chapel's GPU support is
  vendor-neutral. This means that GPU-enabled Chapel code can be executed
  on both NVIDIA and AMD GPUs, without any modifications! This includes all
  of the code presented in this article.

  In fact, you don't even need a GPU. Chapel supports a mode called 'CPU-as-device',
  which allows code targeting GPUs to transparently execute on the CPU. You
  can prototype GPU-enabled code on a laptop without dedicated graphics, then
  switch to a GPU-enabled machine whenever you like. In fact, this is how this
  article was written.

  Finally, Chapel's GPU support, like the rest of the language, is scalable.
  Programs prototyped on a laptop can easily be executed on a supercomputer,
  with good performance. Although writing code in a scalable way requires
  {{< sidenote "right" "some additional steps," >}}
  Not using only the first GPU via `here.gpus[0]` is one such step.
  {{< /sidenote >}}
  Chapel makes it easy to create parallel code that runs everywhere.

  ### Summary
  Chapel's GPU support goes much deeper, but this might be a good stopping point
  for an introductory article --- we've already covered a lot of ground! Let's
  look back at a few of the things we've covered:

  * Chapel's _locales_ represent parts of the machine that can run code and store variables.
  * The `on` statement specifies where code should be executed, including on the GPU.
  * _Order-independent_ loops, written using `foreach`, are automatically executed on the GPU.
  * Much of the Chapel language can be used in GPU code.
    * This includes _promotion_, functions plain and recursive, and loops.
  * All of this is vendor-neutral; Chapel works with both NVIDIA and AMD GPUs.

  If you'd like to see more information on Chapel's GPU support in particular,
  the [tech note](https://chapel-lang.org/docs/technotes/gpu.html) contains many
  details and examples of GPU code, and the
  [__GPU Programming__ section of the release notes from Chapel 1.32](https://chapel-lang.org/releaseNotes/1.31-1.32/05-gpus.pdf)
  contains a "crash course on GPU programming".

  Of course, we have not yet seen a practical example of solving a problem on
  the GPU. We also have not yet seen how to analyze the performance of GPU-enabled
  programs in Chapel, or how to improve said performance. Finally, we didn't see
  how Chapel's GPU support frictionlessly integrates with the rest of the language
  to allow writing code that runs across all GPUs __and__ compute nodes. For
  a little sneak peek of that last point, take a look at this version of
  the "even numbers" example that runs on all GPUs in the system:
*/

coforall loc in Locales do on loc {
  coforall gpu in here.gpus do on gpu {
    var Evens = 2 * [1,2,3,4,5];
    writeln("Even numbers computed on ", gpu, ": ", Evens);
  }
}
writeln("__BREAK__");

/*

  In just six lines of code, we wrote a program that can make use of the
  computational resources of an entire supercomputer.

  We will be coming back to all of the above topics in subsequent posts,
  starting with writing multi-node, multi-GPU programs. Stay tuned!

  **The entire Chapel program presented in this post can be viewed here:**
  {{< whole_file_min >}}

  ### Appendix: What Sorts of Problems Benefit from GPUs?
  A huge difference between a GPU and a CPU is the number of _cores_.
  A core is the part of a processor that's responsible for executing instructions
  / machine code. Whereas I am writing this from a computer with around 10
  CPU cores, a cursory Google search indicates that the NVIDIA RTX 4070 GPU
  (picked arbitrarily by searching "consumer NVIDIA GPU")
  has 5888 cores ---
  {{< sidenote "right" "over 500 times the number of cores in my CPU!" -2 >}}
  In fact, because of the huge number of cores that concurrently execute code,
  GPUs are an example of a [massively parallel](https://en.wikipedia.org/wiki/Massively_parallel) architecture.
  {{< /sidenote >}}
  Of course, a CPU core is not the same as a GPU core: GPU cores tend to be
  much weaker individually.

  For problems that can be decomposed into a large number of
  {{< sidenote "left" "similar" >}}
  For GPUs, the sub-problems being similar is actually very significant.
  A single GPU core is actually solving multiple instances of
  a sub-problem _at the same time_, executing their code in lock-step.
  As soon as lock-step execution is no longer possible, and two sub-problems
  need different approaches, the GPU has to struggle a lot more. This problem
  is called _thread divergence_.
  {{< /sidenote >}}
  pieces,
  having a large number of weak cores is ideal. Each
  core can receive its own share of the problem, and work on it
  {{< sidenote "right" "independently;" >}}
  It's possible, and not too uncommon, to have a small degree of coordination
  between GPU cores when solving problems. GPUs are able allocate memory that's
  shared between cores, and to synchronize the cores' execution. However,
  this is slightly more advanced than this introductory article.
  {{< /sidenote >}}
  because each sub-problem is independent, all of the cores can be working on their
  share at exactly the same time. This can result in a very significant speedup
  over a single, powerful core: such a core would need to go through each
  of the pieces one after another.

  One example of a problem amenable to GPU execution is rendering an image to
  a screen. In fact, as the name _Graphics Processing Unit_ suggests, this
  was the very problem GPUs were developed to solve. When rendering, the color
  of each pixel can be computed relatively independently, based on depth and
  texture information; each core of the GPU can thus be working on a handful of
  pixels at a time, all in parallel, significantly speeding up the process.

  An entire problem domain that is well-suited for GPU execution is linear algebra.
  In matrix multiplication, for example, each cell in the output matrix can be
  computed independently from all the other cells; once again, this means that
  each GPU core can be working on a handful of cells in parallel. Many
  things, including neural networks, can be formulated in terms of matrix operations;
  fast linear algebra leads to faster machine learning models.

  The descriptions above should give you a taste of _what_ can be done with GPUs.
  The next obvious question is _how_ we can do all this with Chapel. This
  brings us to the topic of this blog: getting Chapel to run code on the GPU.

 */
