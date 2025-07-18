---
title: "Changes to Chapel 2.0 Since its First Release Candidate"
date: 2024-02-27
tags: ["Chapel 2.0"]
series: []
summary: "A summary of breaking and other notable additions made since Chapel 1.32"
authors: [Lydia Duncan, Jeremiah Corrado, Jade Abraham, Shreyas Khandekar]
---

As you may be aware, [the Chapel 1.32 release was considered a
candidate for becoming the future Chapel 2.0 release.]({{< relref "announcing-chapel-1.32/index.md#chapel-20-release-candidate" >}})  Our intention as a team was to have
any breaking changes made for that release, so that users could rely on the
presence of deprecation and unstable warnings to know about any features that
were changing or subject to change in upcoming releases.  We made it a release
candidate for 2.0 so that we could solicit feedback and have a chance to gain
experience with the state of the language, enabling final tweaks and polish
as required before the official 2.0 release.

Since 1.32, we've been hard at work responding to your feedback (both public and
private), as well as performing a perusal of our own, to ensure that the 2.0
release will be as good as it can be.  To that end, we have made some notable
changes that we wanted to call to your attention before making the March
release our official 2.0.  If any of these changes strike you as wrong or
worrying, please don't hesitate to reach out.

### Newly Stabilized Features

These features were not originally intended to be stable for 2.0, but we were
able to find the time to discuss and work on them, bringing them to a stable
state.

#### Changes to the `Random` Module

As of Chapel 1.32, the Random module was unstable as a whole. It contained an
abstract `RandomStreamInterface` as well as two algorithms that implemented the
interface:
[PCG](https://chapel-lang.org/docs/1.32/modules/standard/Random/PCGRandom.html)
and
[NPB](https://chapel-lang.org/docs/1.32/modules/standard/Random/NPBRandom.html).
Both random stream types were designed to provide a notion of an iterable
stream of pseudo-random values of a given type. There were also several symbols
used to select between the two algorithms, as well as a variety of top-level
procedures that mirrored the `RandomStream` methods.

Feedback from users indicated that they were interested in a stable `Random`
module with a simpler set of features. To accomplish this, several very
significant changes to the module's design were made in Chapel 1.33 (the
latest release as of this article's publication). Some more minor API
changes on the remaining unstable symbols are slated for the upcoming
release.

For 1.33, the [PCG
class](https://chapel-lang.org/docs/1.33/modules/standard/Random/PCGRandom.html#PCGRandom.PCGRandomStream)
was deprecated and the [NPB
class](https://chapel-lang.org/docs/1.33/modules/packages/NPBRandom.html#NPBRandom.NPBRandomStream)
was moved to its own package module. Both types, as well as the `RandomStream`
alias and interfaces, were replaced by a single `randomStream` record
implemented using the more capable PCG algorithm. This type's interface is very
similar, and it is still meant to represent a conceptual stream of random
numbers that can be iterated over in parallel.  In many cases, switching to
the new type involves
{{< sidenote "right" "a very simple code change:" >}}
Beyond the obvious capitalization changes, the meaning of the type
argument `real` also changes slightly. For `RandomStream` it meant
that the stream would maintain enough internal state to generate values of
_any_ type with the same or smaller size as the stream's type. So in this
case, `rs` could produce random values of any numeric type with 64
or fewer bits. With the new `randomStream`, it will only be able to
generate `real` values. Another `randomStream` would need
to be created to generate values of other numeric types. This change resulted
in various simplifications to the interface. {{< /sidenote >}}

```Chapel
var rs = new RandomStream(real, seed, parSafe=false);  // before 1.33
var rs = new randomStream(real, seed);  // in 1.33 (note the capitalization)
```

One significant difference with switching to a record is that the new type has
value semantics. This means that assigning one `randomStream` to another will
copy its internal state and seed. In the old design, reference semantics were
used, meaning that the two variables pointed at the same underlying random
stream. As a result, more care was necessary when accessing random stream
variables from multiple tasks concurrently.

Additionally, there is no longer a `parSafe` parameter available on the
`randomStream` type. This makes the type lighter-weight but also means that
separate locking or synchronization is needed when accessing a single random
stream variable with concurrent tasks. In some cases it is useful to avoid the
need for synchronization by constructing a random stream per task when
executing concurrent operations. For example, the following code uses this
strategy to fill an array with random values in parallel:

```Chapel
var A: [1..1000] int;
forall a in A with (var rs = new randomStream(int)) do
  a = rs.getNext();
```

Alternatively, the `fill` method can be used to accomplish the same thing (also
executing in parallel under the hood):

```Chapel
var A: [1..1000] int,
    rs = new randomStream(A.idxType);
rs.fill(A);
```


The `Random` module's top-level procedures were also modified slightly to accommodate
these changes. Specifically, the default-valued arguments for selecting between
the PCG and NPB algorithms were removed. In programs where this argument wasn't
specified, no code changes are required. For example, the following code would
remain the same between releases:

```Chapel
var A = [i in 1..10] i;
shuffle(A);
```

But this code would need to remove the `algorithm` argument:

```Chapel
var A = [i in 1..10] i;
shuffle(A, algorithm = RNG.PCG);
```

The NPB algorithm can still be used via the
[`NPBRandom`](https://chapel-lang.org/docs/1.33/modules/packages/NPBRandom.html)
package module.

In 1.33, the `Random` module
was no longer unstable as a whole, but the following symbols remained unstable
pending some name changes and interface improvements planned for the upcoming
release:

* **`permutation`**: to be replaced by new `permute` procedures
* **`choice`**: to be replaced by a simplified `choose` / `sample` interface
* **`getNext`**: to be renamed to `next`
* **`skipToNth`**: to be renamed to `skipTo`
* **`getNth`**: to be deprecated
* **`iterate`**: to be renamed to `next` (overloading the single-value version)
* **default seed initialization**: will use an improved algorithm for generating default seeds

With the above changes coming in the March release, the module is expected to be
fully stable. There are future plans to expand the parallel iteration
capabilities, as well as to create a more formal random stream interface (or
interfaces) making use of Chapel's newer [interface
features](https://chapel-lang.org/docs/1.33/technotes/interfaces.html) — this may
lead to the introduction of some other random number generator algorithms.
We also expect to explore the addition of some other types like a global,
parallel-safe random number generator. We welcome any feedback from users on
the direction taken so far, as well as future goals for the module.

#### Default Task Intent For Arrays

In 1.32, we made some big changes to the default
{{< sidenote "right" "intent" >}}
Chapel uses intents to define how variables are passed to functions and
parallel constructs. These are called _argument intents_ for functions and
_task intents_ for parallel constructs. For example, a
`const ref` argument intent causes a constant reference to the actual argument to be passed into the function, while an `in` task intent creates a
task-private mutable copy of the original variable.

See the primers on
[procedures](https://chapel-lang.org/docs/1.33/primers/procedures.html) and
[task parallel constructs](https://chapel-lang.org/docs/1.33/primers/taskParallel.html)
for examples and more information.
{{< /sidenote >}}. This change meant that arrays, which previously had a
special intent, were now always passed by `const` to functions and tasks unless
an explicit intent was requested. This same change was also made to record
methods, removing the special intent for the record receiver `this`.

After receiving some feedback from users that this change created overly
verbose code for parallel loops operating on arrays, we made an improvement.
The default task intent for arrays was changed to be inferred from the array
itself, so a `const` array has a default `const` task intent and a `var` array
has a default `ref` task intent. Essentially, if an array is modifiable outside
a parallel block, it is modifiable inside a parallel block.

Consider the following code, where a procedure uses an explicit parallel loop to
increment elements in an array:

```Chapel {file_name=modifyArrayExtraIntent.chpl}
proc incArray(ref arr: [?dom] int) {
  forall i in dom with (ref arr) {
    arr[i] += 1;
  }
}
```

This code explicitly uses a `ref` task intent on a parallel loop, and in 1.32
this was required to prevent unstable warnings. Today, this code can remove the
explicit `ref` task intent, since the `arr` has already been marked as
modifiable by the `ref` argument intent on the procedure:


```Chapel {file_name=modifyArray.chpl}
proc incArray(ref arr: [?dom] int) {
  forall i in dom {
    arr[i] += i;
  }
}
```

The result of this change has been a simplification of the default intent rules, while still being able to write concise and clear code.

#### Promoted Array Indexing

Chapel provides some powerful array programming features that can greatly
improve code readability and programmer productivity. Using promotion, arrays
can be selectively updated based on a set of indices. For example, this program
increments all values that have an even index:

```Chapel {file_name=promotedIndexing.chpl}
var arr = [i in 1..100] i;
const indices = [i in arr.domain by 2] i;
arr[indices] += 1;
```

However, this powerful syntax does have sharp edges. In the above example, if
`indices` contained any duplicate elements, the increment would have caused an
unsafe race condition. With duplicate elements, the above code requires explicit
ordering or synchronization to be applied to the increment to prevent races.

{{< details summary="How can I write this pattern without the race?" >}}

Here is one way using `reduce` intents:

```Chapel {file_name=promotedIndexing-reduce.chpl}
var arr = [i in 1..100] i;
const indices = ...expression containing duplicates...;
[i in indices with (+ reduce arr)] arr[i] += 1;
```

Here is another way using `atomic` variables:

```Chapel {file_name=promotedIndexing-atomic.chpl}
var arr: [1..100] atomic int;
arr.write([i in arr.domain] i);
const indices = ...expression containing duplicates...;
arr[indices].add(1);
```

{{< /details >}}

In the interest of improving the safety and consistency of Chapel code, we
initially thought we wouldn't include this feature in 2.0. However, after the aforementioned changes
to the default task intent for arrays, we felt that this feature should be reinstated for consistency and convenience, with
some additional and optional safety rails. To achieve this, we added the
compilation flag<br> `--warn-potential-races`, which warns for code patterns like
this that may be unsafe.


#### Class Memory Management

For the last few Chapel releases using stable features, it was not possible to escape the <a href="https://chapel-lang.org/docs/1.33/technotes/lifetimeChecking.html">lifetime checker</a>
when using managed classes like `owned` and `shared`. These
management strategies use the lifetime checker to ensure that memory is not
accessed incorrectly. It is sometimes necessary to have pieces of code that a
developer knows to be correct bypass the lifetime checker. To enable this,
we have stabilized a cast to an `unmanaged` class. This cast does not affect
the original lifetime of the object, it merely provides a view of the object
that is not tracked by the lifetime checker.

For example, the following code passes an `unmanaged` view of an `owned` class into a procedure that expects an `unmanaged` instance:

```Chapel {file_name=modifyArray.chpl}
var myOwnedObject = new MyClass();
unsafeApiCall(myOwnedObject.borrow(): unmanaged);
```

This allows programs to get the benefits of the lifetime checker for the majority of the code and to opt-out when needed.

#### Associative Domains

Associative domains have been stabilized to prioritize performance by
default; however, some diligence is crucial for optimal use.

Associative domains in Chapel have a `parSafe` setting that
determines their behavior when
{{< sidenote "right" "operated on by concurrent tasks." -25>}}

`parSafe` stands for "parallel safety". Setting
`parSafe=true` allows for multiple tasks to modify
an associative domain's index set concurrently without race conditions.
It is important to note that `parSafe=true` does not protect the
user against all race conditions. For example, iterating over an associative
domain while another task modifies it represents a race condition and the
behavior is undefined.

See the [documentation](https://chapel-lang.org/docs/1.33/language/spec/domains.html?highlight=parsafe#parallel-safety-with-respect-to-domains-and-arrays)
on parallel safety for domains for examples and more information.

{{< /sidenote >}} The default of `parSafe=true` {{< sidenote "right"
"added overhead" 2>}} The setting `parSafe=true` adds
overhead because it uses locking on the underlying data structure each time the
domain is modified. This overhead is unnecessary, for example, when the domain
is operated upon by a single task. {{< /sidenote >}}
to the operations and made programs slower by default, even when such safety
guarantees were not needed.
Because of this we have changed their default from
`parSafe=true` to `parSafe=false`.
With this change, associative domains have been stabilized, except for domains
requesting `parSafe=true`.

For example, a new associative domain, like `d1` below, will have its default
`parSafe` value be `false`. It will also issue a warning to users, alerting
them of the changing default. Domains with an explicit `parSafe` value
like `d2` do not issue such warnings:
```Chapel {file_name=defaultAssociativeDomain.chpl}
var d1: domain(int);                 // warns
var d2: domain(int, parSafe=false);  // does not warn
```
Domains like `d3` with `parSafe=true` will continue to generate unstable
warnings when compiled with `--warn-unstable`:

```Chapel {file_name=assocDomainUnstable.chpl}
  var d3: domain(int, parSafe=true);  // generates unstable warning
```

More information about the new warning, where it is issued, how it can be
silenced, and how the transition can be made easier will be provided in
the upcoming release notes.

### Breaking Changes

For the following features, we thought we had the correct behavior, but we realized we
needed to change them before the official 2.0 release.  Some of these were
motivated by feedback from users like you, while others were noticed as part of our
own development work.

#### Renamed the `ioendian` enum to `endianness`

We've renamed the `ioendian` enum, used to specify byte order for file I/O,
to `endianness`.
This change was made for the following reasons:
  * Enhanced Clarity: The new name accurately reflects the property's independence from I/O,
  making code easier to understand and maintain.
  * Adherence to Convention: `endianness` aligns with our [established naming
  conventions.](https://chapel-lang.org/docs/1.33/developer/bestPractices/StandardModuleStyle.html)
  promoting consistency across the codebase. `ioendian` did not align due to its
  failure to capitalize `endian`.

Importantly, the constants within the `endianness` enum remain unchanged,
reducing the number of updates needed for existing code.

#### Altered Format for the Binary Serializer/Deserializer

The 1.32 release saw the introduction of serializers (for writing) and
deserializers (for reading) as a way of controlling the formatting of file input
and output.  [Serializers and
deserializers](https://chapel-lang.org/docs/1.33/technotes/ioSerializers.html)
replaced the old strategy for I/O, which had relied heavily on a single type
(`iostyle`) to control everything needed for the widely-varying forms
of input and output.  Each serializer/deserializer pair became responsible for
a single particular format of I/O.

When we added the binary serializer and deserializer to replace the old handling
for binary I/O, we had originally made the formatting for certain types
include additional meta-information.  In the case of strings and bytes, this
would include their lengths.  In the case of classes, this would indicate whether
the class value was `nil`.

This change in default behavior was surprising to some users, so we moved this
functionality to an alternative, unstable serializer/deserializer in the new
`ObjectSerialization` module, restoring the old, "unstructured" behavior to the
binary serializer and deserializer.

This means that the binary deserializer no longer supports reading strings and
bytes — Chapel strings and bytes {{< sidenote "right"
"do not include a null-terminator," >}} This enables the string or bytes to
contain null characters. {{< /sidenote >}} so without a length there is no way
to determine when the string or bytes value ends.  Instead, a method such as
`fileReader.readBinary` should be used.


### New Warnings

#### Adjustments to Comparison Operators

Comparison operators such as `<`, `>`, `!=`, etc. used to be arbitrarily
chainable.  This meant that it was syntactically possible to write:

```Chapel {file_name=compOps.chpl}
if a < b < c then ...
```

However, such code would not necessarily behave as expected for someone coming
from a math or Python perspective.  Instead of ensuring that `b` was both
greater than `a` and less than `c`, what would happen is that the first portion
(`a < b`) would be evaluated and transformed into a boolean representing the
outcome, and that resulting boolean would then be compared to `c` (using the
numeric value of `0` for `false` and `1` for `true`).  This followed the
precedent established by languages like C.

This meant that if the code had defined `a`, `b`, and `c` like so:

```Chapel {file_name=compOps.chpl}
var a = 1,
    b = 7,
    c = 5;
```

then the expression would evaluate to `true`, which may not be what the user
intended.

To rectify this potential source of confusion, we've changed such expressions to
now be syntax errors.


#### Added Checks When `const` Arguments are Indirectly Modified

When the `const` intent is used to declare an argument to a function, the actual
intent is determined to be either `const in` or `const ref`.  For optimization
purposes, it may be beneficial for the compiler to adjust which actual intent is
selected in the future.

In the case where the actual intent becomes `const ref`, it is possible for the
contents of the argument to be modified by another part of the code while the
function is executing.  This can happen when the function is called in parallel,
or if the function modifies a variable with broader scope.  For instance,
the following code, though serial, will cause the argument to be indirectly
modified:

{{< file_download fname="indirectMod.chpl" lang="chapel" >}}

producing:

{{< console fname="indirectMod.1-0.good" >}}

This behavior can be surprising, especially in the case where the argument's
type is generic, and relying on it would mean that adjusting the actual intent
in the future would break programs rather than being an optimization.  With that
in mind, `const` intents should be considered an assertion on the part of the
programmer that such indirect modifications will not occur.  An unstable warning
will now be generated when compiling with `--warn-unstable` when we detect that an
indirect modification has occurred:

{{< console fname="indirectMod.2-0.good" >}}

If the indirect modification is intentional, the warning can be silenced by
using an explicit `const ref` intent for the argument:

```Chapel
proc takeRec(const ref r: rec) { ... }
```

If the indirect modification is not intentional, the modification can be
prevented by using an explicit `const in` intent:

```Chapel
proc takeRec(const in r: rec) { ... }
```

producing:

```console
(x = 15)
(x = 15)
```

Due to concerns about the performance impact of such checks, only shallow
indirect modifications will be noticed.  For instance, if a record contains a
class field and the field's contents are modified, no warning will be generated.

This warning will also trigger when arguments relying on a default intent of `const` are
indirectly modified.


#### Added/Extended Warnings When Symbol Shadowing Might Be Surprising

In scenarios where multiple symbols share the same name, it is not always easy
to determine which one is being referenced.  The language has a particular set
of rules to follow, but language constructs like `use` statements can affect
what is considered the best candidate, leading to confusion on the part of the
user.

Our goal has been to simplify such rules when possible, adding warnings when
the result may be surprising.  We recently added and extended some warnings
along those lines.

As an example, because of the order of `use` statements, the following code will
not rely on the contents of the top level module `N`.  Instead, `M`'s submodule named `N` will be used:

{{< file_download fname="shadowing.chpl" lang="chapel" >}}

Our recent work has added a warning to alert users to this potential for confusion, so compiling and running this program
will now produce:

{{< console fname="shadowing.good" >}}

Such warnings are intended to help clarify behavior and to call attention to cases
where a program is perhaps not behaving in a way the user would otherwise
expect.

### What's Next?

With the above changes, the official 2.0 release is scheduled for this coming
March.  This will mark a new chapter in Chapel's history, where users can rely
on the stability of core language features.  Applications developed using these
stable features will only require updates on your schedule, rather than because
a new version of Chapel has been released.

Though more remains to be stabilized, with the guidance of users like you we
will continue to be hard at work making Chapel the language of the future.
Thank you for all the feedback and support you have already provided.
