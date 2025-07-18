// Generic Linear Multistep Method Evaluator using Chapel
// tags: ["Compile-time Computation", "Generic Types", "Math", "Differential Equations"]
// summary: "In this article, we use advanced features of the Chapel type system to implement a general linear multistep method evaluator for approximating differential equations."
// authors: ["Daniel Fedorin"]
// date: 2024-05-13

/*
  In addition to its powerful tools for parallel and distributed computing, Chapel has a very
  pleasant and unique mix of features for general-purpose programming. Among
  those features is Chapel's support for generics and type-level computation.
  In particular, Chapel lets you define functions that perform computations
  on types at compile-time. This allows one to specialize the behavior
  of a particular generic function depending on its type arguments. Since
  types are {{< sidenote right "only present at compile-time," >}}
  Certain types in Chapel actually have a runtime component. This is specifically
  true for arrays, where the array's domain --- the indices it allows, and
  their distribution across various nodes --- is a runtime value. This supports
  resizing and dynamic allocation of arrays, but it does muddy the waters
  a bit in terms of what "compile-time type computation" means.
  {{< /sidenote >}}
  there's generally no runtime cost to operating on them. In other words:
  __we can write functions that accept a type argument, which has no runtime
  costs and allows us to customize the behavior of the function.__

  There are infinitely many ways to make use of this feature, but
  here I will present a concrete example. We'll look at a certain subset of
  [linear multistep methods](https://en.wikipedia.org/wiki/Linear_multistep_method),
  which are a family of related numerical algorithms. The algorithms from
  this subset have different numbers of initial parameters and have different
  behavior, but the behavior and initial parameters are all derived from
  each method's list of coefficients. Thus, by passing a type-level
  list of coefficients to a generic linear multistep method evaluator,
  we'll be able to select which algorithm we want to use --- without writing
  the code for each particular method explicitly. Moreover, since the list
  of coefficients is a type-level construct, each resulting function will
  perform as well as an explicitly-written implementation would.

  ### Euler's Method
  Suppose we have a (first-order) differential equation. Such a differential
  equation has the form:

  $$
  y' = f(t, y)
  $$

  That is, the value of the derivative of \(y\) (aka \(y'\)) at any point \(t\)
  depends also on the value of \(y\) itself. You want to figure out what the
  value of \(y\) is at any point \(t\). However, there is no general solution to
  such an equation. In the general case, we'll have to settle for approximations.

  Here is a simple approximation. Suppose that we knew a starting point for our
  \(y\). For instance, we could know that at \(t=0\), the value of \(y\) is
  \(y(t) = y(0) = 1\). With this, we have both \(t\) and \(y\), just
  what we need to figure out the value of \(y'(0)\):

  $$
  y'(0) = f(0, y(0)) = f(0,1)
  $$

  Okay, but how do we get \(y(t)\) for _any_ \(t\)? All we have is a point
  and a derivative at that point. To get any further, we have to extrapolate.
  At our point, the value of \(y\) is changing at a rate of \(y'(0)\). It's
  not unreasonable to guess, then, that after some distance \(h\), the
  value of \(y\) would be:

  $$
  y(0+h) \approx y(0) + hy'(0) = y(0) + hf(0,y(0))
  $$

  Importantly, \(h\) shouldn't be large, since the further away you
  extrapolate, the less accurate your approximation becomes. If we need
  to get further than \(0+h\), we can use the new point we just computed,
  and extrapolate again:

  $$
  y(0+2h) \approx y(0+h) + hf(0+h,y(0+h))
  $$

  And so on and so forth. The last thing I'm going to do is clean up the above
  equations. First, let's stop assuming that our initial \(t=0\); that doesn't work
  in the general case. Instead, we'll use \(t_0\) to denote the initial value of
  \(t\). Similarly, we can use \(y_0\) to denote our (known _a priori_)
  value of \(y(t_0)\). From then, observe that we are moving in discrete
  steps, estimating one point after another. We can denote the first point
  we estimate as \((t_1, y_1)\), the second as \((t_2, y_2)\), and so on.
  Since we're always moving our \(t\) by adding \(h\) to it, the formula for
  a general \(t_n\) is easy enough:

  $$
  t_n = t_0 + nh
  $$

  We can get the formula for \(y_n\) by looking at our approximation steps above.

  $$
  \begin{gather*}
    y_1 = y_0 + hf(t_0,y_0) \\
    y_2 = y_1 + hf(t_1,y_1) \\
    ... \\
    y_{n+1} = y_n + hf(t_n,y_n)
  \end{gather*}
  $$

  What we have arrived at is [Euler's method](https://mathworld.wolfram.com/EulerForwardMethod.html).
  It works pretty well, especially considering how easy it is to implement.
  We could write it in Chapel like so: */

proc runEulerMethod(step: real, count: int, t0: real, y0: real) {
    var y = y0;
    var t = t0;
    for i in 1..count {
        y += step*f(t,y);
        t += step;
    }
    return y;
}

/*
  Just nine lines of code!

  ### Linear Multistep Methods
  In Euler's method, we use only the derivative at the _current_ point to drive
  our subsequent approximations. Why does that have to be the case, though?
  After a few steps, we've computed a whole history of points, each of which
  gives us information about \(y\)'s derivatives. Of course, the more recent
  derivatives are more useful to us (they're closer, so using them would reduce
  the error we get from extrapolating). Nevertheless, we can still try to
  mix in a little bit of "older" information into our estimate of the derivative,
  and try to get a better result that way. Take, for example, the two-step
  Adams-Bashforth method:

  $$
  y_{n+2} = y_{n+1} + h\left[\frac{3}{2}f(t_{n+1}, y_{n+1})-\frac{1}{2}f(t_n,y_n)\right]
  $$

  In this method, the _two_ last known derivatives are used for computing the next
  point. More generally, an \(s\)-step linear multistep method uses the last
  \(s\) points to compute the next, and always takes a linear combination
  of the derivatives and the $y_n$ values themselves. The general form is:

  $$
  \sum_{j=0}^s a_jy_{n+j} = h\sum_{j=0}^s b_jf(t_{n+j}, y_{n+j})
  $$

  Let's focus for a second only on methods where the very last \(y\) value
  is used to compute the next. Furthermore, we won't allow our specifications
  to depend on the slope at the point we're trying to compute (i.e., when computing
  \(y_{n+s}\), we do not look at \(f(t_{n+s}, y_{n+s})\). The methods
  we will consider will consequently have the following form:

  $$
  y_{n+s} = y_{n+s-1} + h\sum_{j=0}^{s-1} b_jf(t_{n+j}, y_{n+j})
  $$

  Importantly, notice that a method of the above form is pretty
  much uniquely determined by its list of coefficients. The
  number of steps \(s\) is equal to the number of coefficients
  \(b_j\), and the rest of the equation simply "zips together"
  a coefficient with a fixed expression representing the derivative
  at a particular point in the past.

  ### Type-Level Coefficient Lists

  What we would like to do now is to be able to represent different methods
  in the above family at compile-time. That is, we would like
  to be able to fully describe a method using a Chapel type,
  feed it to a function that implements the method, and pay
  nothing in terms of runtime overhead. By encoding
  information about a numerical method at compile-time,
  we can also ensure that the function is correctly invoked. For
  instance, Euler's method needs a single initial coordinate to
  get started, \(y_{0}\), but the two-step Adams-Bashforth method
  above requires both \(y_{0}\) and another coordinate \(y_{1}\).
  If we were to describe methods using a runtime construct, such
  as perhaps a list, it would be entirely possible for a user to
  feed in a list with not enough points, or too many. We can be
  smarter than that.

  Okay, but how do we represent a list at compile-time? Chapel
  does have `param`s, which are integer, real, boolean, or string
  values that can occur at the type-level and are known when
  a program is being compiled. However, `param`s currently only support
  primitive values; a list is far from a primitive value!

  What is necessary is a trick used quite frequently in
  Haskell land. We can create two completely unrelated records, just to tell
  the compiler about two new types: */

record empty {}
record cons {
    param head: real;
    type tail;
}

/*
  The new `cons` type is generic. It needs two
  things: a `real` for the `head` field, and
  a `type` for the `tail` field. Coming up
  with a `real` is not that hard; we can, for instance,
  write:

  ```Chapel
  type t1 = cons(1.5, ?);
  ```

  Alright, but what goes in the place of the question mark?
  The second argument of `cons` is a type, and a fully-instantiated
  `cons` is itself a type. Thus, perhaps we could try nesting
  two `cons`s:

  ```Chapel
  type t2 = cons(1.5, cons(-0.5, ?));
  ```

  Once again, the first argument to `cons` is a real number, and
  coming up with one of those is easy.

  ```Chapel
  type t3 = cons(1.5, cons(-0.5, ?));
  ```

  I hope it's obvious enough that we can keep
  repeating this process to build up a longer
  and longer chain of numbers. However, we need to
  do something different if we are to get out of this
  `cons`-loop. That's where `empty` comes in.

  ```Chapel
  type t4 = cons(1.5, cons(-0.5, empty));
  ```

  Now, `t4` is a fully-concrete type. Note that we
  haven't yet --- nor will we --- actually allocate
  any records of type `cons` or `empty`; the purpose
  of these two is solely to live at the type level.
  Specifically, if we encode our special types
  of linear multistep methods as lists of coefficients,
  we can embed these lists of coefficients into Chapel
  types by using `cons` and `empty`. Check out the
  table below.

  |Method | List | Chapel Type Expression |
  |-------|----------------------|-------------------|
  | Degenerate case | \(\varnothing\) | `empty` |
  | Euler's method  | \(1\)                  | `cons(1.0, empty)` |
  | Two-step Adams-Bashforth  | \(\frac{3}{2}, -\frac{1}{2}\)                  | `cons(3.0/2.0, cons(-0.5, empty))` |

  As I mentioned earlier, the number of steps \(s\) a method takes
  (which is also the number of initial data points required to
  get the method started) is the number of coefficients. Thus,
  we need a way to take a type like `t4` and count how many coefficients
  it contains. Fortunately, Chapel allows us to write functions on
  types, as well as to pattern match on types' arguments. An
  important caveat is that matching occurs when a function is called,
  so we can't somehow write `myType == cons(?h, ?t)`. Instead, we need
  to write a function that _definitely_ accepts a type `cons` with
  some arguments: */

proc length(type x: cons(?w, ?t)) param do
  return 1 + length(t);

/*
  The above function works roughly as follows:

  * We start with the initial call.
    ```Chapel
    length(cons(1.5, cons(-0.5, empty)))
    ```
  * When resolving the call to `length`, `?w` gets matched with `1.5` and
    `?t` gets matched with `cons(-0.5, empty)`. When the return
    expression is evaluated, we end up with the following:
    ```Chapel
    1 + length(t)
    ```
  * Since `t` was matched with `cons(-0.5, empty)`, the previous
    code snippet is the same as:
    ```Chapel
    1 + length(cons(-0.5, empty))
    ```
  * We now resolve the new call to `length`: `?w` gets matched with `-0.5`,
    `?t` gets matched with `empty`. Evaluation proceeds like last time.
    ```Chapel
    1 + 1 + length(empty)
    ```

  Here, we could we get stuck; what's `length(empty)`? We need
  another overload for `length` that handles this case. */

proc length(type x: empty) param do
  return 0;

/*
  With this, the final expression will effectively become `1 + 1 + 0 = 2`,
  which is indeed the length of the given list.

  Another thing we're going to need is the ability to get a coefficient at a particular
  location in the list. We'll use `1` to get the first element, `2` to get
  the second, and so on. Such a function is pretty simple, though it
  does also use pattern-matching via `?w` and `?t`: */

proc coeff(param x: int, type ct: cons(?w, ?t)) param {
    if x == 1 {
        return w;
    } else {
        return coeff(x-1, t);
    }
}

/*
  ### A Generic Evaluator

  Alright, now's the time to get working on the actual implementation
  of linear multistep methods. A function implementing them will
  need a few arguments:

  * A `type` argument representing the linear multi-step method
    being implemented. This method will be encoded using our
    `cons` lists.
  * A `real` representing the step size \(h\).
  * An `int` representing how many iterations we should run.
  * A `real` representing the starting x-coordinate of the method
    \(t_0\). We don't need to feed in a whole list \(t_0, \ldots, t_{s-1}\)
    since each \(t_{i}\) is within a fixed distance \(h\) of
    its neighbors.
  * As many `real` coordinates as required by the method,
    \(y_0, \ldots, y_{s-1}\).

  Here's the corresponding Chapel code: */

proc runMethod(type method, step: real, count: int, start: real,
               in n: real ... length(method)): real {

    /*
      That last little bit, `n: real ... length(method)`, is an
      instance of Chapel's variable arguments functionality. Specifically,
      this says that `runMethod` takes multiple `real` arguments,
      the exact number of which is given by the expression `length(method)`.
      We've just seen that `length` computes the number of coefficients
      in a list, so the function will expect exactly as many \(y_i\)
      y-coordinates as there are coefficients.

      The actual code is straightforward. */

    param coeffCount = length(method);
    // Repeat the methods as many times as requested
    for i in 1..count {
        // We're computing by adding h*b_j*f(...) to y_n.
        // Set total to y_n.
        var total = n(coeffCount - 1);
        // 'for param' loops are unrolled at compile-time -- this is just
        // like writing out each iteration by hand.
        for param j in 1..coeffCount do
            // For each coefficient b_j given by coeff(j, method),
            // increment the total by h*bj*f(...)
            total += step * coeff(j, method) *
                f(start + step*(i-1+coeffCount-j), n(coeffCount-j));
        // Shift each y_i over by one, and set y_{n+s} to the
        // newly computed total.
        for param j in 0..< coeffCount - 1 do
            n(j) = n(j+1);
        n(coeffCount - 1) = total;
    }
    // return final y_{n+s}
    return n(coeffCount - 1);
}

/*
  That completes our implementation. All that's left is to actually
  use our API, by applying it to some function! I'll use Wikipedia's page on
  linear multi-step methods to find some examples to compare against.
  That page runs all the methods with the differential equation \(y' = y\),
  for which the corresponding function `f` is: */

proc f(t: real, y: real) do
  return y;

/*
   Next, we need to encode the various methods: */

type euler = cons(1.0, empty);
type adamsBashforth = cons(3.0/2.0, cons(-0.5, empty));
type someThirdMethod = cons(23.0/12.0, cons(-16.0/12.0, cons(5.0/12.0, empty)));


/*
  Then, we can run the methods as follows (with initial coordinate
  \((0, 1)\), as Wikipedia does). */

writeln(runMethod(euler, step=0.5, count=4, start=0, 1));
writeln("__BREAK__");

/*
   Wikipedia confirms that 5.0625 is the correct answer! To test Adams-Bashforth,
   pick a second initial point from Euler's method. */

writeln(runMethod(adamsBashforth, step=0.5, count=3, start=0, 1,
    runMethod(euler, step=0.5, count=1, start=0, 1)));
writeln("__BREAK__");

/*
  Once again, 6.0234 is the correct answer!

  Of course, this is just a toy example, and finding an approximate solution
  to \(y' = y\) is neither novel nor particularly difficult. However,
  the goal was not to approximate the differential equation, but to demonstrate
  some of the advanced general-purpose features that Chapel provides. Using
  these features, we were able to implement an evaluator for a whole
  family of numerical methods, allowing us to describe a method in only
  a line of code, and execute it as fast as a hand-written implementation.

  {{< changetable >}}
  | Date         | Change                                                      |
  |:-------------|:------------------------------------------------------------|
  | Sep 27, 2024 | Resolved errors due to improved constness checking in varargs in Chapel 2.2 |
*/
