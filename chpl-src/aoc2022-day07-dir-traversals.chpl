// Advent of Code 2022, Day 7: Traversing Directories
// authors: ["Daniel Fedorin"]
// summary: "A solution to day seven of AoC 2022, introducing classes and memory management."
// tags: ["Advent of Code", "How-To"]
// series: ["Advent of Code 2022"]
// date: 2022-12-07

/*
  Welcome to day 7 of Chapel's Advent of Code 2022 series. We're over halfway
  through the twelve days of Chapel AoC! In case you haven't been following
  the series, check out the introductory [Advent of Code 2022: Twelve
  Days of Chapel]({{< relref "aoc2022-day00-intro" >}}) article for more context.
 */

/*
  ### The Task at Hand and My Approach

  In today's puzzle, we are given a list of terminal-like commands (
  [`ls`](https://man7.org/linux/man-pages/man1/ls.1.html) and [`cd`](https://man7.org/linux/man-pages/man1/cd.1p.html)
  ), as well as output corresponding to running these commands. The commands
  explore a fictional file system, which can have files (objects with size)
  as well as directories that group files and other (sub-)directories. The
  problem then asks to compute the sizes of each folder, and to total up the
  sizes of all folders that are smaller than a particular threshold.

  The tree-like nature of the file system does not make it amenable to
  representations based on arrays, lists, or maps alone. The trouble with
  these data types is that they're flat. Our input could have arbitrary
  levels of nested directories. However, arrays, lists, and maps cannot have
  such arbitrary nesting --- we'd need something like a list of lists of lists of...
  We could, of course, use the `map` and `list` data types to represent the
  file system with some sort of [adjacency list](https://en.wikipedia.org/wiki/Adjacency_list).
  However, such an implementation would be somewhat clunky and hard to use.

  Instead, in this article I use a different tool from the repertoire of Chapel language
  features, one we haven't seen so far: classes. Specifically, I use a class, `Dir`, to represent
  directories in the file system, and build up a tree of these directories
  while reading the input. I then create an iterator over this tree that
  computes and yields the sizes of the folders. From there, it's easy to
  pick out all directory sizes smaller than the threshold and sum them up.

  **If you skip right to your favorite parts of a movie, here's a full solution for the day:**
  {{< whole_file_min >}}

  And now, on to the explanation train. Before the train departs, let's import
  a few of the modules we'll use today. `IO` is a permanent fixture in our
  solutions (we always need to read input!), and `List` is a familiar face.
  The only newcomer here is `Map`, which helps us associate keys with values,
  much like a dictionary in Python, a hash in Ruby, or a map in C++.
  We'll use maps and lists for storing the various files and directories
  on the file system.
*/

use IO, Map, List;

/*
  With that, our train's first stop: classes!

  ### Classes in Chapel

  Like in most languages, classes in Chapel are a way to group together related
  pieces of data. Up until now, we've used tuples for this purpose. Tuples,
  however, have a couple of limitations when it comes to solving today's
  Advent of Code problem:

  * We can't name a tuple's elements. Whenever you make and use a tuple,
    it is up to _you_ to remember the order of the elements within it, and
    what each element represents.
  * Tuples are a statically constrained data structure. We can't nest tuples within tuples
    to a depth not known at compile time, just like we couldn't arbitrarily
    nest lists within lists.

  Classes have neither of these limitations. They do, however, need to be
  explicitly created within Chapel code. For example, one might create a
  class to store information about a person:

  ```Chapel
  class person {
    var firstName, lastName: string;
  }
  ```

  We've seen plenty of `var` statements used to create variables; when used
  within a class, `var` declares a _member variable_ (also known as a _field_)
  for the class. Our `person` contains two pieces of data in its fields: the
  person's first name (`firstName`) and last name (`lastName`).

  With that class definition in hand, we can create instances of the `person` class
  using the `new` keyword.

  ```Chapel
  var biggestCandyFan = new person("Daniel", "Fedorin");
  ```

  As usual, we can rely on type inference to only write the type `person` once;
  Chapel figures out that `biggestCandyFan` is a `person`. Now, it's easy to get
  the various fields back out of a class:

  ```Chapel
  writeln("The biggest fan of candy is ", biggestCandyFan.firstName);
  ```

  Believe it or not, we've already seen enough of classes to see how to represent
  nested data structures. The key observation is that classes have names, which
  means that we can create fields that refer back to instances of the same class. Here's
  an example of what I mean, in the form of a modified `person` class:

  ```Chapel {hl_lines=3}
  class person {
    var firstName, lastName: string;
    var children: list(owned person);
  }
  ```

  The highlighted line is new. We've added a list of children to our person.
  These children are themselves instances of `person`, which means they too
  can have children of their own. _Et voilà_ - we've got a nested data structure!

  #### Memory Management Strategies
  You probably noticed that `children`'s type is `list(owned person)` ---
  note the `owned`. This keyword is an indication of the way that memory is
  allocated and maintained for classes: their _memory management_. To create
  a class, a Chapel program asks for some memory from the computer (_allocates_ it).
  This memory is kept by the program until the instance of a class is no longer
  needed, at which point it's _deallocated_/_freed_. The challenge is knowing when
  a class is no longer needed! This is where _memory management strategies_,
  like `owned`, come in.

  We don't need to get too deep into the various memory management strategies
  in today's post.

  {{< details summary="**(If you're curious, here's a brief description of each strategy...)**" >}}
  * When using the `owned` strategy, a class instance has one "owner" variable.
    The instance is only around as long as this owner exists.
    As soon as the owner disappears, the class instance is deallocated.
    In some cases --- though we won't be covering them today --- ownership can
    be transferred from one variable to another, but no two values can
    own the same class instance at the same time.

    Other variables can still refer to an `owned` class instance, but they must _borrow_ it,
    creating, for example, a `borrowed person`. Borrows do not affect the
    lifetime of a class nor when it is deallocated.
  * When using the `shared` strategy, Chapel keeps track of how many places
    still have variables that refer to a particular instance of a class. This
    is typically called a _reference count_. Each time a variable is created
    or changed to refer to a class instance, the instance's reference count
    increases. When that variable goes out of scope and disappears, the
    reference count decreases. Finally, when the reference count reaches
    zero (no more variables refer to the class instance), there's no point
    in keeping it around anymore, and its memory is deallocated.

    As is the case with `owned`, other variables can borrow `shared` class instances.
    Such borrows do not affect the reference count at all, and therefore don't
    influence when the instance is freed.
  * When using the `unmanaged` strategy, you're promising to manually free
    the memory later, using the `delete` keyword. This is very similar to
    how `new`/`delete` work in classic C++.
  {{< /details >}}

  So, the `owned` keyword in our `children` list means we've opted for the
  `owned` memory management strategy. The implication of this is that
  when a "parent" person is deallocated, so are all of its children
  (since the person class, through its `children` list, owns each child).
  If we aren't planning on sharing our data, `owned` is the preferred strategy. This is because
  it precludes the need for some bookkeeping, which
  often makes a difference in terms of performance. The added benefit to using
  `owned`, in my personal view, is that it's easier to figure out when something
  will be deleted --- there's no chance of some other variable, elsewhere in my program,
  preventing a class instance's deallocation.

  #### Methods
  Remember how I said that classes can be used to group together pieces
  of related data? Well, they can do more than that. They can also group
  together operations on this data, in the form of _methods_. For instance,
  we could add the following definition **inside** the `class` declaration
  for our `person`:

  ```Chapel
  class person {
    // ... as before

    proc getGreeting() {
      return "Hello, " + this.firstName + "!";
    }
  }
  ```

  Just like fields can be thought of as `var`s that are associated with a particular
  class instance, methods can be thought of as _procedures_ associated with
  a particular class instance. Thus, methods behave pretty much exactly
  like the `proc`s we've seen so far, with the notable difference of being able to
  access that class instance through the `this` keyword.
  For example, inside the body of a method like `getGreeting` above,
  `this.firstName` gets us the person's first name, and `this.lastName` would
  get us their last name.

  We can call methods using the dot syntax:

  ```Chapel
  // Prints "Hello, Daniel!"
  writeln(biggestCandyFan.getGreeting());
  ```

  Methods are a powerful tool for abstraction; rather than writing external code
  that refers to the various fields of a class, we can put that logic
  inside of methods, and avoid exposing it to the rest of the world. A person
  writing `.getGreeting()` will not need to know how a name is represented
  in the `person` class.

  Another sort of method is a _type method_ (sometimes referred to as
  a _static method_ in other languages). Rather than being called on
  an instance of a person, like `biggestCandyFan` or `daniel`, it's called
  on the class itself. For instance:

  ```Chapel
  class person {
    // ... as before

    proc type createBiggestCandyFan() {
      return new person("Daniel", "Fedorin");
    }
  }

  var biggestCandyFan = person.createBiggestCandyFan();
  ```

  Methods like this have the benefit of being associated with a particular class.
  This means that another class can have its own `createBiggestCandyFan()`
  method, and there won't be any confusion or problems arising from trying
  to figure out which is which. Perhaps dogs (represented by a hypothetical
  `dog` class) have a biggest candy fan, too!

  ```Chapel
  var biggestCandyFan = person.createBiggestCandyFan();
  var biggestCandyFanDog = dog.createBiggestCandyFan();
  ```

  ### A `Dir` Class to Represent Directories
  Back to the solution. The class I use for tracking directories is actually not too different
  from our modified `person` class above. Each directory
  {{< sidenote right "will have a name" >}}
  Despite the recent media noise about ChatGPT, directories have not yet
  been granted personhood, and do not have both first and last names.
  {{< /sidenote >}}
  as well as a collection of files and directories it contains.
*/

class Dir {
  var name: string;

  var files = new map(string, int);
  var dirs = new list(owned Dir);

/*
  Since files have no
  additional information to them besides their size, I decided to represent
  them as a map --- a directory's `files` field associates each file's name
  with that file's size. The subdirectories are represented just like
  the `children` field from our `person` record, as a list of owned `Dir`s.

  There are a few more things I want to add to `Dir`;
  the first is a way to read our directory from our puzzle input.

  #### Reading the File System with the `fromInput` Type Method
  For reasons of abstraction and avoiding conflicts, I put
  the code for creating a directory from user input into a type method on `Dir`. Within
  this method, I include the now-familiar code for reading from the
  input using `readLine`, until we run out of lines.
*/

  proc type fromInput(name: string): owned Dir {
    var line: string;
    var newDir = new Dir(name);

    while readLine(line, stripNewline = true) {
      /*
        Notice that I'm accepting the name for the
        directory as a string formal and initializing a new variable `newDir` with that name.
        Notice also that I don't need to provide the `files` and `dirs`
        as arguments to `new Dir` --- they have default values in the
        class definition. By default, `new` uses the `owned` memory management
        strategy. For the time being, the `newDir` variable owns our
        directory-under-construction.

        We're reading lines now; all that's left is to figure out what to do
        with them. The first case is that of `$ cd ..`. When we see that line,
        it means that we're done looking at the current directory; none
        of the subsequent `ls` lines will be meant for us. Thus, we break
        out of the input `while`-loop.
       */
      if line == "$ cd .." {
        break;
      /*
        If the `cd` command is used, but its argument isn't `..`, we're being
        asked to descend into a sub-directory of our current `newDir`.
        In this case, we call the `fromInput` method again, recursively,
        to create a subdirectory of the current one. This
        call will keep consuming lines from the input until the sub-directory
        has been processed, at which point it will return it to us. We'll
        immediately append this sub-directory to the `newDir.dirs` list,
        which becomes the sub-directory's new owner.

        Recall that we need to give `fromInput` the name of the new
        sub-directory. We can figure out the name by slicing the string
        starting after the `$ cd` prefix. Since I want to get the rest of the
        characters after the prefix, I leave the end of my range unbounded, which
        makes the slice go until the characters run out at the end of the string.
        If you're feeling shaky on lists and `pushBack`, check out our [day 5 article]({{< relref "aoc2022-day05-cratestacks#moving-crates-within-an-array-of-lists" >}}).
        If you want a little refresher on slicing, we first covered it on [day 3]({{< relref "aoc2022-day03-rucksacks#ranges-and-slicing" >}}).

       */
      } else if line.startsWith("$ cd ") {
        param cdPrefix = "$ cd ";
        const dirName = line[cdPrefix.size..];
        newDir.dirs.pushBack(Dir.fromInput(dirName));
      /*
        As it turns out, all that's left is to handle files. We already get
        directory names from `cd`, so there's no reason to worry about
        lines starting with `dir`. The `ls` command itself always precedes
        the list of files and directories; by itself, it provides us no
        additional information. Thus, our last case is a line that's neither
        `dir` nor `ls`. Such a line is a file, so its format will be a number
        followed by the file's name.

        I use the `partition` method on the line to split it into three
        pieces: the part before the space, the space itself, and the part
        after the space. After that, I can just update the `newDir` map,
        associating the file called `name` with its size. I use an integer cast
        to convert `size` (a string) to a number.
       */
      } else if !line.startsWith("$ ls") && !line.startsWith("dir") {
        const (size, _, name) = line.partition(" ");
        newDir.files[name] = size : int;
    /*
      That's it for the loop! Once the loop stops running, we know we're done
      processing the directory. All that remains is to return it. Returning
      an `owned` value from a function or method transfers ownership to whatever
      code calls the function or method.
     */
      }
    }
    return newDir;
  }
  /*
    One more thing: I have explicitly annotated the
    return type of `fromInput` to be `owned Dir` to let Chapel know
    that I'm using the `owned` memory management strategy. This might just
    be the first return type annotation we've written so far. Up until now,
    Chapel has been able to deduce the return types of our procedures
    and iterators automatically. However, here, because we are using
    recursion, it needs just a little bit of help: determining the types
    in the body of `fromInput` requires knowing the type of `fromInput` itself!
    The manual type annotation helps break that loop.
   */

  /*
    #### An Iterator Method for Listing Directory Sizes
    Let's recap. What we have now is a data structure, `Dir`, which represents
    the directory tree. We also have a type method, `Dir.fromInput` that
    converts our puzzle input into this data structure. What's left?

    The way I see it, the problem is composed of three pieces:

    1. Go through all of the directory sizes...
    2. ... ignoring those that are above a certain threshold ...
    3. ... and sum them.

    Over the past week, we've gotten really good at summing things! In
    Chapel, we can just use `+ reduce` to compute the sum of something
    iterable, so there's point number three. For point two, it turns out that
    those [loop expressions]({{< relref "aoc2022-day06-packets" >}}#parallel-loop-expressions)
    from yesterday can be used to filter out elements like so:

    ```Chapel
    [for i in iterable] if someCondition then i
    ```

    Putting these two pieces together, we might write something like:
    ```Chapel
    + reduce [for size in directorySizes] if size < 1000000 then size
    ```

    That `directorySizes` expression is the only "fictional" piece of the solution.
    Perhaps we can make our `Dir` tree support an iterator of directory sizes?
    Then, we'd have our answer.

    In my solution, I do just that. Methods on classes don't have to be procedures ---
    they can also be iterators. There's only one complication. We want our
    iterator method to yield the sizes of _all_ of the various sub-directories
    within a `Dir` including sub-directories of sub-directories. That's because
    we have to sum them all up as per the problem statement. However, when
    _computing_ the size of a directory, we don't want to include sub-sub-directories
    in our counting: the direct sub-directories already include the sizes of
    their own contents. To make this work, I added a `parentSize` formal to
    the iterator method, which represents a reference to the parent directory's
    size. When it's done yielding its own size, as well as the sizes of the
    sub-directories, the iterator method will add its own size to its parent's.

    Here's the implementation of the iterator method; I'll talk about it in
    more detail below.
   */
  iter dirSizes(ref parentSize = 0): int {
    // Compute sizes from files only.
    var size = + reduce files.values();
    for subDir in dirs {
      // Yield directory sizes from the dir.
      for subSize in subDir.dirSizes(size) do yield subSize;
    }
    yield size;
    parentSize += size;
  }
  /*
    The first thing this method does is create a new variable, `size`,
    representing the current directory's size. It's initialized to the sum
    of all the file sizes. However, at this point, that's not the whole size ---
    we also need to figure out how much data is stored in the subdirectories.

    I use a `for` loop over the `dirs` list to examine each sub-directory
    of the current folder in turn. Each of these sub-directories is its
    own full-fledged `Dir`, so we can call its `dirSizes`
    method. This gives us an iterator of all directory sizes from `subDir`.
    I simply yield them from the parent iterator, making it yield
    the sizes of all directories, including nested ones. Notice that I also
    provide `size` as the argument to the recursive call to `dirSizes`:
    the inner for-loop serves the double purpose of yielding directory sizes
    and finishing computing the current folder's size.

    Once all of the sub-directory sizes have been yielded, the `size` variable
    includes all the files in the folder, including nested ones. Thus, I use it to yield
    the size of the current folder. I also add `size` to `parentSize`.

    That concludes our `Dir` class!
  */

  /*

  {{< skip >}}
  ```Chapel
  iter these(param tag: iterKind): (string, int) where tag == iterKind.standalone {
    var size = + reduce files.values();
    coforall dir in dirs with (+ reduce size) {
      // Yield directory sizes from the dir.
      forall subSize in dir do yield subSize;
      // Count its size for our size.
      size += dir.size;
    }
    yield (name, size);
    this.size = size;
  }
  ```
  {{< /skip >}}

  */

}

/*
  ### Putting It All Together
  With our `Dir` class complete, we can finally make use of it in our code.
  The first thing we need to do is read our file system from the input;
  this is accomplished using the `fromInput` method.
*/

var rootFolder = Dir.fromInput("/");

/*
  Next up, we can use that `+ reduce` expression I described above. I use
  a new variable, `rootSize`, to represent the size of the top-level directory.
  After the call to `dirSizes` completes, it will be set to the total size of
  the root directory, i.e., the total disk usage. */
var rootSize = 0;
writeln(+ reduce [size in rootFolder.dirSizes(rootSize)] if size < 100000 then size);

/*
  I could've omitted the argument to `dirSizes` --- notice from the method's
  signature that I provide a default value for `parentSize`.

  ```Chapel
  iter dirSizes(ref parentSize = 0): int {
  ```

  However, knowing `rootSize` lets us easily compute the amount of space we need
  to free up (for part 2 of today's problem).
 */
const toDelete = rootSize - 40000000; // = 30000000 - (70000000 - rootSize)

/*
  We can now re-use our `dirSizes` stream to check every directory size again,
  this time looking for the smallest folder that meets a certain threshold.
  A `min` reduction takes care of this:
 */
writeln(min reduce [size in rootFolder.dirSizes()] if size >= toDelete then size);

/* And there's the solution to part 2, as well! */

/*
  ### Summary
  This concludes today's description of my solution. This time, I introduced
  Chapel's classes --- defining them, creating fields and adding methods. We got
  a little taste of memory management strategies and ownership, though I deliberately
  kept it light to avoid introducing too many new concepts.

  Admittedly, today's solution is (for the most part) serial. Although the
  `+ reduce` expression that computes the initial `size` of a directory from
  its `files` is eligible for parallelization, the `dirSizes` iterator is not. The main
  reason for this is that the interaction between recursive parallel iterators and
  reductions is, at the time of writing, unimplemented.
  Nevertheless, I think that using even a serial iterator has _yielded_ an elegant
  solution (pun intended).

  If you wanted to write a parallel version, I'd advise creating a new,
  non-iterator method on `Dir` that solves just part 1 of today's puzzle.
  This method could return a tuple of two elements, perhaps `sumSmallSizes`
  and `dirSize`; then, a simple `forall` loop over `dirs` (and judicious use of reduce intents,
  which are described in our [day 4 article]({{< relref "aoc2022-day04-ranges" >}}#third-solution-parallel-approach))
  will let you compute the answer in parallel.

  Thanks for reading! Please feel free
  to ask any questions or post any comments you have in the new [Blog
  Category](https://chapel.discourse.group/c/blog/21) of Chapel's
  Discourse Page.


  ### Updates to this article

{{< changetable >}}
  | Date         | Change                                                      |
  |:-------------|:----------------------------------------------------------------------------------|
  | Feb 5, 2023  | Replaced `list.append()` with new `list.pushBack()` method |

*/
