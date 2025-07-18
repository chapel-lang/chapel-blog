// Advent of Code 2022, Day 11: Monkeying Around
// authors: ["Brad Chamberlain"]
// summary: "A parallel solution to day eleven of AoC 2022, using Chapel's task parallel features."
// tags: ["Advent of Code", "How-To"]
// series: ["Advent of Code 2022"]
// date: 2022-12-17

/*

  Welcome to part 11 in our 'Twelve Days of Chapel' Advent of Code
  2022 series.  If you're new to the series, take a look at the
  [introductory article]({{< relref "aoc2022-day00-intro" >}}) for
  background on what we're doing.

*/

/*

  ### Today's Task and My Approach to it

  [Today's challenge](https://adventofcode.com/2022/day/11) involves
  simulating a troop of monkeys as they inspect and throw our precious
  items amongst themselves using a fairly obtuse pattern defined by
  an input file.  Our goal is to count the number of items each
  monkey inspects and to multiply the two highest counts together.

  Using the description on the AoC site, the problem statement for
  this challenge sounds inherently sequential: It talks in terms of
  each monkey taking a turn, one after another, until each has had a
  turn, completing a round.  It also talks about having the monkeys
  inspect the items one at a time.  If implemented literally, there
  would be no way to compute this algorithm in parallel.  So is there
  anything unique that Chapel can bring to the table today?

  As it turns out, yes.  As is often the case in parallel programming,
  there _is_ a parallel approach to the problem if we focus on _what_
  we are being asked to compute rather than _how_ we are being told to
  compute it.  Specifically, since the operations that determine where
  a monkey throws a given item only depend on that item's value and
  not on its relationship to other items (like its order in a list),
  we can inspect and throw the items in any order we wish as long we
  we keep accurate counts of those items.  As an example, each monkey
  could inspect the items it is holding in parallel using a `forall`
  loop due to the independence of the items' values.

  Throwing the items is another matter, however.  If a monkey uses a
  parallel loop to inspect its items, since there are only two monkeys
  it will throw the items to, it's quite likely that it will throw
  multiple items at another monkey simultaneously.  For that reason,
  it is essential that we have some _parallel-safe_ way of catching
  those thrown items.  In this program, I use Chapel's standard `list`
  collection in its parallel-safe mode to accomplish this.

  There's actually another way to execute this program in parallel
  beyond using a `forall` loop to process each monkey's items.
  Namely, we can simulate the monkeys themselves in parallel.  We can
  create a task per monkey and have those tasks execute for the
  duration of the rounds of the game, inspecting items and throwing
  them to other monkeys' tasks.  In this approach, each monkey
  performs its work sequentially, but all of the monkeys execute
  concurrently in a loosely synchronous fashion.  I ended up taking
  this approach for today's article for two reasons:

  1. The monkeys' item lists are not very large in practice.  As a
     result, spinning up the tasks required to implement a `forall`
     loop only to have each task compute a small number of items felt
     like too much overhead.  The Chapel program would spend most of
     its time creating and destroying tasks rather than computing with
     them.  If the monkeys' item lists had been much longer, the
     `forall`-based approach may have seemed more viable.

  2. Creating a task per monkey permits me to introduce you to some of
     Chapel's _task-parallel_ constructs.  Task parallelism is
     well-suited for this type of simulation, and we have not used it
     yet in this series.  Up until now, we've been using high-level
     _data-parallel_ constructs such as promotion and `forall` loops.
     In contrast, Chapel's _task parallel_ features can be considered
     a lower-level and more explicit way of doing parallel computing.
     That said, you may still find that these features feel very
     high-level compared to how threading and synchronization are
     expressed in conventional performance-oriented languages.

  For these two reasons, my approach is to execute each monkey as a
  distinct, independent task, inspecting and throwing its items at its
  own pace.  The key to adhering to the turn and round structure
  described in AoC's sequential version of the algorithm is to have
  each monkey throw items differently depending on whether the target
  monkey precedes it or follows it in the turn order.

  Specifically, I give each monkey _two_ lists of items, one
  representing those it must process in this round, and a second
  representing those intended for the next round.  When one monkey
  throws an item to another whose turn precedes it, it will throw it
  into the list for the next round; whereas when the monkey throws an
  item to another whose turn follows it, it will throw it into its
  list for this round.  This can be viewed as a form of [double
  buffering](https://en.wikipedia.org/wiki/Multiple_buffering).

  That's the high-level idea anyway.  There will definitely be
  additional details to cover as we go.

  **If you like eating the icing of your cupcake first, here's my approach to today's challenge:**
  {{< whole_file_min >}}


  ### Data Parallelism vs. Task Parallelism

  The `forall` loops that we've used up to now in this series are
  considered to be part of Chapel's _data-parallel_ features.  They
  are typically used to perform the same computation many times in
  parallel for the items of a data set—like the elements of an array
  or collection, or the indices of a range or domain.  Promotion is
  another form of data parallelism, since it is defined in terms of
  forall-loops.

  As mentioned on [day 3]({{< relref
  "aoc2022-day03-rucksacks#forall-loops-and-task-intents" >}}), a key
  property of the forall-loop is that its iterations can be executed
  in any order.  This means that `forall` is not appropriate for
  computations in which parallel tasks must interact with each
  other—like monkeys throwing items to one another.  The reason is
  that the synchronization between distinct tasks tends to rely on
  them running simultaneously or in a given order—two things that
  `forall` does not guarantee.

  In contrast, _task-parallel_ features in Chapel are those in which
  the programmer explicitly defines tasks that are to be executed in
  parallel, including what those tasks should compute and how they
  should coordinate and synchronize with one another.  Parallel tasks
  can be created in Chapel using one of three language constructs:

  * the `coforall` loop
  * the `begin` statement
  * the `cobegin` statement

  All coarse-grained parallelism within Chapel is implemented using
  one of these three features.  Sometimes this is done by using them
  directly; other times, it's done indirectly—for example, by
  executing a `forall` loop whose iterand's parallel iterator uses
  them.

  In this article, I'll be creating tasks using the `coforall` loop.
  But before getting there, let's talk a bit more about how tasks are
  executed in Chapel.

*/

/*

  ### Tasks, Threads, and Processors

  In this series, we've talked a bit about tasks, threads, and
  processors in passing, like when introducing `forall` on [day 3]({{<
  relref "aoc2022-day03-rucksacks#forall-loops-and-task-intents" >}}).
  Now that we're doing a task-parallel computation with explicit
  synchronization, let's get a bit more precise and introduce some
  terminology that I'll be using today.

  Chapel's specification is intentionally vague about precisely how
  tasks are executed.  This is done to permit the language to map to
  various parallel architectures without making too many assumptions
  about what they will or will not be able to handle.  In practice,
  the details of tasks' implementations are controlled primarily by
  the (set or inferred) value of the `CHPL_TASKS` environment
  variable.  In this discussion and article, I'll be focusing on
  Chapel's preferred configuration, `CHPL_TASKS=qthreads`, which is
  the default on most platforms.

  All Chapel tasks are ultimately implemented by the hardware's
  processors, such as the multiple _cores_ of a modern CPU.  These
  cores execute _system threads_, typically [_POSIX threads_
  (_pthreads_)](https://en.wikipedia.org/wiki/Pthreads), which serve
  as vehicles for computation.  In Chapel's default configuration, its
  runtime creates a pthread per core, _pinning it_ to that core for
  performance reasons.  When Chapel features like `forall` or
  `coforall` loops introduce new tasks, they can be mapped down to the
  pthreads in a variety of ways that aren't necessary to understand
  here.  Whatever mapping is used, some key properties include:

  * each pthread can only execute one task at a time
  * there can be more tasks than there are pthreads or cores
  * when there are, they will necessarily need to take turns running

  In the default configuration, tasks run using [_cooperative
  multitasking_](https://en.wikipedia.org/wiki/Cooperative_multitasking).
  This means that a task keeps running on its thread and core until it
  {{< sidenote "right" "yields" >}}Note that
  this is a different use of the term 'yield' than we've seen
  previously in this series.  Iterators use the `yield` statement to
  return one or more values back to their callsites.  This use of
  'yield' differs, referring to having a task get out of the way so
  that another task can use its processor.{{< /sidenote >}} those
  resources, permitting another task to take a turn with them.  This
  is done for performance reasons, since switching between tasks too
  frequently can add overheads that could slow down execution.

  Many low-level, high-latency Chapel operations have such task yields
  built into them to help ensure that tasks make progress and don't
  get stuck waiting for resources.  For example, some Chapel
  operations are said to _block_ a task, meaning that the task will be
  stuck until some external event occurs.  This is an obvious time for
  that task to yield its processor since it can't immediately proceed
  anyway.  Moreover, by yielding, it may permit a task to run whose
  actions will un-block it.  This is ultimately to its benefit as well
  as to the program's as a whole.

  Despite the fact that task yields are built into several Chapel
  features, when doing explicit task-parallel programming, a user can
  definitely create problems for themselves if they are not aware of
  how their tasks use the system resources.  For example, if each of
  the tasks currently running on the cores's pthreads were to reach an
  infinite loop in the program, like:

  ```chapel
  while true {
  }
  ```

  they would effectively _starve_ the other tasks in the program since
  they are not yielding their processors, and therefore are preventing
  other tasks from getting the chance to run.

  In practice, such errors are often caused by cases that are not as
  simple or obvious as this one.  More likely, the tasks are waiting
  for something to happen without yielding the processor, thereby
  preventing other tasks that would cause that "something" to occur
  from running.  In one of my early drafts of today's program, I had
  such a bug, in which I had 8 tasks running on my 4-core laptop.  The
  tasks that were running were all waiting on events from the ones
  that were not; yet they were also not yielding, so my program would
  get stuck.  This is a condition known as _livelock_ in that tasks
  are running, yet no computational progress is being made.

  Now that we've covered that background material, let's start looking
  at some code:

*/

/*

  ### Using Modules and Configuring Rounds

  My program starts, as most in this series have, with a `use`
  statement indicating the modules whose features I'll be relying on
  today:

*/
  
use IO, List, Collectives;

/*

  `IO` is a module we've used daily in this series, and here I'll need
  it once again to read and parse our input file.  As seen in some
  previous articles, the `List` module provides the `list` collection
  that I'll use for maintaining the monkeys' items.  I'm also using
  the `Collectives` module, which is new in this article.  It provides a
  way for a number of tasks to synchronize with one another using
  _barrier synchronization_.  I'll explain these barriers in more
  detail once we reach their use cases in today's code.

  I also declare a `config const` here at the outset to specify the
  number of rounds in our monkey simulation.

*/

config const numRounds = 20;

/*

  As we've seen in other programs, this allows me to change the number
  of rounds for a given execution of the program from its default of
  `20` using the command-line flag Chapel provides for `config`s.  For
  example, I could run 10,000 rounds, as in part two, using:

  ```bash
  $ ./day11 --numRounds=10000`
  ```

  This `config` permits me to change how my program runs with no edits
  to the program text, no need to recompile, and no manual argument
  parsing.

*/

/*

  ### Defining our Monkeys as Classes

  Next, I'll define a class named `Monkey` that stores all of the
  state that I need to associate with each of our monkeys.

  #### Constant Monkey Fields

  I start by declaring my `Monkey` class and its constant fields,
  which will be invariant across the monkey's lifetime:

*/

class Monkey {
  const id: int,
        op: owned MathOp,
        divisor: int,
        targetMonkey: 2*int;

/*

  The first field is the monkey's `id`, as given in the input file,
  numbered from 0.

  Next, I declare an `op` field, which is an `owned` instance of an
  parent class named `MathOp`.  We'll look at `MathOp` and its
  subclasses a bit later in the article, but for now, know that they
  will implement the monkey's individual operations, like adding six
  to an item's value, or squaring it.  We saw classes on [day 7]({{<
  relref "aoc2022-day07-dir-traversals#memory-management-strategies"
  >}}) and learned that `owned` is a memory management strategy in
  which a single variable _owns_ a class object at any given time.
  When that owner is de-allocated, so is the class.  In this case,
  each monkey has its own unique math operation, so having it 'own'
  the class representing that operation is a natural approach.

  The third field is `divisor`.  This represents the integer value the
  monkey will use to check an item's divisibility when determining who
  to throw it to next.  For example, in the sample input, the first
  monkey's divisor is `23`.

  Finally, I declare `targetMonkey`, which is a 2-tuple storing the
  `id`s of the two monkeys that this one will throw items to,
  depending on whether or not their worry level is divisible by
  `divisor`.

  #### Variable Monkey Fields

  Next, let's look at the variable fields in my `Monkey` class:

*/

  var items: [0..1] list(int, parSafe=true),
      current = 0, next = 1,
      numInspected: int;

/*

  The first is `items`, which is a 2-element array of lists.  Its
  elements are used to implement the double-buffering strategy
  mentioned above: one of the lists will store the items that the
  monkey needs to process in the current round, and the other will
  store those that it needs to process in the next one.  Because our
  items are represented as integers, I declare the list types as
  `list(int, ...)` to indicate that they store `int` values.  I also
  provide an additional argument to the type signature,
  `parSafe=true`.  This opts in to an implementation of the list that
  is designed to support concurrent operations.  For example, this
  makes it safe for multiple monkeys to add items to a list
  simultaneously, or for a monkey to remove items from its list
  while others are adding new ones.

  Next up are two integers, `current` and `next`.  These are used to
  indicate which of the two lists represents the items to be processed
  in the current round, and which stores the items for the next.  From
  one round to the next, we will swap the values of these two
  variables so that list `0` will store the first round's items, list
  `1` will store the second round's, then back to list `0` for round
  three, and so on.

  The final field in `Monkey` is used to store the number of items
  that monkey inspects.  This will be used to compute our final result
  at the end of the program.

*/

/*

  #### Monkey Methods for Item Lists

  Before getting to the parallel simulation, I also define a few
  methods to help manage and abstract away the monkey's item lists.
  The first two methods hide the details of the double-buffering,
  returning the lists representing the current, and next, rounds'
  items, respectively:

*/
 
  proc currentItems() ref {
    return items[current];
  }

  proc nextItems() ref {
    return items[next];
  }

/*

  Note that these methods have a `ref` keyword after their argument
  list.  This indicates that they will return a reference to the
  expression being returned rather than its value.  In this case,
  rather than returning a copy of the list in question, they permit
  the callsite to refer directly to the original list.  The callsites
  could simply refer to `items[current]` and `items[next]` directly,
  but by creating these methods, I give myself the ability to change
  the representation of the double-buffered lists without modifying
  the simulation code at the callsites.

  The final list-related method will be used between rounds to swap
  the current and next list indices such that the 'next' list of items
  becomes the 'current' one and the 'current' becomes the next:

*/
  
  proc swapItems() {
    current <=> next;
  }
}

/*

  This method uses an operator that we haven't seen yet, the _swap
  operator_ (`<=>`).  It can be considered a shorthand for the typical
  way of swapping two values:

  ```chapel
  const tmp = current;
  current = next;
  next = tmp;
  ```

  Besides being a more concise way of expressing the swap, using the
  swap operator can also enable optimized swap implementations for
  more complex data types, such as arrays.

*/

/*

  #### Creating our Troop of Monkeys

  Now that I've defined a class representing a single monkey, let's
  create a whole troop of them.  Here, I'm using the time-honored
  technique in this series of invoking an iterator, `readMonkeys()`,
  which reads the input file, yielding an unknown number of `Monkey`
  objects back to me, which I then store in an array named `Monkeys`:

*/

const Monkeys = readMonkeys(),
      numMonkeys = Monkeys.size;

/*

  Though the fields within my `Monkey` classes will change as the
  program runs, the identities of those classes will not, so I declare
  `Monkeys` to be `const`.  I then query the size of the `Monkeys`
  array and store the result in another constant, `numMonkeys`, as a
  convenience.

  The I/O for today's puzzle is the most challenging we've seen yet
  for AoC 2022.  I'll show how I approached it towards the end of this
  article because I'd rather focus on task-parallel programming in
  Chapel than teaching you to become a master of parsing input data
  (not that I'm a master myself).

*/

/*

  ### Simulating Monkeys Using Task Parallelism

  Now that I've defined how a single monkey is represented and have
  created a troop of monkeys, I'm ready to set the parallel simulation
  in motion using task-parallel concepts.

  #### Chapel's `sync` variables

  In Chapel, when tasks need to coordinate with one another, the
  safest way to do so is by accessing `sync` or `atomic` variables
  that are declared in a scope that is visible to the tasks in
  question.  In today's article, I've decided to use `sync` or
  [_synchronization_
  variables](https://chapel-lang.org/docs/builtins/ChapelSyncvar.html).
  We'll see examples of `atomic` variables in our day 12 article.

  In Chapel, the `sync` variable has several unique properties.  The
  most significant is that, in addition to its normal value, it stores
  a full/empty bit which says whether that value is valid or not.
  Reads and writes to synchronization variables are done through
  methods, and these methods indicate what state the full/empty bit
  must be in for the operation to proceed.  If the bit is not in that
  state, the task attempting the read or write will _block_, allowing
  other tasks to execute instead.  Though this is a very important
  property of `sync` variables, it isn't one I'll be using today
  because I don't want my monkeys to spend their time blocking when
  they could be processing items thrown to them from another monkey.

  I do rely on some other properties of `sync` variables.  One is that
  certain methods on `sync` variables cause the task performing the
  call to _yield_ its processor to another task.  This is crucial when
  you want to simulate more monkeys than there are processors on your
  system, since a monkey that fails to yield will hog its thread and
  processors, potentially preventing other monkeys from making crucial
  progress.  This relates to the bug in an early draft of my program
  that I mentioned earlier:

  In my program, I was running eight monkey tasks on four processors
  without performing any operations that would yield the processors.
  As a result, I ended up in a livelock situation: The monkeys that
  were running were waiting for more items to inspect, or to be told
  that it was safe to end their turn; but the monkeys who could give
  them those items or information were not running on a processor.  As
  a result, the monkeys whose tasks were running would wait forever
  (or, really, until I killed the program).  Using synchronization
  variables to coordinate between the monkeys fixed this problem since
  the `sync` variable accesses I used caused the monkeys' tasks to
  yield.

  Another key property of `sync` variables is that accesses to them
  imply a _memory fence_.  At a high level, this means that all memory
  operations that were started before a read or write to the `sync`
  variable are guaranteed to be written to memory before the `sync`
  operation is performed.  This is important due to Chapel's [_memory
  consistency
  model_](https://chapel-lang.org/docs/language/spec/memory-consistency-model.html)
  which is a very advanced topic that I won't be covering in today's
  article.  Suffice it to say, these memory fences make `sync`
  variables a very safe way to coordinate between tasks.

  #### Tracking Turns Using a `sync` variable

  Given that long introduction, here is my `sync` variable for this
  program, `canFinishTurn`:

*/

var canFinishTurn: sync int = 0;

/*

  This variable is used to keep track of the monkeys' turns within a
  round.  Specifically, a challenge in my task-per-monkey model is
  that when a monkey is processing the items in its list and has
  emptied it, it's not obvious whether its turn for this round is over
  or whether, once it waits a bit longer, some other monkey will throw
  it another item to process.  This synchronization variable is
  designed to answer that question.

  Specifically, remember that—due to the problem statement's
  sequential nature—a monkey only needs to process items during the
  current round if they were thrown to it by a monkey whose turn
  preceded it—that is, a monkey with a lower ID.  As a result, from
  the start of a round, monkey 0 knows that nobody else can throw
  items for it to process in this round since it is the first monkey.
  If any items _are_ thrown to it, they will be stored in its list of
  items for the _next_ round.  Thus, when monkey 0's list of current
  items is empty, it knows that it's done with its turn and this
  round.

  Recursively, once monkey 0 is done with its turn, no other monkeys
  can throw items for monkey&nbsp;1 to handle during this round,
  because only monkey 0 preceded it in the turn order.  And once
  monkey 1 is finished, nobody will be able to throw new items to
  monkey 2.  And so on.

  So, the synchronized `canFinishTurn` variable is essentially a
  shared way for the monkeys to know whether or not it is OK for them
  to finish their turn when their item list is empty—that is, whether
  it is guaranteed that no new items will show up needing to be
  processed in this round.  Since this is initially true only for
  monkey 0, I initialize `canFinishTurn` to 0.  As we will see a bit
  later on, when each monkey finishes its turn, it increments the
  value of this synchronization variable, permitting the monkey that
  follows it to end its turn once its item list is empty, and so
  forth.

  One final note on this declaration: Recall that `sync` variables
  store a full/empty bit in addition to their value (the `int`
  represented by a `sync int` in this case).  When a `sync` variable
  has an explicit initializer, like the `= 0` in my declaration, that
  causes its full/empty bit to be initialized to the 'full' state.
  If it does not have an initializer, as in this declaration:

  ```chapel
  var canFinishTurn: sync int;
  ```

  its full/empty bit is set to 'empty'.  Since I initialized
  `canFinishTurn` in my program, it will be 'full' to start out (and,
  in fact, will remain 'full' for the duration of the program).

  #### Declaring a Barrier for Coordinating Monkeys

  A common form of synchronization in parallel programming is _barrier
  synchronization_.  This introduces a point in the program where all
  tasks participating in the barrier must pause and wait for all other
  participating tasks to also reach the barrier.  Only after all the
  tasks have arrived can they all proceed past the barrier.

  We'll use barriers a bit later in our computation, but to do so,
  we need to declare a variable representing the barrier now:

*/

var bar = new barrier(numMonkeys);

/*

  This declares an instance of the `barrier` type defined by the
  `Collectives` module we `use`d at the program's outset.  It takes an
  integer argument indicating the number of tasks that will
  participate in the barrier.  Because I will create a task per
  monkey and will want them all to participate in the barrier
  synchronization, I passed in `numMonkeys` as that value.

*/

/*

  #### Chapel's `coforall` Loops

  At last, we are ready to create our monkey tasks.  To do this, I'm
  using Chapel's _coforall loop_.  The `coforall` is similar to the
  `for` and `forall` loops that we've seen before, in that it can
  iterate over one or more iterand expressions, binding the values
  yielded by those expressions to loop index variables.  However,
  where the `for` loop executes its iterations sequentially using a
  single task and the `forall` loop executes them using whatever tasks
  its parallel iterator specifies (typically equal to the number of
  processor cores available to the loop), the `coforall` loop creates
  a distinct task for every one of its iterations.

  As a simple example of `coforall` loop, consider this code:

  ```chapel
  coforall tid in 1..4 do
    writeln("Hello from task ", tid);
  writeln("After the coforall");
  ```

  Because iterating over this range yields four indices, the
  `coforall` will create four tasks, one for each iteration.  Each
  task gets its own `tid` variable with a unique value from `1`
  through `4`.  Each task executes its own copy of the loop body,
  printing a unique greeting.  Because the tasks are all executing
  concurrently and not synchronizing, the messages could appear on the
  console in any order.

  One other property of the `coforall` loop is that the task which
  encounters the loop and spawns the per-iteration tasks will not
  proceed past the loop until those tasks have all completed executing
  their loop bodies.  Thus, in the example above, though the order of
  the per-task messages is nondeterministic, the message "After the
  coforall" is guaranteed to print only after the four tasks have
  printed their messages and completed running.  Here is the output
  from a sample compile and run of this program:

  ```bash
  $ chpl hello-coforall.chpl
  $ ./hello-coforall
  Hello from task 2
  Hello from task 1
  Hello from task 3
  Hello from task 4
  After the coforall
  ```

  Running again, we might see the first four lines printed in a
  completely different order, but the fifth will always be last.

  {{< details summary = "**(When should I use `coforall` vs. `forall`...?)**" >}}

  The reason Chapel has both `coforall` and `forall` loops essentially
  comes down to a question of efficiency.  If you want to increment
  all of the elements in an array `A`, you _could_ write:

  ```chapel
  coforall a in A do
    a += 1;
  ```

  However, imagine that `A` was declared over the domain `{1..1000,
  1..1000}`.  Since `A` has a million elements, this loop has a
  million iterations, and the use of the `coforall` to drive it would
  create a million tasks.  That's a lot of parallelism if you're only
  running on a 4-core laptop—far more than you need.

  Moreover, even if you had a million cores, creating tasks only to
  have each perform a single `+ 1` operation means that your program
  will spend most of its time creating and destroying tasks rather
  than doing useful work.  It would be a bit like going to the grocery
  store to buy one item at a time—you'd spend far more time in travel
  than doing the actual work of shopping.  This is why Chapel has
  `forall` loops: to create a number of tasks based on the number
  of available processors, and then have them each do a portion of the
  total work, amortizing the cost of creating the tasks.

  Specifically, rewriting the above `coforall` as a `forall`, like so:

  ```chapel
  forall a in A do
    a += 1;
  ```

  says "Here are a bunch of independent increment operations that I
  want to perform in parallel.  Please defer to `A`'s parallel
  iterator method to decide how to make that happen."  In practice,
  most parallel iterators on standard Chapel types, like ranges,
  domains, and arrays, will query the number of processor cores
  available, create a number of tasks equal to those cores, and divide
  up the work between those tasks.  For example, on my 4-core laptop,
  4 tasks would be created by default, and the million iterations of
  this loop would be divided into equal-sized chunks of 250,000
  elements, each of which would be executed by one of the tasks.

  To summarize, use a `forall` loop whenever the iterations of your
  loop are independent, particularly when the number of iterations far
  exceeds the number of processors available for you to run on.  Use a
  `coforall` loop when you literally want to create a task per
  iteration; or when you must do so because the tasks need to
  synchronize or coordinate with one another in a way that breaks the
  `forall` loop's assumption that the iterations can be executed in
  any order.

  {{< /details >}}

  #### Creating Monkey Tasks with `coforall` Loops

  Now that you know about `coforall` loops, we can create our tasks!
  This has been a lot of build-up to what is a very simple loop
  structure in Chapel:

*/

coforall monkey in Monkeys {
/*

  Here, I am iterating over my `Monkeys` array, creating a distinct
  task for each monkey.  If `Monkeys` has 8 elements, this loop will
  create 8 tasks.  Each task or iteration will have its own `monkey`
  loop index variable referring to its unique `Monkey` object from the
  `Monkeys` array.

  What those tasks do is governed by the body of the loop, which is
  as follows:

*/
  for 1..numRounds {
    monkey.processItems(canFinishTurn);
    bar.barrier();
    monkey.swapItems();
    bar.barrier();
  }
}

/*

  Though this loop's body is short, it's also a bit dense because of
  the barrier, so let's go through it step by step.

  We start with a sequential `for` loop representing the rounds of the
  simulation.  Each of our monkey tasks takes a turn in each of the
  rounds, and this loop essentially counts off those rounds.  Because
  I didn't need to refer to the round number within the loop, I didn't
  bother giving it an index variable.

  Within each round:

  * First, the monkey processes its items using a call to its
    `.processItems()` method.  This is a procedure that I define a bit
    later in the file, so we'll come back to it then.  For now, all
    you need to know is that the monkey will process its current items
    until it runs out and `canFinishTurn` says it's OK for its turn to
    end.  It will also increment its `numInspected` field as it
    inspects items.  Once it's done with its turn, it returns here.

  * Next, it enters our barrier synchronization, by calling
    `bar.barrier()`.  If it is the first monkey to arrive, it must
    wait for all the other `numMonkeys-1` monkeys before proceeding.
    All subsequent monkeys but the last act similarly.  When the last
    monkey arrives, all monkeys can go on to the next statement.

    The reason I need a barrier here is that a monkey's next action
    will be to swap its lists of `current` and `next` items.  But if
    monkey 0 performs that swap while monkeys `1`–`7` are still
    executing, those monkeys may simultaneously be throwing it items
    for the next round.  Depending on the timing, they could end up in
    the wrong list.  So we need to make sure all monkeys are done
    throwing items before any of them swap their lists.

  * Next, each monkey calls the `.swapItems()` method that we saw
    earlier.  Recall that this swaps the indices of the `current`
    and `next` item lists, setting us up for the next round.  The
    empty `current` list will be ready to catch new items for the next
    round, and the (potentially) non-empty `next` list becomes the
    list of items to process in the coming round.

  * Finally, the monkeys enter our barrier again.  This time, it's
    because if a monkey were to go on to the next round and start
    throwing items, they could land in the wrong list if the receiving
    monkey had not yet swapped its lists.  Once all monkeys have
    reached this call to `barrier()`, we know their swaps are
    complete, and that it is safe to go on and start throwing items
    around again.

  After `numRounds` iterations through this loop, we are done with our
  simulation.  And then we reach the end of the `coforall` loop, which
  waits for all the monkey tasks to finish before going on to the end
  of the program's execution.

*/

/*

  ### Printing the Program Output

  When we are done simulating our monkeys, we can read their
  `numInspected` fields to see how many items they each inspected.
  These fields are incremented in the `processItems()` method, which
  we haven't seen yet, but will in just a bit.  For now, you'll have
  to trust me that the values have been properly incremented by the
  time we reach this point.

  The AoC instructions ask us to find the two monkeys who inspected
  the most items and multiply their values together.  There are a few
  ways one might approach this in Chapel.  I did it using reductions.
  Specifically, I started with a `maxloc` reduction (introduced on
  [day 6]({{< relref "aoc2022-day06-packets/#the-maxloc-reduction"
  >}})) to find the largest value and its index within the `Monkeys`
  array:

*/

const (max, loc) = maxloc reduce zip(Monkeys.numInspected, Monkeys.domain);
/*

  The value itself will be stored in `max` and its location in `loc`.
  I then zero out that monkey's `numInspected` field and run a second
  `max` reduction to find the second largest value, `max2`:

*/
Monkeys[loc].numInspected = 0;
const max2 = max reduce Monkeys.numInspected;

/*

  Finally, I multiply these two values together and print them out:

*/

writeln(max * max2);

/*

  (I could then store `max` back into `Monkeys[loc]`'s `numInspected`
  field to restore the original results for posterity, if desired; but
  I didn't bother doing that here).

*/

/*

  ### Processing a Monkey's Items Using a Secondary Method

  Now let's look at my method for how a monkey processes its items.
  This is what's known as a _secondary method_ in Chapel because I
  have declared it outside of the `Monkey` class, yet within the same
  module that defines `Monkey`:

*/

proc Monkey.processItems(canFinishTurn) {
/*

  As you can see, I associate the method with the `Monkey` class by
  qualifying the method name `processItems` with the `Monkey.` prefix.

  For all intents and purposes, this secondary method is equivalent to
  declaring the procedure as a _primary method_ directly within the
  Monkey class's scope, as I did for `currentItems()`, `nextItems()`,
  and `swapItems()` above.  So, I could have declared `processItems()`
  earlier as follows:

  ```chapel
  class Monkey {
    ...
    proc processItems(canFinishTurn) {
      ...
    }
  }
  ```

  In this case, I used a secondary method simply so I could walk you
  through the code in what felt like a more logical order to me.  In
  practice, developers may choose between primary and secondary
  methods for similar reasons, or just due to personal style
  preferences.  Again, the key is that either approach is equivalent
  in Chapel.

  As we saw at the callsite, I'm passing our `sync` variable,
  `canFinishTurn` into this routine so that the monkey can tell when
  it's OK to stop processing items and complete its turn.

  The body of `processItems()` is dominated by a while-loop that
  continues running as long as `canFinishTurn` does not store our ID
  yet:

*/
  while (canFinishTurn.readXX() != id || currentItems().size > 0) {

/*

  As long as it does not, monkeys preceding us are still running and
  could throw more items to us.  The loop also runs as long as there
  are more items in our current list that need processing, by checking
  the size of `currentItems()`.

  The `.readXX()` call on `canFinishTurn` is one of several methods
  supported for reading or writing synchronization variables.  Because
  of their full/empty bits, `sync` variables can't simply be accessed
  like normal variables.  Instead, methods must be used that say what
  state the full/empty bit must be in for the read or write to start,
  as well as what state the operation should leave it in.

  For example, a common way to read a `sync` variable is using the
  `readFE()` method, which says that the full/empty bit must start in
  the 'full' state (`F`) for the operation to proceed.  If it isn't,
  the task performing the read will block, yielding its processor.
  Once the variable is 'full', the task can perform the read, and will
  leave the full/empty bit in its 'empty' state (`E`).  If multiple
  tasks are attempting a `readFE()` on a single variable
  simultaneously, only one will succeed since whichever one performs
  the read will leave it 'empty' blocking other tasks from reading.
  This is a very common approach for writing producer-consumer
  parallelism in Chapel, and an efficient use of resources since any
  blocked task(s) will not consume CPU resources until the variable
  becomes 'full'.

  In this program, we don't really want our monkeys to block, though,
  since additional items may arrive that they'll need to process
  before ending their turn.  This is why I've taken the approach of
  keeping `canFinishTurn` in its 'full' state at all times.  And since
  I don't care what state the full/empty bit is in, I use `.readXX()`
  to get its value.  The first `X` in `.readXX()` indicates that the
  read does not care whether the full/empty bit is in its 'full' or
  'empty' state.  The second `X` indicates that the operation won't
  change the bit's setting as it performs the read.  So this is
  essentially a way of "peeking" at the `sync` variable's integer
  value without changing anything about its full/empty bit.  This read
  also gives other tasks the opportunity to run and implies a memory
  fence for other loads and stores.

  {{< details summary = "**(An aside about a subtle bug that I hit along the way...)**" >}}
  
  While preparing my code for this article, at one point I swapped the
  order of my tests in this `while` loop as follows, thinking it might
  give me a slight boost in performance:

  ```chapel
  while (currentItems().size > 0 || canFinishTurn.readXX() != id) {
  ```

  For my first few runs, I got the right answer; then, on a subsequent
  run, did not.  Running some more, I found that I was getting
  incorrect results in about one out of every ten runs.  It turns out
  that I had introduced a subtle race condition into my code.
  Specifically, my mental model was "If my current list of items has
  size 0 and I can finish my turn, I should exit this loop."  But what
  I failed to consider was the potential for a subtle race.  Imagine I
  am monkey 3:

  * I check the size of my list of current items and find it to be 0
    because I'd already cleared it out on previous iterations of this
    loop.

  * Meanwhile, monkey 2 is running in parallel and finds some new
    items for me, so it throws them into my `current` list because it
    precedes me in the turn order.

  * Then, monkey 2 decides it is done and sets `canFinishTurn` to my
    ID, `3`.

  * Then, I go to read `canFinishTurn`, see that it stores my ID and
    decide it is safe for me to proceed.

  * Yet, it actually is not, because I've ignored the fact that new
    items have shown up in my list since I checked its size.

  If this scenario may seem hard to imagine ("How could those changes
  slip in so fast?!?"), welcome to the world of modern parallel
  computing where multicore processors can keep these monkeys running
  continuously, causing operations to overlap with one another in time
  in just this way.

  When I restored these expressions to the original order, the code
  became correct again: I only consider proceeding once monkey 2 has
  given me the go-ahead, but then will only actually proceed once I've
  verified that it hasn't thrown me any new items since I last checked
  my current item list's size.

  This was a great reminder that while Chapel makes parallel
  programming far more straightforward than conventional techniques,
  parallel programming is still inherently challenging by nature.
  Race conditions between tasks can be subtle and difficult to
  anticipate, even for an experienced parallel programmer.  It's worth
  noting that such challenges often arise when using Chapel's
  task-parallel features: Because the coordination and synchronization
  between tasks is under the programmer's control, it is also their
  burden to make sure all the tasks are executing and synchronizing
  correctly.  In contrast, the data-parallel features tend to provide
  a simpler model of parallelism to the programmer, and one that
  handles many common cases.  All the details of creating and
  coordinating tasks still exist, yet they are hidden within
  abstractions like parallel iterators.

  {{< /details >}}


  Whenever a monkey enters the main `while` loop in `processItems()`,
  it either has more items that it needs to process in the current
  round, or it's not allowed to end its turn yet.  The body of the
  while-loop checks for items and processes them if there are any:

*/

    while currentItems().size > 0 {
      var item = currentItems().popBack();
      numInspected += 1;

/* 

  This inner while-loop exists to make sure we don't remove items from
  our list when it's empty.  It also serves as a means of processing
  as many items as possible before going back to check the
  synchronized `canFinishTurn` variable again (since reading a `sync`
  is a bit more heavyweight than reading a typical variable and could
  also cause us to yield our processor to another monkey).

  Each time through this loop, the monkey removes an item from its
  current list with the `.popBack()` method and increments its
  `numInspected` count to track the item (see, I said you could trust
  me that it would!).

  Next, it processes the item:

*/

      item = op.apply(item);
      item /= 3;

/*

  The first line here applies the monkey's operator, which will add
  to, multiply, or square its item's value.  Then we divide the item's
  value by 3 to reflect our relief that the monkey didn't break it, as
  indicated by the AoC instructions.

  All that remains is to throw the item to the appropriate target
  monkey.  We do this by seeing whether or not the item's value modulo
  `divisor` is `0`, using the result to index into our
  `targetMonkey()` tuple, storing the monkey's ID in a constant,
  `target`:

*/
      
      const target = targetMonkey(item % divisor == 0);

/*

  Note that this indexing expression relies on Chapel's support for
  implicitly converting `bool` values to `int`s, where `false`
  converts to `0` and `true` to `1`.  Thus, this is essentially
  shorthand for:

  ```chapel
  const target = if item % divisor == 0 then targetMonkey(1) else targetMonkey(0);
  ```

  We've actually used these conversions on previous days, such as [day
  8]({{< relref
  "aoc2022-day08-treehouse/#computing-visibility-in-parallel-via-promotion"
  >}})):

  ```chapel
  writeln(+ reduce visible(ForestSpace, Forest));
  ```

  In this expression, `visible()` returns `true` or `false`, and we
  relied on the implicit conversion of these values into integers in
  order to add them up and get the number of visible trees using
  `+ reduce`.

  You might also notice that I'm indexing into `targetMonkey` using
  parentheses rather than square brackets.  Chapel permits indexing
  expressions (and subroutine calls) to be written with either square
  brackets or parentheses, and my personal style is to typically use
  square brackets when indexing into arrays and parentheses for
  tuples.

  Then, we "throw" the item to the target monkey's `items` lists using
  the `list.pushBack()` method.  If the target monkey's ID is less than
  ours, we know that we have to throw the item to its list of items
  for the next round.  Conversely, if the monkey's ID is greater than
  ours, it will need to handle the item in this round, so we append to
  its current item list:

*/

      if (target < id) {
        Monkeys[target].nextItems().pushBack(item);
      } else {
        Monkeys[target].currentItems().pushBack(item);
      }
    }
  }

/*

  Each monkey continues this process until its current list of items
  is empty (i.e., its size is 0) and the `sync` variable indicates
  that it's OK for it to end its turn (i.e., all of the monkeys
  preceding it have finished their turns, so no other items will be
  thrown to it in this round).

  When a monkey exits the main `while` loop in `processItems()`, it
  finishes its turn by updating the value in `canFinishTurn`.  This
  signals to the next monkey that its predecessors are done, so nobody
  will be throwing it any more items this round:

*/
  
  canFinishTurn.writeFF((id+1) % numMonkeys);
}

/*

  Note that I'm using the `.writeFF()` method here to state that this
  write should only occur when the `sync` variable is 'full' and that
  it should leave it 'full'.  As mentioned previously,
  `canFinishTurn()` starts out 'full', and none of our operations—most
  notably the `readXX()` earlier—will change this state.  So there is
  no chance of the full/empty bit being in the 'empty' state or of
  this task blocking.

  Also, note that the last monkey resets the value to `0` for the next
  round, due to the use of modular arithmetic.

*/

/*

  {{< details summary = "**(a note on the performance characteristics of this simulation...)**" >}}

  Before going on, it's worth pausing to consider whether applying
  parallelism to this problem is worthwhile or not.  On the plus side,
  giving each monkey its own task permits multiple monkeys to process
  their item lists simultaneously.  On an 8-core processor, all 8
  monkeys could be executing simultaneously throughout the program's
  execution.  Since we only create the monkey tasks once, for a
  long-running simulation of 10,000 rounds, the cost of creating and
  tearing down the tasks is amortized by the long execution time.

  However, this program also has a fairly staggered, asynchronous
  execution pattern.  While all monkeys with non-empty lists will have
  parallel work to do at the start of a round, monkey `0` will
  necessarily finish first since nobody can throw it new work; and
  monkey `7` may continue receiving work right up until monkey `6`
  finishes its turn.  So unlike a well-balanced `forall` loop, our
  monkeys will necessarily have workloads that are skewed in time, with
  the smaller IDs finishing earlier and higher ones finishing later.
  This is not terrible, but it does mean that processor utilization
  will vary per task, and that we won't see "perfect speedup" since not
  everyone can execute simultaneously the entire time.

  In addition, by changing from a serial implementation to a parallel
  one, we've added synchronization overheads: The monkeys must access
  a `sync` variable to determine when their turns are over, which is
  more expensive than a normal variable access.  The monkeys also have
  to interact with parallel-safe lists which add overheads relative to
  non-parallel-safe lists.  And finally, they must enter and wait at
  the barrier synchronizations before proceeding.  The combination of
  these operations adds a fair amount of overhead that would not be at
  all present or necessary in a simpler sequential version.

  As in many of these AoC 2022 codes, the use of parallelism may not
  be justified from a performance perspective.  The AoC site describes
  these challenges as having solutions that can run in 15 seconds on
  10-year-old computers, presumably using serial approaches.  However,
  it is not difficult to imagine that with a large enough set of
  items, or potentially a large number of monkeys and cores, the
  benefits of having multiple monkeys processing their long lists of
  tasks simultaneously would outweigh the additional overheads of
  coordinating between them.

  And this is the promise of parallel computing: to apply it to
  computationally intensive problems where the overheads of
  introducing parallelism and coordinating between tasks are
  outweighed by being able to do multiple things simultaneously for
  long enough periods to outweigh those costs.  Fortunately for the
  parallel programming community, the world is full of such problems
  even if our AoC monkey simulation may not be one of them.

  As we've mentioned before in this series, our goal in writing these
  articles is not to suggest that this is the right or best way to
  solve these AoC problems, but to use the problems to teach you
  Chapel's parallel features in a simple, well-defined setting in
  hopes that you can take the lessons and apply them to large,
  well-motivated, real-world problems that take hours or days to run
  without parallelism.

  {{< /details >}}

*/

/*

  ### Using A Class Hierarchy to Represent Monkeys' Operations

  I've left the representation of the monkey's operations quite
  vague so far, so let's clear that up.  To represent the
  operators, I used a little class hierarchy, consisting of a
  base class, `MathOp`:

*/

class MathOp {
  proc apply(item): item.type {
    halt("We should never end up calling '.apply' on the base class");
  }
}

/*

  The `MathOp` class has three subclasses, representing the three
  operations a monkey might do.  The first represents squaring the
  item's value:

*/

class SquareOp: MathOp {
  override proc apply(item) {
    return item * item;
  }
}

/*

  The other two add a value to the item or multiply the item by a
  value, respectively, where the other value is stored as a field
  within the class:

*/


class AddOp: MathOp {
  var val;
  override proc apply(item) {
    return item + val;
  }
}

class MulOp: MathOp {
  var val;
  override proc apply(item) {
    return item * val;
  }
}

/*

  This is the first time we've seen subclasses in this series.  If
  you've used [_object-oriented
  programming&nbsp;(OOP)_](https://en.wikipedia.org/wiki/Object-oriented_programming)
  in C++, Java, Smalltalk, or any other OOP language, the concept is
  likely familiar to you.  If not, you can think of a subclass as
  being a specialization of its parent class.  In this case, `MathOp`
  represents an abstract mathematical operation, while `SquareOp`,
  `AddOp`, and `MulOp` represent specific kinds of math operations.

  Chapel subclasses are declared by specifying a parent class
  constraint after the class name, like `: MathOp` here.  The reason I
  use a class hierarchy is to declare the monkeys' `op` fields using a
  well-defined type, but to permit different monkeys to have different
  flavors of operations.  All the compiler needs to know is that they
  are `MathOp`s, but at execution time, each monkey will store an
  instance of one of the specific child classes.

  Chapel's class hierarchies support [_dynamic
  dispatch_](https://en.wikipedia.org/wiki/Dynamic_dispatch), which is
  specified by using the `override` keyword as a prefix on the child
  class methods that are meant to replace their parent's.  I use
  `override` on the declarations of `apply()` in my subclasses to
  indicate that when I 'apply' a monkey's operation, it should use the
  `apply()` method of the specific sub-class.  We saw such a call in
  `processItems()` above:

  ```chapel
      item = op.apply(item);
  ```

  For this call, the Chapel program will execute the appropriate
  `override` method in the child class that the monkey is storing.
  Again, this is similar to dynamic dispatch in virtually any OOP
  language.

  To create instances of these class-based operations, I wrote the
  following little helper routine, which takes the two strings
  uniquely identifying the operator from the input (like `* 19`, `+
  6`, or `* old`) and converts them to an instance of the appropriate
  class.  When present, it stores the numerical operand into the
  class's `val` field:

*/

proc opStringsToOp(operation, operand) {
  if operation == "+" {
    return new AddOp(operand:int): MathOp;
  } else {  // operation is "*"
    if operand == "old" {
      return new SquareOp(): MathOp;
    } else {
      return new MulOp(operand:int): MathOp;
    }
  }
}

/*

  ### Reading the Input using an Iterator and Initializer

  To read in the monkeys, I use an iterator that runs a loop, creating
  monkeys until it fails to find a newline (`\n`) in the console's
  input channel, `stdin`:

*/

iter readMonkeys() {
  do {
    yield new Monkey();
  } while stdin.matchNewline();
}

/*

  This iterator uses a different pattern than we've seen before.  The
  `Monkey` class's initializer (defined below) does all the heavy
  lifting of reading a monkey's description from the input file.  The
  loop simply yields those monkeys back to the callsite as they are
  created.  The call to `matchNewline()` returns `true` if a `\n` is
  found next in the input and `false` otherwise (indicating we've
  reached the end of the file).

  Speaking of the initializer, here it comes.  Initializers can be a
  tricky bit of code to write in Chapel, as they must initialize a
  record or class's fields in the same order that they were declared,
  and must also follow certain rules and constraints.  Up until now,
  our uses of classes in this series have relied on the compiler's
  default initializer in all cases.  For this program, however, I
  wanted the initializer to read in the input file directly and save
  the values to their appropriate constant fields at
  initialization-time.

  I'm already way over my target word-count, so am not able to teach
  you the intricacies of initializers today.  Instead, let me walk you
  through what I did at a high level:

  First, the initializer's declaration is made using the `proc`
  keyword and the method name `init()`.  Like `processItems()`, it is
  declared as secondary method since we've long since left the scope
  of the `Monkey` class:

*/

proc Monkey.init() {

/*

  Initializers can take arguments like normal procedures, but are
  called using `new Monkey(...)` rather than `<something>.init()`
  since the whole point of them is to create something out of nothing.

  Next, I read in the monkey's ID:

*/

  readf("Monkey ");
  this.id = read(int);
  readf(":");

/*

  Here, I've used `readf()` to read in the fixed formatting from the
  file, as we've seen in previous days' examples.  However, I'm using
  a `read()` procedure that we have not seen.  It takes a type
  argument, reads a value of the given type from `stdin`, and returns
  it.  Here, I use the routine to read an `int` and initialize the
  `id` field with its value.

  Next, I read in the monkey's items list into a temporary list
  named `tempItems`:

*/

  readf(" Starting items:");
  var tempItems: list(int);
  do {
    const val = read(int);
    tempItems.pushBack(val);
  } while stdin.matchLiteral(",");

/*

  I use `tempItems` here because an object's fields must be
  initialized in order.  The array of item lists is next in our input
  file format, yet the field is declared later in my class.  So I
  store the values here for now, and will put off setting up the
  `items` field until later.

  Next, I read the monkey's operation and use my `opStringsToOp()`
  helper to convert it into the appropriate `MathOp` subclass.  I use
  this to initialize the `op` field:

*/

  var operation, operand: string;
  readf(" Operation: new = old %s %s", operation, operand);
  this.op = opStringsToOp(operation, operand);

/*

  Then I read and initialize the divisor:

*/
  
  readf(" Test: divisible by ");
  this.divisor = read(int);

/*

  Then I read and store the target monkeys:

*/
  
  var targetMonkey: 2*int;
  readf(" If true: throw to monkey %i", targetMonkey(true));
  readf(" If false: throw to monkey %i\n", targetMonkey(false));
  this.targetMonkey = targetMonkey;

/*

  Finally, I copy `tempItems` into the `items` field using the
  current items list:

*/
  
  init this;
  for item in tempItems do
    items[current].pushBack(item);
}

/*

  I do this after an `init this;` statement, which ensures that all
  remaining fields are initialized, permitting me to write arbitrary
  code like the loop and indexing expressions here.  When Chapel
  reaches an `init this;` statement, any fields that had initializers
  at their declaration point (like `current = 0` and `next = 1`) are
  initialized with those values.  Fields that don't are initialized to
  their type's default value, as with normal variable declarations in
  Chapel.

  ### Summary

  And _that_ is my program for day 11!  We covered a lot of new ground
  here, mostly in the task parallelism realm, where we saw `coforall`
  loops, synchronization variables, and barriers for the first time.
  However, we also got a quick taste of some fancy IO, class
  hierarchies, dynamic dispatch, and our first user-defined class
  initializer.  You can download my full solution at the top of this
  article or from
  [GitHub](https://github.com/chapel-lang/chapel/blob/0568b92d7c27c442b855c61687dce0f86fb4d96a/test/studies/adventOfCode/2022/day11/bradc/day11.chpl).

  You have all of the Chapel knowledge you need for part 2 of today's
  challenge, though it does require some good mathematical reasoning
  (or a good memory depending on what math courses you've taken).

  In particular, once we no longer divide the item values by 3 on each
  iteration and run for 10,000 rounds, the item values will blow up
  well beyond what an `int` in Chapel can store (the `int` type in
  Chapel is 64 bits, and signed, so can store values up to `2**63`).
  Chapel also has a [`bigint`
  type](https://chapel-lang.org/docs/modules/standard/BigInteger.html),
  but it can be very memory intensive, particularly since the values
  in part two can grow to such ridiculous magnitudes.  In practice,
  writing the program using `bigint` bogs down due to excessive memory
  usage and operation times (believe me, I tried).

  {{< details summary = "**(a further hint on the part two math...)**" >}}

  A key insight for part two is to notice that all of the monkeys'
  `divisor` values are prime.  As a result, since all their
  comparisons are done using modular arithmetic, we can safely reduce
  items' values by the product of the monkeys' divisors without
  changing the results of the `%` operations..

  {{< /details >}}

  This is the penultimate article in this series.  Thanks for reading
  this far, and please feel free to ask any questions or post any
  comments you have in the [Blog
  Category](https://chapel.discourse.group/c/blog/) of Chapel's
  Discourse Page.

  ### Updates to this article

{{< changetable >}}
  | Date         | Change                                                      |
  |:-------------|:----------------------------------------------------------------------------------|
  | Apr&nbsp;26,&nbsp;2023 | Updated to reflect `barrier`-related name changes in Chapel 1.30 |
  | Feb&nbsp;5,&nbsp;2023  | Updated to reflect changes to `list` method names, `init this;` syntax, and new handling of returns after halt()s |

*/
