// Distributed Tuning in Chapel with a Hyperparameter Optimization Example
// tags: ["How-To", "AI/ML"]
// summary: "This post shows how to write a distributed tuning program in Chapel"
// authors: ["Lydia Duncan", "Michelle Strout"]
// date: 2024-10-08

/*

  Tuning a computation is a common challenge in science, engineering, and
  machine learning/AI.  Tuning involves calling the same program with a lot of
  different possible arguments and then analyzing the collection of results to
  determine the best argument combination.  A number of tools can be used to
  address this problem: [Dask](https://dask.org), [Ray](https://ray.io),
  [HyperOpt with Spark](https://hyperopt.github.io/hyperopt/scaleout/spark/),
  and [Dragon](https://github.com/DragonHPC/dragon), to name just a handful.
  This kind of tuning is generally useful for activities such as
  [autotuning](https://www.osti.gov/pages/biblio/1488544), [ensembles of
  simulations](https://en.wikipedia.org/wiki/Ensemble_forecasting), and
  [hyperparameter
  optimization](https://en.wikipedia.org/wiki/Hyperparameter_optimization).

  This blog post shows how to perform distributed and multicore parallel tuning
  using a toy target program and a polynomial fitting program. Both target
  programs are written in Python, but this framework works with executables
  written in any language that support the expected interface (information on
  the expected interface can be found in the [Distributed
  Tuning](#distributed-tuning-used-for-hyper-parameter-optimization) and
  [Additional Features](#possible-additional-features) sections). The tuning
  program, written in the open-source [Chapel Programming
  Language](https://chapel-lang.org), (1) randomly explores the argument space
  and (2) indicates which combination of arguments led to the best performance.
  The tuning program does this by `exec`ing instances of the given target
  program with different argument values in parallel over all the nodes and
  cores requested.  When the polynomial fitting program described below is
  passed to the tuning program, the tuning program written in Chapel is doing
  hyperparameter optimization.

  We hope you enjoy the tuning program and the example target programs—try it
  out on some of your own target programs, and consider giving Chapel a try!

*/

/*

  ### QuickStart

  To try out this Chapel tuning program on a toy target program, here are
  some quickstart instructions.

  {{< details summary="**Commands to run the Chapel tuning program in this post.**"  >}}

  1. **Install Chapel**: If you haven't already, install Chapel by following the
  relevant instructions at
  [chapel-lang.org](https://chapel-lang.org/download.html).

  2. **Compile this file**: Save [this file](code/tune.chpl) as
     `tune.chpl` and compile it with the following command:

     ```bash
     $ chpl tune.chpl
     ```

  3. **Download the toy target program**: Download the [toy program](toy.py)
  from here and save it as `toy.py`.

  4. **Run the Chapel program**: Run the Chapel program with the following

     ```bash
     $ ./tune
     ```

   {{< /details >}}

  **Here is the full program described in this post (which we recommend saving
    as `tune.chpl`).**
  {{< whole_file_min >}}

*/

/*

  The rest of this post describes how the Chapel tuning program works in detail,
  starting with the code that enables the tuning program to leverage all
  available distributed and multicore parallelism while executing many
  instances of a target program written in any programming language.

  ### How the Chapel Tuning Program Works

  The Chapel tuning programs starts with some `use` statements to obtain access
  to the library functions used below.

*/
use Random, List, Subprocess, OS.POSIX, BlockDist;

/*

  The key piece of the Chapel tuning program is its ability to execute instances
  of the target program in parallel across all of the available nodes and cores.
  The `evaluate` procedure defined below does this by iterating over all of the
  possible combinations in parallel using Chapel's special `forall` loop syntax
  (see line {{< get_line_anchor tag="forall-start" >}}) and by `exec`ing the
  target program within that parallel loop with the `spawnshell` procedure
  provided by the `SubProcess` module (see line {{< get_line_anchor
  tag="spawnshell-call" >}}).  The possible combinations are passed in as an
  array called `combosToCheck`.  We describe that array and the `combo` type a
  bit later in the post.

  The `evaluate` procedure is called by `main`, which is defined below. The
  arguments to `evaluate` include the command-line for executing the target
  program, which is passed as the argument `targetProgram`, as well as another argument
  that is a reference to an array of possible combinations (the `combo` data
  structure is described below). The first statement in the `evaluate` procedure
  is a `forall` parallel loop over all of the combinations in the
  `combosToCheck` array.

  {{< details summary="**The Chapel `forall` loop.**"  >}}

  A `forall` is a special type of `for` loop in Chapel.  Its usage signals to
  the Chapel compiler that the programmer expects the iterations of the
  `for` loop can execute in parallel without issue.  The `forall` loop
  implementation will use all available cores and also uses all available nodes
  if it is iterating over a distributed data structure, which the array
  `combosToCheck` ends up being.  For more information about the various loop
  types supported by Chapel, see
  https://chapel-lang.org/docs/primers/loops.html

  {{< /details >}}

*/

proc evaluate(targetProgram: string, const ref combosToCheck: [] combo) {

  forall currentCombo in combosToCheck { // hugo-tag="forall-start"

    /*

      Each combination of arguments is used to build an individual call to
      the target program:

    */

    var programCall = targetProgram;

    // Build the command-line call we should make
    for (arg, val) in currentCombo.args {
      programCall += " --" + arg + "=" + val: string;
    }

    /*

      We then run the command we've built as a subprocess using the
      `Subprocess` library's `spawnshell` function:

    */

    var process = spawnshell(programCall, stdout=pipeStyle.pipe, // hugo-tag="spawnshell-call"
                             stderr=pipeStyle.pipe);

    /*

      The subprocess may still be running when the program returns from
      `spawnshell`.  To avoid the operating system prioritizing the loop over
      the task it is waiting on, and to allow other tasks to start their subprocess
      runs, the code must actively tell the current task to yield.  Each time the OS wakes up
      this Chapel task, it will re-poll to see if the subprocess is done.

    */

    while process.running {
      currentTask.yieldExecution();
      process.poll();
    }

    /*

      With the while-loop ensuring that the subprocess is no longer running, the
      code will next ensure the subprocess stores the most up-to-date version of
      its output in the subprocess's `stdout` by calling its `communicate` method,
      and saving the result into the `result` field of the combination we were
      running:

    */

    process.communicate();
    try {
      currentCombo.result = process.stdout.read(real);
    } catch e {
      writeln("run failed: ", e.message());
      currentCombo.result = max(real);
    }
  }
}

/*

  The rest of the program
    * reads in the target program name and the space of arguments to explore,

    * randomly creates a distributed array of combinations to execute the target
      program on,

    * calls the above `execute` procedure, passing in the possible combinations,

    * and then prints out the best result found.


  This tuning program has some configuration constants.  `numTrials` controls
  the number of argument combinations to try.  `seed` controls the random number
  generator, so it is possible to have reproducible results.  `targetProgram`
  is the name of the target program to tune.  `argsString` is a string that
  specifies the arguments to tune and their ranges:

*/

config const numTrials = 10,
             seed = 121242412,
             targetProgram = "python3 toy.py",
             argsString = "('x', (0, 30))";

/*

  These can be set to different values when running the tuning program.  For
  instance, if you wanted to try fifteen argument settings instead of ten,
  you could run the Chapel program like so:

  ```bash
  $ ./tune --numTrials=15
  ```

*/

/*

  Then we define the `combo` type itself.  It stores two fields:
  - `args`, a list of arguments and the value used for this particular combo
  - `result`, which is where the `evaluate` function stores the output from the
    individual run.

*/
record combo {
  var args: list((string, int));
  var result: real;
}

/*

  After defining the configuration constants and the `combo` type, we define the
  `main` procedure.  This procedure starts by parsing the `argsString`
  configuration constant to get the list of argument ranges.  This function
  helps ensure that the user does not have to modify the file itself to tune
  programs other than our toy example.  However, it is a bit esoteric for that
  reason, and so is only provided in the [detail block below](#parseArgSpace).

*/

proc main() {
  var args = parseArgSpace(argsString);
  var target = targetProgram.strip("\"");
/*

  Next, a distributed domain is created with `blockDist.createDomain` and then a
  distributed array of `combo` objects is created with that domain.  Distributed
  domains and arrays enable distributed parallel processing of all kinds,
  including for this tuning program.  The distribution called
  [`BlockDist`](https://chapel-lang.org/docs/latest/modules/dists/BlockDist.html)
  distributes the data in the `combosToCheck` array across locales (nodes) and
  enables any `forall` loop over `combosToCheck` — such as the one in our
  `evaluate` routine above — to create distributed parallel tasks.

*/
  const BlockSpace = blockDist.createDomain({0..<numTrials});
  var combosToCheck: [BlockSpace] combo;

  /* We then call the `randomSampling` procedure to randomly select argument
     values to try, and call the `evaluate` procedure defined above to run the
     target program with the selected argument combinations.  The result of each
     run is saved in the corresponding `combo`.
  */
  randomSampling(args, combosToCheck);

  evaluate(target, combosToCheck);

  /* We then find the best result and print it to the screen (aka `stdout`). */
  var result = findBest(combosToCheck);

  // These five lines are useful output for the user for debugging, but might
  // want to comment out for production runs with a lot of trials.
  writeln("Target program was: ", target);
  writeln("Combos checked were:");
  for currentCombo in combosToCheck {
    writeln(currentCombo);
  }

  writeln("Best found was:");
  writeln(result);
}

/*

  <a name="parseArgSpace"></a>

  {{< details summary="**The `parseArgSpace` function**"  >}}

  The `parseArgSpace` procedure takes the `argsString` configuration constant of
  the form `('x', (0, 30));('y', (10, 50))` and returns a list of tuples where
  the first element in each tuple is an argument name and the second element is
  a tuple of the range of possible values for that argument. For a value of the
  `argsString`, which is "('x', (0, 30));('y', (10, 50))", `parseArgSpace` would
  return a list containing `('x', (0, 30))` and `('y', (10, 50))`.

*/
proc parseArgSpace(argsString: string): list((string, (int, int))) {
  var args = new list((string, (int, int)));
  var argGroups = argsString.split(";");
  for arg in argGroups {
    arg = arg.strip()[1..arg.size-2];
    const argParts = arg.split(",");
    const argName = argParts[0].strip(" \t\r\n("),
          argRangeLow = argParts[1].strip(),
          argRangeHigh = argParts[2].strip(" \t\r\n)");
    const low = argRangeLow[1..].strip(): int,
          high = argRangeHigh[0..argRangeHigh.size-1].strip(): int;
    args.pushBack((argName, (low, high)));
  }
  return args;
}

/*
  {{< /details >}}

  Next is the definition for the `randomSampling` function.  It receives
  an allocated array of `combo` records and the possible range of values
  for each of the arguments to be optimized over while tuning.  It then
  uses the ranges of values to generate a random input for each argument per
  array element, storing that value in the element's `args` field along with the
  argument name.

*/

private var rng = new randomStream(int, seed);

proc randomSampling(optimizableArgs: list((string, (int, int))),
                    ref combosToCheck: [] combo) {

  // Determine the values to try for the arguments
  for currentCombo in combosToCheck {
    // Based on the limits provided in the argument list, determine a
    // value to try for this particular tuning trial
    for (name, (low, high)) in optimizableArgs {
      var val = rng.next(low, high);
      currentCombo.args.pushBack((name, val));
    }

  }
}

/*

  Another procedure called in the `main` procedure is the `findBest` procedure.
  The `findBest` procedure iterates over all the run combinations, returning the
  best combination found.  It does this by using a combination of the
  [minloc
  reduction](https://chapel-lang.org/docs/latest/primers/reductions.html#maxloc-and-minloc-reductions)
  and
  [zippering](https://chapel-lang.org/docs/latest/users-guide/base/zip.html).

*/
proc findBest(const ref combosToCheck: [] combo) {
  const (bestVal, bestIndex) = minloc reduce zip (combosToCheck.result,
                                                  combosToCheck.indices);

  // Return the argument/hyperparameter settings that led to that lowest value
  return combosToCheck[bestIndex].args;
}

/*

  ### Performing Distributed Parallel Tuning

  Since the the above tuning program uses a distributed array of `combo` objects
  and iterates over them using a `forall` loop, it can be run in parallel across
  all the nodes and cores available on a system.  To run the program using
  distributed parallelism, the Chapel compiler and runtime must be built to
  support multi-locale execution (see [Chapel's multilocale
  documentation](https://chapel-lang.org/docs/latest/usingchapel/multilocale.html)
  for instructions), and the `tune` program needs to be executed by passing the
  `-nl` flag to specify the number of locales (compute nodes) to use:

  ```bash
  $ ./tune -nl 4  # run the Chapel program across four compute nodes
  ```

  In the above execution of `tune`, the number of nodes specified is 4, but any
  number could be passed, so long as the system has that number of nodes
  available.  Note that the number of trials (defined in the code as
  `numTrials`) and the number of nodes used interact, which can vary the
  performance of this solution.  We recommend playing around with both the
  number of trials and the number of nodes to determine the combination that
  best works on your system.

  Typically, Chapel will reserve the memory it can on a node.  Because we know
  Chapel will be spawning other tasks, we only want it to use half the memory so
  that the processes we spawn off can use the rest.  This can be accomplished by
  setting the environment variable `CHPL_RT_MAX_HEAP_SIZE` prior to execution.
  E.g.,

  ```bash
  $ export CHPL_RT_MAX_HEAP_SIZE="50%"
  $ ./tune -nl 4 --numTrials=1000000
  ```

  or

  ```bash
  # to only apply it to this program
  $ CHPL_RT_MAX_HEAP_SIZE="50%" ./tune -nl 4 --numTrials=1000000
  ```

*/

/*

  ### Distributed Tuning Used for Hyper-Parameter Optimization

  Hyperparameter Optimization is the process of finding what set of
  hyperparameters (e.g., number of levels, size, etc.) sent to a machine
  learning training algorithm (e.g., neural network, etc.) results in the
  highest accuracy model being produced and/or fastest training time.  This
  means running the same ML training algorithm a LOT of times to search the
  hyperparameter space.  This all takes a lot of time and can be difficult to
  scale.  Scalable performance is something that the Chapel programming language
  excels at.

  You can replace the toy target program with a program of your own, as there are
  no assumptions about the programming language used to write the target
  program, just that the target program is capable of being run from the
  command-line.  For this blog post, we created a polynomial fitting algorithm as
  another target program, see [polyfit.py](polyfit.py) for its description.
  Here is an example of how to run the Chapel tuning program with the polynomial
  fit target program (note that this involves installing `scikit-learn`):


  ```bash
  $ python3 -m venv myenv           # Create virtual environment
  $ source myenv/bin/activate       # Activate on macOS/Linux
  $ pip install numpy scikit-learn  # Install required packages

  $ ./tune --targetProgram="python3 polyfit.py" \
           --argsString="('degree', (2,5));('alpha_order',(-2,2))"
  ```

  If you want to hyperparameter optimize a program of your own, you'll want to
  understand what hyperparameters you want to optimize and how to summarize the
  results of each individual run so that they can be compared accurately.  Also,
  the target program will need to have hyperparameter arguments to tune and to
  output a single result/metric, where smaller is better.  This blog post does
  not go into details about choosing hyperparameters or defining the result
  (which is known as a Figure of Merit), but you can find information on
  choosing hyperparameters from
  [RayTune](https://docs.ray.io/en/master/tune/faq.html#what-are-hyperparameters)
  and in Ben Albrecht's [2019 CHIUW
  talk](https://chapel-lang.org/CHIUW/2019/Albrecht.pdf) on a tool written in
  Chapel called HPO.

*/

/*

  ### Possible Additional Features

  There are a number of ways this `tune` example could benefit from additional
  features, and we encourage anyone interested in seeing these features or
  adding them to contact us on
  [Discourse](https://chapel.discourse.group/c/blog/21) and let us know.  It
  would be great to hear from you and collaborate!

  * Use one of the other distributions already available in Chapel to see if the
    tuning benefits from using a distribution other than `blockDist`.  E.g., the
    [cyclic
    distribution](https://chapel-lang.org/docs/latest/modules/dists/CyclicDist.html)
    might lead to a more even balance of subprocesses.  The number of code
    changes needed to use these other distributions is minimal, only two lines.

  * Instead of iterating over the `combosToCheck` array itself and relying on its
    distribution to balance the subprocesses, you could use one of the dynamic
    load balancing iterators in the
    [`DistributedIters`](https://chapel-lang.org/docs/latest/modules/packages/DistributedIters.html)
    package to ensure that all nodes are kept busy with work.

  * Put the randomly selected argument space values in a set so that the target
    program is not run the same way more than once.

  * Implement other ways to select argument space values, or potentially use
    the results of previous target program runs to guide the search.

  * Enable different argument types.  Currently only integer arguments are
    handled.

  * Rewrite a target program you have in Chapel so that lower levels of
    parallelism, such as vector or GPU parallelism, can be leveraged and the need
    to `exec` a subprocess is eliminated.

*/

/*

  ### Summary

  This article shows how you can use Chapel to run a distributed tuning computation in
  parallel.  The example program shown can be copied and adapted to do whatever
  kind of tuning computation you would like on whichever cloud, cluster,
  or supercomputer you have access to.

  Thank you for reading this blog post, and feel free to make comments or ask
  questions by creating a thread in the [Chapel Blog Discourse
  Category](https://chapel.discourse.group/c/blog/21).  We especially look
  forward to hearing all the cool ways people use this tuning program to tune or
  hyperoptimize their own target programs.

  ---

  _The authors would like to thank Ben Albrecht and the HPO/CrayAI
  team, who inspired this article with their more extensive HPO
  implementation._


  ### Updates to this article

  {{< changetable >}}
  | Date         | Change                                                      |
  |:-------------|:------------------------------------------------------------|
  | Oct 11, 2024 | Updated to strip leading and trailing parens from arguments |
  | Oct 14, 2024 | Updated to strip quotes from test program name              |

  */
