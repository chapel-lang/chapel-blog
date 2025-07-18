// Advent of Code 2022, Day 1: Counting Calories
// tags: ["Advent of Code", "How-To"]
// series: ["Advent of Code 2022"]
// summary: "A simple solution to day one of AoC 2022, introducing basic Chapel concepts"
// authors: ["Brad Chamberlain"]
// date: 2022-12-01

/*

Welcome to day 1 of Chapel's Advent of Code 2022 series!  If you're
wondering what we're doing here, check out our introductory [Advent of
Code 2022: Twelve Days of Chapel]({{< relref "aoc2022-day00-intro" >}}) blog
article for context or instructions on compiling this code.

### The Task at Hand and My Approach

In brief, [the challenge for
today](https://adventofcode.com/2022/day/1) is to read in a series of
numbers—one per line—representing the calories in snack items owned by
elves.  A blank line (or the end of the file) represents the logical
end of the current elf's items.  Part one of today's task is to
determine the maximum number of calories owned by any single elf.

This article will walk through a solution I wrote in Chapel in detail,
introducing language concepts as we go.

**For those who like to jump to the end of books first, here is my solution:**
{{< whole_file_min >}}

There are some clever/cute ways to approach this problem in Chapel
using iterators and arrays, but for the sake of focusing on the basics
of Chapel for this first day, I stuck with a more naive solution that
simply uses scalar variables and traditional control flow constructs.
Knowing Advent of Code, we'll almost certainly get to those other
features in the next day or two.

At a high level, the approach I've taken is to:
* keep a running tally of the maximum calorie count we've seen so far
* read lines from the console, one at a time
* check their lengths to see whether they're empty or not
* increment a running calorie counter for any non-blank lines
* when we reach a blank line or the end of a file, update the
  maximum value as necessary and reset our counter

*/

/*

### The IO module (and modules in general)

This exercise, like most in AoC, requires reading input from the
console or a file.  As a result, we will be using Chapel's standard
`IO` module, which supports a wide variety of routines for reading and
writing data.  You can read about its features on its page in
[Chapel's online
documentation](https://chapel-lang.org/docs/modules/standard/IO.html)
or just keep reading this blog series and we'll teach you several key
routines as we go.

One way to make use of a module's features in Chapel is the `use`
statement:

*/


use IO;

/*

The `use` statement ensures that a module is initialized and makes all
of its public symbols available to the current scope.

{{< details summary="**(More on modules in Chapel...)**" >}}

Chapel also supports an `import` statement, which is a far safer and
more precise way of accessing a module's symbols.  In these AoC
exercises, our goal is to write code sketches quickly, so we'll tend
to rely on `use` for simplicity and brevity.

For additional context, all Chapel programs are defined in terms of
_modules_, which serve as a way to organize code into distinct units
or _namespaces_.  As a simple example, if the code in this article was
stored in a file named `day01.chpl`, it would define an implicit
module named `day01` containing all of the file's code.  Modules can
also be declared explicitly using the `module` keyword.

Any executable code defined at the top-level of a module's scope (like
the code in this article) will be executed when that module is
initialized, as the program begins executing.

For further information on modules, see the related
[primer](https://chapel-lang.org/docs/primers/modules.html) or
[section of the language
specification](https://chapel-lang.org/docs/language/spec/modules.html).
{{< /details >}}


Before going on, it's worth noting that:

* Chapel statements are typically terminated by semicolons (`;`)
* Chapel programs are not sensitive to whitespace.

*/

/*

### Variable Declarations

Let's start by declaring some variables.  Chapel variables can be
declared in terms of a type and/or initialization expression
(_initializer_).  If no type is specified, the variable will still
have a single, static type, which the compiler will infer from its
initializer.

First, I'll define a variable `line` of type `string` that will
be used to store the lines from the input:

*/

var line: string;

/* 

Variables are declared using the `var` keyword in Chapel, which can be
used to define one or more variables.  The colon operator (`:`) seen
here is used to specify the type of a symbol or expression in Chapel.
For example, when declaring a variable, like `line` here, the
expression after `:` specifies the variable's type.  In other
contexts, `:` serves as Chapel's _cast_ operator, which we'll see an
example of below.

Chapel's variable declarations are designed to be read left-to-right,
so this statement might be read as:

> _"Define a `var`iable named `line` whose type is `string`."_

Next, we'll declare a pair of variables to represent our running tally
of calories for the current elf's snacks (`currentCalories`) and the
maximum count we've seen so far for any elf (`maxCalories`):

*/

var currentCalories, maxCalories = 0;

/*

Here, you can see that I haven't specified the types of these
variables, just an initializer of `0`.  Since `0` is an integer value
in Chapel (an `int`), the compiler infers that `maxCalories` has type
`int`.

When a variable doesn't have a declared type or initializer, like
`currentCalories` here, but is followed by another variable that
does, it shares that information.  So in this case, `currentCalories`
is also an `int` variable initialized to `0`.

*/

/*

### Control Flow: Loops

If you're familiar with languages like C/C++, Python, Java, Fortran,
etc., Chapel's features for control flow will probably look familiar,
though potentially using slightly different syntax.

For this computation, we want to iterate until we run out of input
data, so we'll use a [`do...while`
loop](https://chapel-lang.org/docs/language/spec/statements.html#the-while-do-and-do-while-loops)
to drive the computation.  Chapel also supports other typical serial
loop styles—such as `for` loops—in addition to a variety of parallel
loop forms.  We'll likely be using several of these in the days ahead.

Here's the `do` statement that marks the start of our loop over the
lines in the input:

*/

do {

/*

Compound statements in Chapel are enclosed by curly brackets, as in C
and C-like languages.  The bodies of loops and conditionals are often
defined using compound statements, as in this case.

*/

/*

### Constant Declarations and Console Input

The next few lines declare a pair of constants using the `const`
keyword.  Constants are like variables except that they cannot be
modified once they are initialized.  Chapel programmers are encouraged
to use `const` when appropriate to enable compiler optimizations and
prevent themselves from modifying things that they didn't intend to.

*/  
  const more = readLine(line),
        foundItem = (line.size > 1);

/*

The first constant here is initialized by a call to the `readLine()`,
routine, provided by the `IO` module.  We pass it our `string`
variable `line` as an argument, and it will attempt to read a line
from the console into that string.  `readLine()` returns a Boolean
value (a `bool`) indicating whether we have reached the end of the
file or not.  Here, I'm storing that in a constant named `more` to
indicate whether there is potentially more data to be read.

The second constant, also a `bool`, will be set to `true` if the
length of the string we read is greater than `1`.  I'm using this test
to determine whether or not the line contained a calorie count.  By
default, `readLine()` stores the line's newline character (`\n`) into
the string argument, which is why I'm comparing against `1` rather
than `0` to find empty lines.

I was tempted to read integer values directly from the file rather
than using strings, but the methods for reading integers that I'm most
familiar with ignore whitespace; and since we need to be sensitive to
blank lines in today's challenge, reading them as strings seemed more
straightforward, particularly for this first lesson.

*/

/*

### Control Flow: Conditionals and Computation

The next chunks of code implement the main logic of this computation
using a series of conditionals.

The first conditional is used to increment our running total if
we found an item on the line:
  
*/

  // If we found an item, update our running tally
  if foundItem then
    currentCalories += (line: int);

/*

If the body of a conditional is a single statement, as in this case,
the keyword `then` can be used to specify that body.

The body of this conditional uses the aforementioned cast operator
(`:`) to turn the string value we read into an integer.  It also uses
Chapel's `+=` operator, which serves as shorthand for `currentCalories =
currentCalories + (line: int);`.

The logic in the following conditionals essentially just updates our
maximum value if appropriate and resets our running total to set up
for the next elf.

*/
  
  // If we are at the end of an elf's item list, update our maximum
  // value if appropriate and reset our tally for the next elf.
  if !more || !foundItem {
    if currentCalories > maxCalories {
      maxCalories = currentCalories;
    }
    currentCalories = 0;
  }

/*

If a conditional's body contains multiple statements, as in the outer
conditional here, curly brackets must be used, similar to the
`do...while` loop containing all this code.  Even for single-statement
conditionals, like the inner one here, it's often considered good
practice to use curly brackets, as a means of improving clarity and/or
reducing the potential for errors to be introduced if new statements
are added to the body over time.

{{< details summary="**(Here's another way to update the max...)**" >}}

The inner conditional here could also be replaced by a call to
Chapel's
[`max()`](https://chapel-lang.org/docs/modules/standard/AutoMath.html#AutoMath.max)
routine, which returns the largest of its arguments, like this:

```chapel
maxCalories = max(currentCalories, maxCalories);
```
{{< /details >}}


At this point, I want to go on to reading the next line if there was
one, so I wrap up my `do...while` loop using:

*/
  
} while more;

/*

Once `more` becomes `false`, we'll exit the loop and continue on to
the next statement.

*/

/*

### Console Output

An easy way to print to the console in Chapel is the `writeln()`
routine, which takes an arbitrary number of expressions and prints
them out one after the other to the console.  Nearly any Chapel
expression can be written out in this way, regardless of type, making
it a useful way to check the values of arbitrary expressions when
debugging.

*/

writeln(maxCalories);


/*

### Summary and Tips for Part Two

That wraps up this first day of introducing Chapel through AoC 2022.
As a reminder, the full code for my solution can be viewed at the top
of this article, or browsed and downloaded [from
GitHub](https://github.com/chapel-lang/chapel/blob/main/test/studies/adventOfCode/2022/day01/bradc/day01.chpl).

If you choose to go on to part two of the day 1 challenge, it asks you
to track the three elves with the most calories and sum their values.
This can be achieved using the concepts introduced above by juggling
some additional scalar variables.

Alternatively, you could choose to use an array to track the three
maximum values seen so far. Such an array can be declared using:
```chapel
var maxCalories: [1..3] int;
```
or
```chapel
var maxCalories: [0..<3] int;
```
depending on whether you prefer 1- or 0-based indexing.

If you use arrays, for-loops over integer sequences can be very
useful, and they can be written in Chapel as

```chapel
for i in 1..3 { ... }
for i in 0..<3 { ... }
```
or the like.  Another tip is that the elements of an array can be
summed into a single value using a _reduction_ of the form:

```chapel
total = + reduce MyArray
```

That said, these are just teasers, and we'll almost certainly return
to these concepts in more detail in the coming days, since they tend to
be very important for lots of Chapel computations and AoC exercises.

See you tomorrow!

*/
