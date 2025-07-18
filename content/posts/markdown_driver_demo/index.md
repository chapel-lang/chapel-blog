---
title: "Markdown Driver Demo"
date: 2022-11-18T15:19:57-08:00
draft: true
tags: ["Demo", "Markdown"]
authors: ["Daniel Fedorin"]
summary: "Using Markdown as the primary content format is another way to write Chapel blog articles."
---

There are two modes of writing blog articles about Chapel.

1. __Your Chapel file "drives"__: the code is the ground truth. You write
   a single `.chpl` file, which is meant to be compiled run. This file has
   comments which describe what the file is doing; these comments are written
   in Markdown, and extracted by a script into a `.md` file. The `.md` file
   is never manually modified.

   This works well for small-to-medium articles, but has its issues. For instance,
   what if you have multiple files that you'd like to talk about?

Anyway, etc., etc..

Here's some code that's extracted into its own source file:

```Chapel {file_name=test.chpl}
proc collatz(x: int(64)) {
    if x == 1 { return; }

    if x % 2 == 0 {
        collatz(x/2);
    } else {
        collatz(x*3+1);
    }
}
```

And now we can talk about the above. The Collatz Conjecture states that
bla bla bla. Unsolved problems in mathematics. Cool.

We can now put more code into our test file.

```Chapel {file_name=test.chpl}
collatz(13);
```

We can even add code from inside bulleted lists.

1. We want to test the base case of the file! Lorem ipsum dolor sit amet.
   ```Chapel {file_name=test.chpl}
   collatz(1);
   ```
2. We want to test recursive calls, too.
   ```Chapel {file_name=test.chpl}
   collatz(8);
   ```
