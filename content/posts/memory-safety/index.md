---
title: "Memory Safety in Chapel"
date: 2025-04-10
tags: ["Safety", "Language Comparison"]
series: []
summary: "A description of how Chapel's features for memory safety strike a balance between productivity and performance, with comparisons to other languages"
authors: ["Michael Ferguson"]
featured: True
---


Memory safety is a property of a programming language that helps to
prevent bugs in programs written in that language. This article describes
Chapel's memory safety features and how these features support Chapel's
goals of productivity and performance.

Chapel is designed to balance productivity, performance and scalability.
As a result, its memory safety features are not as comprehensive as
Python's (where performance is not as important) or Rust's (which has a
design that focuses primarily on safety).

This table shows how we see Chapel as comparing to the other technologies
studied here:

{{< alttable >}}
|                | C/C++  | Rust  | Python | MPI   | OpenSHMEM | Chapel |
|----------------|:------:|:-----:|:------:|:-----:|:---------:|:------:|
| Productivity   | ➖     | ✔️     | ➕     | ➖    | ➖        | ➕     |
| Performance    | ➕     | ➕    | ➖     | ➕    | ➕        | ➕     |
| Scalability    |        |       |        | ➕    | ➕        | ➕     |
| Safety         | ➖     | ➕    | ➕     | ➖    | ➖        | ✔️      |

<p style="text-align: center"> <b>Key:</b> ➕: great; ✔️: good; ➖: drawback</p>

Since this article is focused on the safety aspect, we'll consider how
Chapel compares to Rust, C, C++, and Python when it comes to common
memory-safety programming errors. The following table shows the errors we
will discuss and summarizes how each language does:

{{< alttable >}}
| Error                      | C      | C++   | Rust   | Python | Chapel |
|----------------------------|:------:|:-----:|:------:|:------:|:------:|
| Variable Not Initialized   | ❌     | ❌    | ✅     | ✅     | ✅     |
| Mishandling Strings        | ❌     | ⚠️     | ✅     | ✅     | ✅     |
| Use-After-Free             | ❌     | ⚠️     | ⚠️      | ✅     | ⚠️      |
| Out-of-Bounds Array Access | ❌     | ❌    | ✅     | ✅     | ⚠️      |

Here are the meanings of ❌, ⚠️ , and ✅ for the purposes of this article:

 * ✅ : The language prevents this type of error or responds to the error
 * ⚠️  : There is significant help from the language to avoid this type of
   error; however, programmers still need to take caution because such
   errors can cause undefined behavior in some situations
 * ❌ : The language doesn't offer much protection against this type of
   error, and such errors may result in undefined behavior

This article also evaluates out-of-bounds array accesses in the context of
communication in distributed-memory programming with MPI, OpenSHMEM, and
Chapel. This table summarizes the result:

{{< alttable >}}
| Error                          | MPI    | OpenSHMEM      | Chapel |
|--------------------------------|:------:|:--------------:|:------:|
| Out-of-Bounds in Communication | ❌     | ❌             | ⚠️      |


### Variable Not Initialized

Many programming languages provide a way to declare a variable without
initializing it. When using such a language, it's a common error to
forget to initialize a variable. What happens if you make that error?
We'll demonstrate it in this section with a program that declares a local
variable but doesn't initialize it.

##### C and C++

In C and C++, it's easy to declare a variable without initializing it, as
this example shows:

{{< file_download fname="unset-variable.c" lang="c" >}}

Unfortunately, programs like this in C and C++ print out *stack trash*,
that is, whatever memory happened to be stored in the memory used for the
variable:

``` console
$ gcc unset-variable.c
$ ./a.out
x is 32764
```

This can lead to hard-to-find bugs and, in the context of software
security, reveal information about a program to an attacker. The
situation is a little better in C++ because, for many types that didn't
exist in C, variables using that type are automatically initialized.
That applies to types like ``std::vector`` but not to the ``int`` used in this
example, because ``int`` is a type that C++ inherited from C, and for
which it needs to maintain compatibility.

##### Rust

Rust checks at compile-time that a variable is initialized before it is
used. As a result, the program below won't compile:

{{< file_download fname="unset-variable.rs" lang="rust" >}}

```console
$ rustc unset-variable.rs

error[E0381]: used binding `x` isn't initialized
 --> unset-variable.rs:3:13
  |
2 |     let mut x: i64; // OOPS! forgot to initialize x
  |         ----- binding declared here but left uninitialized
3 |     let y = x;
  |             ^ `x` used here but it isn't initialized
  |
help: consider assigning a value
  |
2 |     let mut x: i64 = 42; // OOPS! forgot to initialize x
  |                    ++++

error: aborting due to 1 previous error

For more information about this error, try `rustc --explain E0381`.
```

Note that Rust checks that local variables are initialized even in
`unsafe` blocks.

##### Python

In Python, it's just not possible to declare a variable; instead
variables are created the first time they are assigned to. So, this type
of error just isn't possible.

##### Chapel

In Chapel, variables are initialized to a default value if the type
supports it. Some variables can't be initialized to a default value, and
in those cases, the Chapel compiler will emit an error if the variable
is used before it is initialized.

For example, an ``int`` variable will be initialized to ``0``:

{{< file_download fname="unset-int-variable.chpl" lang="chapel" >}}

{{< console fname="unset-int-variable.out" >}}

{{< details summary="**(What if the variable can't be initialized to a default?)**" >}}

A variable can't be initialized to a default if it is declared without
a type, or if its type has no default value.

Chapel allows variables to be declared without a type. In this
case the variable's type will be inferred when it is initialized. That
won't work if it's used before it is initialized, so that case results in
an error:

``` chpl
proc main() {
  var x;
  writeln(x);
}
```

```console
unset-untyped-variable.chpl:1: In function 'main':
unset-untyped-variable.chpl:2: error: 'x' is not initialized and has no type
unset-untyped-variable.chpl:2: note: cannot find initialization point to split-init this variable
unset-untyped-variable.chpl:3: note: 'x' is used here before it is initialized
```

See https://chapel-lang.org/docs/language/spec/variables.html#split-initialization for more details on this feature.

A class type like `owned C` is an example of a Chapel type that has no
default value.  Class types in Chapel can be nilable or non-nilable;
meaning they can store `nil` or not. The type `owned C` is non-nilable ---
that is, a variable of that type can't store `nil`. Since `nil` is the
reasonable default value for classes and `owned C` can't be `nil`, the
variable<br> `var x: owned C;` can't be initialized with a default. As a
result, the compiler will give an error.

``` chpl
class C { }
proc main() {
  var x: owned C;
  writeln(x);
}
```

```console
$ chpl unset-owned-variable.chpl
unset-owned-variable.chpl:2: In function 'main':
unset-owned-variable.chpl:3: error: cannot default-initialize x: owned C
unset-owned-variable.chpl:4: error: use here prevents split-init
note: non-nilable class type 'borrowed C' does not support default initialization
note: Consider using the type owned C? instead
```

We'll discuss Chapel's classes and memory management further in the
[Use-After-Free section](#use-after-free).

{{< /details >}}

##### Summary

How well do each of these programming languages protect against
uninitialized memory?

 * ❌ **C and C++:** programmer beware!
 * ✅ **Python:** it's not possible to write a variable declaration separate from initializing a variable
 * ✅ **Rust:** checks at compile-time that each variable is initialized
   before it is used
 * ✅ **Chapel:** ensures at compile-time that each variable is initialized, possibly by setting it to a default value



### Mishandling Strings

General-purpose languages need to provide ways to manipulate strings, as
strings are a very common data type. To demonstrate, we'll create a little
program in each language that creates a string storing a greeting:

##### C

{{< file_download fname="string-greeting.c" lang="c" >}}

It's easy to cause a stack overflow for this program by providing a name longer than 16 characters:

```console
$ gcc string-greeting.c
$ ./a.out abcdefghijklmnopqrstuv
Hello abcdefghijklmnopqrstuv
*** stack smashing detected ***: terminated
Aborted (core dumped)
```

That's disastrous from a security perspective, and it could be
exploitable.  In practice, C programmers should know not to write code
like this. A better program would count the sizes of the strings to be
concatenated, allocate a new string on the heap, and use `stpncpy` and
`strlcat` instead of `strcpy` and `strcat`.

##### C++, Python, Rust, and Chapel

These newer languages have improved on the situation in C and include a
standard ``string`` type that avoids many of the
error-prone patterns of string manipulation in C. In particular,
appending to a string will resize it appropriately.

Since C programs can be valid C++ programs, it's possible to write an
unsafe program like the above in C++ too.

Here are the equivalent programs using the standard ``string`` type in these other languages:

{{< file_download_min fname="string-greeting.cpp" lang="c++" >}}

{{< file_download_min fname="string-greeting.py" lang="python" >}}

{{< file_download_min fname="string-greeting.rs" lang="rust" >}}

{{< file_download_min fname="string-greeting.chpl" lang="chapel" >}}

##### Summary

C is uniquely bad at string manipulation, but the other languages provide
mechanisms to avoid the most common issues.

 * ❌ **C:** programmer beware!
 * ⚠️  **C++:** It's possible to write the same error-prone code with
   ``strcat`` since C++ extends C. Programmers should use the
   ``std::string`` type to avoid these issues.
 * ✅ **Everything else:** the standard ``string`` type avoids these issues



### Use-After-Free

When allocating memory dynamically, a potential problem is reading or
writing memory that has already been freed.

##### C

C and C++ have a lot of flexibility with pointers. As a result, it's very
easy to read or write to memory that has been freed. This kind of error
can cause all manner of problems, since the writes could overwrite other
values in memory.

{{< file_download fname="use-after-free.c" lang="c" >}}

What happens when you compile and run such a program? If you are lucky,
it will crash. If you are unlucky, the error will cause a
difficult-to-detect data corruption issue.

``` console
$ clang use-after-free.c
$ ./a.out
a.out(38065,0x1fae94f40) malloc: Heap corruption detected, free list is damaged at 0x6000007bc020
*** Incorrect guard value: 96606699388929
a.out(38065,0x1fae94f40) malloc: *** set a breakpoint in malloc_error_break to debug
```

##### C++

C++ provides `std::unique_ptr` and `std::shared_ptr` to reduce the
chances of a use-after-free because the `free` calls are automatically
added. However, use-after-free is still possible.

For example, this program compiles, but it has a use-after-free:

{{< file_download fname="use-after-free.cpp" lang="c++" >}}

As with the similar C program, if you are lucky, the program will crash:

``` console
$ clang++ use-after-free.cpp --std=c++14     
$ ./a.out
a.out(47219,0x1fae94f40) malloc: Heap corruption detected, free list is damaged at 0x60000315c020
*** Incorrect guard value: 71734543777834
a.out(47219,0x1fae94f40) malloc: *** set a breakpoint in malloc_error_break to debug
```

##### Python

Python is a garbage-collected language, and so isn't susceptible to
use-after-free errors. It keeps memory allocated as long as it can be
referred to.

##### Rust

The Rust compiler issues an error in this case to prevent a
use-after-free.

{{< file_download fname="use-after-free.rs" lang="rust" >}}

``` console
$ rustc use-after-free.rs
error[E0506]: cannot assign to `buf` because it is borrowed
  --> use-after-free.rs:11:9
   |
6  |     let ref_to_val: &mut i32 = &mut *buf;
   |                                --------- `buf` is borrowed here
...
11 |         buf = Box::new(2); // replace the pointer
   |         ^^^ `buf` is assigned to here but it was already borrowed
...
16 |     println!("value: {}", ref_to_val);
   |                           ---------- borrow later used here

error: aborting due to 1 previous error

For more information about this error, try `rustc --explain E0506`.
```

Note that here, the ``borrow`` in the error message refers to the concept
of having a pointer to something without having any concern about when
that thing will be deallocated.

{{< details summary="**(The situation is different for unsafe code)**" >}}

However, code in ``unsafe`` blocks is not protected against use-after-free
and can produce undefined behavior:

``` rust
fn main() {
    // Allocate a an integer value on the heap
    let mut buf: Box<i32> = Box::new(1);

    // Create a pointer to the value
    let ptr: *mut i32 = &mut *buf as *mut i32;

    unsafe {
        *ptr = 10;         // modify the value through the pointer
                           //
        buf = Box::new(2); // free the pointer
        println!("value: {}", *ptr); // OOPS: use-after free, prints garbage

        drop(buf);         // explicitly drop 'buf' to avoid compiler error
    }
}
```

``` console
$ rustc use-after-free-unsafe.rs
$ ./use-after-free-unsafe  
value: -1495007200
```

{{< /details >}}

##### Chapel

Chapel provides automatic memory management for its types (arrays,
strings, ...) and `owned` and `shared` for class types to automatically
manage freeing classes.

Chapel includes compile-time lifetime checking that catches common errors,
but it is not exhaustive. It is designed to help programmers find problems
in their programs without requiring a lot of programmer effort. 

Here is an example of a program containing a use-after-free that is
detected by Chapel's lifetime checker. This program does not compile as a
result.

{{< file_download fname="use-after-free-scoped.chpl" lang="chapel" >}}

{{< console fname="use-after-free-scoped.out" >}}

In addition to ``owned``, ``shared``, and ``borrowed`` classes, Chapel
supports ``unmanaged`` classes, which require the user to be responsible
for freeing such memory when necessary, similar to classic C++.  While
this can be an important feature in some applications for
generality and/or performance, its use is generally discouraged since it can
potentially result in memory safety errors.

{{< details summary="What are some errors that Chapel's lifetime checker doesn't detect?" >}}

As mentioned, Chapel's lifetime checker takes a hands-off approach to
``unmanaged``. Using ``unmanaged`` is inherently unsafe but it is
sometimes necessary. Here's an example of a use-after-free that is not
detected at compile-time because the use of ``unmanaged`` opts out of
the checking:

``` chapel
class C { var x: int; }

{
  var x = new unmanaged C(42);
  delete x;
  writeln(x);
}
```

Here is a case that has a use-after-free due to aliasing. This case
goes beyond what we expect the Chapel compiler to handle.

``` chpl
class C { var x: int; }

{
  var x = new C(42);
  var b = x.borrow();  // b refers to the same class instance as x
  {
    x = new C(41);     // now x refers to a new class instance;
                       // the old class instance is deleted
  }
  writeln(b);          // use-after-free: b refers to a deleted instance
}
```

{{< /details >}}


##### Summary

The languages vary greatly in the extent to which use-after-free is an
issue:

 * ❌ **C:** use-after-free is very easy to accidentally write
 * ⚠️  **C++:** `unique_ptr` and `shared_ptr` help to some extent, but
   use-after-free is still possible to write
 * ⚠️  **Rust:** compile-time checking prevents a use-after-free in safe code,
   but a use-after-free is still possible in ``unsafe`` code
 * ✅ **Python:** the garbage collector avoids this issue
 * ⚠️  **Chapel:** automatic memory management for most types means that
   `free` need only be written when using ``unmanaged``. The compiler can
   detect and emit errors for some use-after-free situations, but it does
   not detect all such situations.



### Out-of-Bounds Array Access

Did you notice the bounds-checking errors in most of the string-greeting programs
above? For example, the C program uses `argv[1]` but does not check that there was an
argument passed. What does an out-of-bounds array access do in these
languages?

##### C and C++

There is no array bounds checking in C or C++. In fact, it's quite hard for a C
compiler to provide array bounds checking, because, in practice, C code
uses pointers as arrays, and there is not a consistent way for the
compiler to know where the array length is stored.

For example, consider this program that creates a 1-element array and
then accesses the $i^{th}$ element based on a command-line argument:

{{< file_download_min fname="out-of-bounds.c" lang="c" >}}

If the command-line argument is not 0, it will lead to an out-of-bounds
array access. At best, you get a program crash. At worst, you get a
hard-to-find memory corruption bug.

``` console
$ gcc out-of-bounds.c
$ ./a.out 123456789
zsh: segmentation fault  ./a.out 123456789
```

The story with a C++ vector is similar:

{{< file_download_min fname="out-of-bounds.cpp" lang="c++" >}}

``` console
$ g++ out-of-bounds.cpp
$ ./a.out 123456789
zsh: segmentation fault  ./a.out 123456789
```

C and C++ developers use address sanitizers or similar tools to find this
class of error. Additionally, the C++ standard library in use might have
a way to activate bounds checking for some types, such as
``-D_GLIBCXX_DEBUG``.

##### Python

Since Python includes array bounds checking, a similar program with an
out-of-bounds array access will cause an `IndexError: list index out of
range` error to be raised.

{{< file_download_min fname="out-of-bounds.py" lang="python" >}}

``` console
$ python3 out-of-bounds.py 123456789
Traceback (most recent call last):
  File "/Users/mferguson/chapel-blog/content/posts/memory-safety/code/out-of-bounds.py", line 10, in <module>
    main(sys.argv)
    ~~~~^^^^^^^^^^
  File "/Users/mferguson/chapel-blog/content/posts/memory-safety/code/out-of-bounds.py", line 6, in main
    x = array[idx]
        ~~~~~^^^^^
IndexError: list index out of range
```

##### Rust

Rust includes bounds checking, and failing a bounds check will cause the
program to panic (print out a message and halt).

{{< file_download_min fname="out-of-bounds.rs" lang="rust" >}}

``` console
$ rustc out-of-bounds.rs
$ ./out-of-bounds 123456789
thread 'main' panicked at out-of-bounds.rs:7:13:
index out of bounds: the len is 1 but the index is 123456789
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

Rust's bounds checking is active even in ``unsafe`` blocks.

##### Chapel

For Chapel, out-of-bounds array accesses are checked by default, but
disabled when the program is compiled with `--fast` or `--no-checks`.

When the program is compiled with bounds checks, the behavior is similar
to the Rust program. The program halts and prints an error about the
out-of-bounds access. For example, this program allocates a 10-element
array and accesses an index provided on the command line:

{{< file_download_min fname="out-of-bounds.chpl" lang="chpl" >}}

``` console
$ chpl out-of-bounds.chpl
$ ./out-of-bounds --idx=123456789
out-of-bounds.chpl:5: error: halt reached - array index out of bounds
note: index was 123456789 but array bounds are 0..9
```

However, if the program is compiled with checks disabled, as with
`--fast`, the out-of-bounds access causes undefined behavior. The program
might crash, or it might print out garbage values.

``` console
$ chpl --fast out-of-bounds.chpl
$ ./out-of-bounds --idx=123456789
zsh: segmentation fault  ./out-of-bounds --idx=123456789
```

Chapel's array bounds checks are disabled with `--fast` in order to
achieve maximum performance. The expectation is that such program errors
will be found and resolved during development and testing where bounds
checking will be enabled.

##### Summary

Bounds checking in these languages varies from opt-in to opt-out to
always on:

* ❌ **C and C++:** out-of-bounds array accesses aren't checked unless running
  with a memory-checking tool
* ✅ **Rust:** out-of-bounds array accesses cause the program to halt with an
  out-of-bounds error
* ✅ **Python:** out-of-bounds array accesses raise an error
* ⚠️  **Chapel:** with `--checks` (the default), out-of-bounds array accesses
  cause the program to halt; with `--fast`, these checks are disabled to
  improve performance

### Out-of-Bounds Array Access in Distributed Memory

Chapel is a language designed for distributed-memory parallel computing,
so we'll compare Chapel with [MPI](https://www.mpi-forum.org/) and
[OpenSHMEM](http://openshmem.org), which are distributed-memory parallel
computing frameworks usable from C and C++.

What will happen with an out-of-bounds array access in the context of a
distributed-memory parallel program?

##### C/C++ with MPI and OpenSHMEM

MPI and OpenSHMEM have a C interface that precludes bounds checking.

Here is a C and MPI example using ``MPI_Gather`` that provides a count
too large that overflows the local buffer:

{{< file_download_min fname="out-of-bounds-mpi.c" lang="c" >}}

First, here's what it looks like to compile and run it when there is no
out-of-bounds access. In this case, any index less than 1000 will not
lead to a memory safety violation.

``` console
$ mpicc out-of-bounds-mpi.c
$ mpirun -n 3 ./a.out 2
Correct gather:
  0
  1
  2
Potentially bad gather:
  0
  0
  1
  1
  2
  2
```

Providing a count beyond the size of the array leads to incorrect results
or core dumps:

``` console
$ mpirun -n 3 ./a.out 123456789

Correct gather:
  0
  1
  2
[iris:24725] Read -1, expected 493827156, errno = 14
[iris:24725] *** Process received signal ***
[iris:24725] Signal: Segmentation fault (11)
[iris:24725] Signal code: Address not mapped (1)
[iris:24725] Failing at address: 0x5ebb9f222880
[iris:24726] *** Process received signal ***
[iris:24726] Signal: Segmentation fault (11)
[iris:24726] Signal code: Address not mapped (1)
[iris:24726] Failing at address: 0x55ae28cd6000
[iris:24725] [ 0] [iris:24726] [ 0] /lib/x86_64-linux-gnu/libc.so.6(+0x45250) [0x70976c845250]
[iris:24725] [ 1] /lib/x86_64-linux-gnu/libc.so.6(+0x45250) [0x731ed9c45250]
[iris:24726] [ 1] /lib/x86_64-linux-gnu/libc.so.6(+0x1ae906) [0x731ed9dae906]
[iris:24726] [ 2] /usr/lib/x86_64-linux-gnu/openmpi/lib/openmpi3/mca_btl_vader.so(+0x338d) [0x731ed800738d]
[iris:24726] [ 3] /usr/lib/x86_64-linux-gnu/openmpi/lib/openmpi3/mca_pml_ob1.so(mca_pml_ob1_send_request_schedule_once+0x1b9) [0x731ed3e51ab9]
[iris:24726] [ 4] /lib/x86_64-linux-gnu/libc.so.6(+0x1ae962) [0x70976c9ae962]
[iris:24725] [ 2] /lib/x86_64-linux-gnu/libopen-pal.so.40(opal_convertor_unpack+0x85) [0x70976cab4b55]
[iris:24725] [ 3] /usr/lib/x86_64-linux-gnu/openmpi/lib/openmpi3/mca_pml_ob1.so(mca_pml_ob1_recv_request_progress_frag+0x13f) [0x70976b05f5af]
[iris:24725] [ 4] /usr/lib/x86_64-linux-gnu/openmpi/lib/openmpi3/mca_btl_vader.so(mca_btl_vader_poll_handle_frag+0x95) [0x70976bc36d15]
[iris:24725] [ 5] /usr/lib/x86_64-linux-gnu/openmpi/lib/openmpi3/mca_btl_vader.so(+0x8064) [0x70976bc37064]
[iris:24725] [ 6] /usr/lib/x86_64-linux-gnu/openmpi/lib/openmpi3/mca_pml_ob1.so(mca_pml_ob1_recv_frag_callback_ack+0x211) [0x731ed3e50881]
[iris:24726] [ 5] /usr/lib/x86_64-linux-gnu/openmpi/lib/openmpi3/mca_btl_vader.so(mca_btl_vader_poll_handle_frag+0x95) [0x731ed800bd15]
[iris:24726] [ 6] /usr/lib/x86_64-linux-gnu/openmpi/lib/openmpi3/mca_btl_vader.so(+0x8064) [0x731ed800c064]
[iris:24726] [ 7] /lib/x86_64-linux-gnu/libopen-pal.so.40(opal_progress+0x34) [0x70976ca9d6f4]
[iris:24725] [ 7] /lib/x86_64-linux-gnu/libmpi.so.40(ompi_request_default_wait+0x55) [0x70976cc35ed5]
[iris:24725] [ 8] /lib/x86_64-linux-gnu/libopen-pal.so.40(opal_progress+0x34) [0x731ed9ab86f4]
[iris:24726] [ 8] /usr/lib/x86_64-linux-gnu/openmpi/lib/openmpi3/mca_pml_ob1.so(mca_pml_ob1_send+0x2b5) [0x731ed3e4f8f5]
[iris:24726] [ 9] /lib/x86_64-linux-gnu/libmpi.so.40(ompi_coll_base_gather_intra_linear_sync+0xd2) [0x731ed9f369e2]
[iris:24726] [10] /usr/lib/x86_64-linux-gnu/openmpi/lib/openmpi3/mca_coll_tuned.so(ompi_coll_tuned_gather_intra_dec_fixed+0x83) [0x731ed3e2c333]
[iris:24726] [11] /lib/x86_64-linux-gnu/libmpi.so.40(ompi_coll_base_gather_intra_linear_sync+0x38c) [0x70976cc90c9c]
[iris:24725] [ 9] /usr/lib/x86_64-linux-gnu/openmpi/lib/openmpi3/mca_coll_tuned.so(ompi_coll_tuned_gather_intra_dec_fixed+0x83) [0x70976b046333]
[iris:24725] [10] /lib/x86_64-linux-gnu/libmpi.so.40(PMPI_Gather+0x173) [0x731ed9effb93]
[iris:24726] [12] ./a.out(+0x1426) [0x55ae048c7426]
[iris:24726] [13] /lib/x86_64-linux-gnu/libmpi.so.40(PMPI_Gather+0x173) [0x70976cc59b93]
[iris:24725] [11] ./a.out(+0x1426) [0x5ebb76730426]
[iris:24725] [12] /lib/x86_64-linux-gnu/libc.so.6(+0x2a3b8) [0x70976c82a3b8]
[iris:24725] [13] /lib/x86_64-linux-gnu/libc.so.6(+0x2a3b8) [0x731ed9c2a3b8]
[iris:24726] [14] /lib/x86_64-linux-gnu/libc.so.6(__libc_start_main+0x8b) [0x731ed9c2a47b]
[iris:24726] [15] ./a.out(+0x11a5) [0x55ae048c71a5]
[iris:24726] *** End of error message ***
/lib/x86_64-linux-gnu/libc.so.6(__libc_start_main+0x8b) [0x70976c82a47b]
[iris:24725] [14] ./a.out(+0x11a5) [0x5ebb767301a5]
[iris:24725] *** End of error message ***
--------------------------------------------------------------------------
Primary job  terminated normally, but 1 process returned
a non-zero exit code. Per user-direction, the job has been aborted.
--------------------------------------------------------------------------
--------------------------------------------------------------------------
mpirun noticed that process rank 0 with PID 0 on node iris exited on signal 11 (Segmentation fault).
--------------------------------------------------------------------------
```

Similarly, an out-of-bounds array access in OpenSHMEM might lead to
incorrect results, hard-to-reproduce bugs, or core dumps:

{{< file_download_min fname="out-of-bounds-shmem.c" lang="c" >}}

In this case, the value we got should be ``0x1010101`` if it is valid:

``` console
$ oshcc out-of-bounds-shmem.c
$ oshrun -np 3 ./a.out  1
Got value 0x1010101
```

Providing an index beyond the array bounds leads to incorrect results and
possibly core dumps:

``` console
$ oshrun -np 3 ./a.out  2000
Got value 0
$ oshrun -np 3 ./a.out  123456789
[iris][[45244,1],2][pshmem_put.c:156:pshmem_int_put] Required address 0x11c6f3524 is not in symmetric space
--------------------------------------------------------------------------
SHMEM_ABORT was invoked on rank 2 (pid 55917, host=iris) with errorcode -1.
--------------------------------------------------------------------------
```

Address sanitizers and similar tools are difficult to use in this
context. Ideally, the network hardware provides support for ``shmem_int_put``. As a result,
the out-of-bounds access won't necessarily even occur in code run by the
processor! It's likely to make the program halt, but it can be
challenging to figure out what caused the out-of-bounds array access.

##### Distributed-Memory Programs in Chapel

A distributed Chapel program has the same level of bounds-checking
support as a non-distributed Chapel program.

For example, this program creates a distributed array and then accesses
the index provided on the command line (which might be out of bounds):

{{< file_download_min fname="out-of-bounds-dist.chpl" lang="chpl" >}}

First, let's show what happens if the index is in bounds:

``` console
$ chpl out-of-bounds-dist.chpl
$ ./out-of-bounds-dist -nl 3 --idx=1
array at index 1 is 0
```

If the index is not within bounds, you get an out-of-bounds error at
run-time (provided it is compiled with bounds checking on, e.g., without
`--fast`):

``` console
$ ./out-of-bounds-dist -nl 3 --idx=1000
out-of-bounds-dist.chpl:8: error: halt reached - array index out of bounds
note: index was 1000 but array bounds are 0..99
```

##### Summary

Bounds-checking errors when using MPI or OpenSHMEM cause undefined
behavior and can be challenging to debug. In contrast, Chapel is unique
in providing bounds checking for distributed-memory programming. 

* ❌ **MPI, OpenSHMEM:** these distributed-memory programming frameworks
  can't easily provide bounds checking due to their pointer-based C
  interface. Moreover, it can be challenging to debug these errors even
  when using an address sanitizer or similar tool.
* ⚠️  **Chapel:** with `--checks` (the default), out-of-bounds array accesses
  on distributed arrays cause the program to halt; with `--fast` these
  checks are disabled to improve performance.



### Conclusion

Memory safety in Chapel provides for productivity, safety, and
performance. Chapel is significantly safer than C and C++, and
significantly safer than using MPI or OpenSHMEM for distributed-memory
programming. Compared to Python, Chapel is able to achieve higher
performance because it's a compiled, statically-typed language, and it
does not need a garbage collector. Compared to Rust, Chapel is able to
provide safety when requested without requiring programmers to prove to
the compiler that the code is correct.
