---
title: "Comparing Standard Library Sorts: Generic Programming"
date: 2024-02-29T13:38:59-05:00
draft: true
tags: ["Sorting", "Generic Programming"]
series: []
summary: "This blog post compares generic programming features in several programming languages by studying how they handle sort routines."
authors: ["Michael Ferguson"]
---

<!-- Overall TODOs:
 * Why 3 methods for specifying key rather than one?
 * Why/How does Chapel support these generic patterns better than C++?
   * or Rust?
   * people might think of C++'s generics as equivalent or better
 * Sort 100 M elements and measure in M elements sorted / second
-->

<!--
TODO: abstract / teaser
-->

### Background

<!--
TODO: background
-->

### Radix Sorting

Chapel's easy and flexible support for generic programming make it
practical for the standard library `sort` to use a
{{< sidenote "right" "radix sort" >}}
  A radix sort is a sorting algorithm that operates by grouping
  elements according to their digits instead of by comparing elements.
{{< /sidenote >}}.
In contrast, most standard libraries aren't able to use a radix sort because
it would make the API too complex.

The reason this is an API issue is that a `sort` function needs to accept
some way of describing the desired order. Normally, this is done by
passing a comparison function to indicate which of two values should be
earlier in the sorted output when the algorithm is comparing them.
However, radix sorts don't use comparisons. Instead, they operate on a
conceptual *digit* at a time, and they group together data with the same
digit. As a real-world example, you can imagine one stage of a radix sort
with postcards. You might have a bin for each of the leading digits in
the destination zip code and put the postcards into these bins. No
pairwise comparisons are needed or used in this process. That process
would sort by the first digit, and then you could continue with more bins
to sort by other digits.

The Chapel `sort` uses a most-significant-byte-first radix sort. That
allows it to work with variable-length data, like strings. The
implementation has drawn quite a bit from earlier published works on
radix sorting [^1].

In my own experiments with parallel Chapel implementations, radix sorting
is 30–40% faster than the fastest comparison sort (which is inspired by
IPS4O [^2]).

The API needed for radix sorting relies much more on generic programming
than a comparison sort does. In particular, Chapel `sort` API allows
users to specify the sort order in 3 distinct ways:

 1. With a [`.key`
    method](https://chapel-lang.org/docs/modules/packages/Sort.html#the-key-method)
    to produce the key to sort by for an element.  The value returned by
    this method can be a number or a string. It's a common situation to
    have a record with multiple fields and to want to sort by a
    particular field. This API makes that easy, and it supports radix
    sorting when the returned value is a type that the library knows how
    to radix sort. That includes all the built-in numeric types, tuples
    of these, and also the `string` and `bytes` types. See the next
    section for an example.

 2. With a [`.compare`
    method](https://chapel-lang.org/docs/modules/packages/Sort.html#the-compare-method),
    which functions in a manner similar to the comparison routine one can
    pass to C's `qsort`.

 3. For advanced use cases, the API supports specifying the sort order
    with a [`.keyPart`
    method](https://chapel-lang.org/docs/modules/packages/Sort.html#the-keypart-method).
    This method can be called by a radix sort to get the next *digit*
    needed during radix sorting. This method supports variable-length
    data because it has a separate way of indicating when the end of a
    sequence is reached. That allows it to be used, for example, to
    describe how to radix sort a string-like type. And, in fact, that is
    how the default sort order for strings is implemented.

Chapel's support for generic programming support makes it straightforward
to provide a custom sort order. No need to add fields to help the
implementation to choose among the 3 ways. And, the generic sort implementation
is also much more straightforward than it would be in C++, in
my opinion. I speak from experience on this point, since I implemented
some similar functionality in C++ [for a previous
project](https://github.com/femto-dev/femto/blob/master/src/utils_cc/criterion.hh).

### Example using the .key method

Sorting 64-bit values by themselves isn't particularly realistic. It's
typical to want to sort records with some particular key. For example, in
a database, we might have a `person` record that has a primary key
`userId` and refers to another object with a `groupId`.

Suppose we had some `person` records and we want to sort them only by that
primary key. How would we do that?

{{< file_download fname="sort-records.chpl" lang="chapel" >}}

Here we used the `key` method of a comparator to specify what value to
sort by. But we still see very impressive performance!

```
$ chpl --fast sort-records.chpl
$ ./sort-records
Sorted 100000000 elements in 0.33638 seconds
297.283 million elements sorted per second
```

Note that the sort performance is about half of what it was when we only
sorted 64-bit elements. That's because memory bandwidth is the bottleneck
in the sort algorithm and we've just doubled the amount of data that
needs to be moved while the memory bandwidth remains fixed. So it runs
about half as fast.

<!-- TODO
  Right in terms of wallclock time it would go half as fast but not so if
  you are measuring MB/s... Should be better with million elements
  sorted/second
  -->


[^1]: Peter M McIlroy, Keith Bostic, and M Douglas McIlroy. 1993. Engineering radix sort. Computing systems 6, 1 (1993), 5–27.

[^2]: Axtmann, Michael; Witt, Sascha; Ferizovic, Daniel; Sanders, Peter (2017). "In-Place Parallel Super Scalar Samplesort (IPSSSSo)". 25th Annual European Symposium on Algorithms (ESA 2017). 87 (Leibniz International Proceedings in Informatics (LIPIcs)): 9:1–9:14.
