// Advent of Code 2022: Wrap-up
// authors: ["Brad Chamberlain"]
// summary: "A summary of our twelve days of AoC 2022 and a peek at some of Chapel's distributed programming features"
// tags: ["Advent of Code"]
// series: ["Advent of Code 2022"]
// date: 2022-12-20


/*

  Having introduced the Chapel language using the first twelve days of
  AoC 2022 exercises, this completes our _Twelve Days of Chapel:
  Advent of Code 2022_ winter spectacular.  Of course, Advent of Code
  2022 is still going on, but we're going to take a break as we head
  into winter shutdowns, holiday vacations, and the like.  If a
  specific exercise from days 13–25 catches our interest, and time
  permits, we may post additional AoC 2022 articles next month, but
  we'll see...  We also have other plans for posts and series in the
  coming year.

  Over these first twelve days, we managed to use a lot of Chapel
  features and find plenty of opportunities for parallel computation,
  both of which should give you enough material to either be effective
  or dangerous with the language, depending on how successful we were.
  In either case, please feel free to ask follow-up questions using
  the channels noted at the bottom of this article.

  That said, because Advent of Code focuses on desktop-ready
  computations, we never really had the chance to see Chapel's
  features supporting distributed parallel computing, which is its
  whole reason for existing.  In this article, we'll wrap up with a
  quick preview of such features, introducing them in the context of
  some computations we've already seen.

  ### Summary of This Series

  First though, let's summarize the main features that we used in this
  series and where they were introduced:

  * [Introduction: Advent of Code 2022: Twelve Days of Chapel]({{< relref "aoc2022-day00-intro" >}})
    * introduction to Advent of Code
    * compiling and running Chapel programs

  * [Day 1: Counting Calories]({{< relref "aoc2022-day01-calories" >}})
    * basic Chapel syntax
    * modules and using their contents (`use`)
    * declarations of variables (`var`) and constants (`const`)
    * type specifications and casts (`: t`)
    * type inference
    * conditionals and `do`...`while` loops
    * reading lines from, and writing them to, the console (`readLine()` and `writeln()`)

  * [Day 2: Rochambeau]({{< relref "aoc2022-day02-rochambeau" >}})
    * declaration order and visibility
    * concrete enumerated types (`enum`) and `use` of enums
    * procedure declarations and instantiation of generic arguments
    * iterators (`iter`) and the `yield` statement
    * sequential `for` loops and index variables
    * tuples, tuple types, and de-tupling
    * sum reductions (`+ reduce`)
    * formatted console input with `readf`
    * the `string` type
    * inferred-size arrays
    * promotion of scalar procedures using array arguments
    * stopping an erroneous program early with `halt()`

  * [Day 3: Rucksack Comparisons]({{< relref "aoc2022-day03-rucksacks" >}})
    * Chapel program structure and module initialization
    * `forall` loops and their relation to promotion
    * task intents
    * range values and open-interval ranges
    * the `bytes` type and values
    * slicing `bytes` values
    * the `set` type
    * unsigned integers and bit widths (`uint(8)`)
    * compile-time `param` values
    * the `break` statement
    * race conditions

  * [Day 4: Finding Overlaps in Cleanup Ranges]({{< relref "aoc2022-day04-ranges" >}})
    * problem-solving strategies
    * range intersection via slicing
    * range subset queries (`contains()`)
    * more formatted I/O with `readf()`

  * [Day 5: Stacking Crates]({{< relref "aoc2022-day05-cratestacks" >}})
    * the `list` type and its `pop()`, `append()`, and `last()` methods
    * abstract `enum` types and printing enums
    * typed array declarations (`: [indices] eltType`)
    * strided ranges and unbounded ranges
    * reference (`ref`) declarations
    * zippered iteration

  * [Day 6: Packet Detection]({{< relref "aoc2022-day06-packets" >}})
    * `config` declarations
    * named range declarations
    * the count operator (`#`)
    * parallel loop expressions (`forall` and `[indices in iterands] expr`)
    * range translation via `+`
    * the `maxloc` reduction (`maxloc reduce`)
    * ignoring tuple elements using `_`

  * [Day 7: Traversing Directories]({{< relref "aoc2022-day07-dir-traversals" >}})
    * classes (`class`)
    * `owned` classes and memory management
    * fields, methods, and type methods
    * creating class instances with `new`
    * the `map` type
    * string slicing
    * string `startsWith()` and `partition()` methods
    * recursion and recursive iterators
    * min reductions (`min reduce`)
    * conditional expressions for filtering

  * [Day 8: Hiding Treehouses]({{< relref "aoc2022-day08-treehouse" >}})
    * locally scoped module `use`s
    * multidimensional arrays and indexing them
    * domain values
    * operator promotion using arrays
    * array slicing and rank-change slices
    * logical 'and' reductions (`&& reduce`)

  * [Day 9: Elvish String Theory]({{< relref "aoc2022-day09-elvish-string-theory" >}})
    * index-free `for` loops
    * the `select` statement
    * the absolute value (`abs()`) and sign (`sgn()`) routines

  * [Day 10: Scan Lines]({{< relref "aoc2022-day10-crt" >}})
    * the `lines()` iterator
    * the `strip()` method on strings
    * scan expressions (`scan`)
    * reshaping arrays (`reshape`)

  * [Day 11: Monkeying Around]({{< relref "aoc2022-day11-monkeys" >}})
    * task-parallelism vs. data-parallelism
    * mapping Chapel tasks to threads and processors
    * the `coforall` loop and its distinctions from `forall`
    * barrier synchronization
    * cooperative multitasking and livelock
    * double-buffering
    * returning by reference (`ref`)
    * the swap operator (`<=>`)
    * synchronization variables (`sync`) and their access methods
    * secondary methods
    * implicit conversions from `bool` to `int`
    * class hierarchies, parent classes, and subclasses
    * dynamic dispatch
    * class initializers (`init`)

  * [Day 12: On the Summit]({{< relref "aoc2022-day12-summit" >}})
    * recursive tree searches in parallel
    * `const ref` argument intents
    * argument queries (`?d`)
    * atomic variables (`atomic`)
    * operations on atomics (`read()`, `compareExchange()`)
    * labels and labeled `break` statements


  ### Chapel's Support for Scalable Distributed Computing: A Preview

  As mentioned above, it isn't terribly surprising that we didn't
  encounter Chapel's support for distributed memory computing in this
  series given AoC's focus on desktop computing.  Since scalable
  parallel computing is Chapel's reason for existing, you can expect
  to see future articles on this blog cover those aspects of the
  language in more detail.  However, let's touch on the topic briefly
  before wrapping up this series.

  #### Chapel's Locales and their Role in Supporting Distributed Parallelism

  A crucial feature for understanding distributed computing in Chapel
  is the
  [_locale_](https://chapel-lang.org/docs/language/spec/locales.html).
  Locales are a type built into the language for representing a
  portion of the target architecture that can run tasks and store
  variables.  Since that describes a CPU and its memory, your laptop
  could serve as a locale.  In fact, all of the programs written in
  this series would be considered _single-locale_ Chapel programs
  since nothing about them has referred to other locales, either
  explicitly or implicitly.  Systems like clusters, the cloud, or
  supercomputers are considered _multi-locale_ systems for Chapel,
  where each compute node could be considered a distinct locale.


  #### Data Parallelism Using Distributed Domains and Arrays

  One of the simplest ways to get started with multi-locale computing
  in Chapel is through its support for _distributed arrays_.  These
  are identical to the arrays we've seen in this series, except that
  rather than storing all of their elements in a single locale's
  memory, they are distributed across multiple locales.

  Looking back at [day 8's
  computation]({{< relref "aoc2022-day08-treehouse" >}}),
  recall that we used a 2D array to find ideal treehouse locations.
  If desired, we could have distributed the elements of this array
  across the memories of multiple compute nodes, giving each of them a
  chunk of the total array.  And for a forest that was large enough,
  this could be a way to run larger problem sizes or to achieve better
  performance.

  To see how this would be done, we could change the 2D domain
  _ForestSpace_ from its original declaration:

  ```chapel
  const ForestSpace = {0..<numRows, 0..<numCols};
  ```

  to this one that uses the
  [`Cyclic`](https://chapel-lang.org/docs/modules/dists/CyclicDist.html)
  distribution for arrays:

  ```chapel
  use CyclicDist;  // we need to use the 'Cyclic Distribution' module

  const ForestSpace = {0..<numRows, 0..<numCols} dmapped Cyclic(startIdx=(1,1));
  ```

  Doing so has the effect of distributing the indices of the
  `ForestSpace` domain across the compute nodes of the target system
  in a round-robin fashion in both of its dimensions.  The `Forest`
  array declared in terms of `ForestSpace` would be similarly
  distributed, such that each locale would store `1/numLocales` of the
  array elements.  And then the subsequent loops or slices over
  `Forest` would result in parallel computation across all of the
  locales owning the indices in question.

  Thus, by `use`-ing one additional module and changing just one line,
  we have turned our desktop AoC code into one that could target all
  of the processor cores and memories of a supercomputer.  This is an
  example of distributed data parallelism in Chapel since it leverages
  Chapel's data-parallel features—its domains, arrays, promotion, and
  `forall` loops—to target multiple locales.  Like the data-parallel
  examples we've seen in this series, it represents a high-level way
  of doing distributed computing in Chapel.


  #### Explicit Distributed Computing Using `on`-clauses

  We can also target multiple locales at a lower level using an
  [`on`&nbsp;statement](https://chapel-lang.org/docs/language/spec/locales.html#the-on-statement)
  (or _on-clause_ for short).  This can be thought of as a more
  explicit way of doing distributed computing in Chapel, similar to
  how Chapel's task-parallel features were shown in this series to give
  us lower-level, more explicit control than its high-level
  data-parallel features.

  In our [day 11]({{< relref "aoc2022-day11-monkeys" >}}) article, you
  may recall that the first task-parallel program I introduced was
  this one:

  ```chapel
  coforall tid in 1..4 do
    writeln("Hello from task ", tid);
  writeln("After the coforall");
  ```

  Using the on-clause and one additional `coforall` loop, we can turn
  this from a 4-task, single-locale program into a multi-locale
  program:

*/

  coforall loc in Locales do
    on loc do
      coforall tid in 1..4 do
        writeln("Hello from task ", tid, " on locale ", loc.id);

  writeln("After the coforalls");

/*

  Here, I'm iterating over a built-in array, `Locales`, which
  represents the set of locales on which my program is running.  If I
  specified that I wanted to run my program on 16 locales, or compute
  nodes, by using the command line:

  ```bash
  $ ./hello-coforall --numLocales=16
  ```

  then the array would have 16 elements, one per node.  The `coforall`
  will then create a task per element in that array, so 16 tasks in
  this example, one per locale.  Each task will have its own index
  variable `loc` that refers to its specific locale.  Next, the
  `on`-clause says to run the code that it encloses on that specific
  locale.  At this point, I'd have one task running on each of the 16
  compute nodes from my distributed system.

  Next, each of those tasks encounters the inner coforall, which
  causes it to create four tasks, mapping them to four local cores on
  that compute node / locale.  And each of those tasks prints a
  message like before.  Note that I've added some more arguments to
  the message to make it unique on each locale.  Specifically, I'm
  using the `.id` query supported by the locale type to get that
  locale's ID from `0..<numLocales`.

  So, when running on 16 locales, we'd see 64 messages printed to the
  console.  As in the original shared-memory version, these messages
  would print in an arbitrary order since there is no coordination or
  synchronization between the tasks.  As the tasks complete, they will
  'join' back together at the ends of their respective `coforall`
  loops, and the original task that kicked the rest of them off would
  print the final message, "After the coforalls".

  ### Conclusion

  Over the course of this "Twelve Days of Chapel" series, we've
  introduced a big cross-section of the features supported by the
  Chapel language.  And in this article, you've seen the basis for
  Chapel's distributed computing features: locales, distributed
  arrays, and `on`-clauses.  We hope that this brief taste of
  distributed computing in Chapel will whet your appetite to learn
  more about its features for scalable parallel computing beyond the
  desktop parallelism introduced in this series.  And we'll be coming
  back to these concepts more in future blog articles and series.
  Meanwhile, whether you've got supercomputer-sized problems to solve,
  or simply parallel computations you'd like to write on your laptop,
  you've now got a good start on how to express them in Chapel.

  We'll be continuing this blog with new articles and series in 2023,
  and may return with another Advent of Code series in December next
  year.  Until then, we hope that you've enjoyed this series.  Please
  let us know of any follow-up questions or comments you might have in
  the [Blog](https://chapel.discourse.group/c/blog/) category of
  Chapel's Discourse page, or on any of the [other communication
  mechanisms](https://chapel-lang.org/community.html) we support for
  the community.

  With best wishes for the new year,

  -[Brad]({{< relref "brad-chamberlain" >}}), [Daniel]({{< relref "daniel-fedorin" >}}), [Jeremiah]({{< relref "jeremiah-corrado" >}}), and [Michelle]({{< relref "michelle-strout" >}})

*/
