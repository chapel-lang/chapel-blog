// Generating the Mandelbrot with Chapel's GPU Support
// tags: ["GPUs", "Tutorial"]
// series: ["GPU Programming in Chapel"]
// summary: "This post continues to introduce Chapel's GPU programming features by generating a fractal"
// authors: ["Daniel Fedorin"]
// date: 2024-01-15
// draft: true

/*
  Having built up some background for what GPU-enabled Chapel code looks like,
  let's take a look at a concrete example: the Mandelbrot set. The Mandelbrot
  set is probably the most well-known _fractal_, a geometric structure with
  details even at the smallest scales. It looks like this:

  {{< todo >}}A picture of the Mandelbrot.{{< /todo >}}

  The way to construct the Mandelbrot fractal is quite simple; when drawing an
  image, each pixel with coordinate \(c\) (represented by a complex number)
  is colored based on whether the the following function, repeatedly applied
  to a number \(z\) (which starts at zero), does not grow infinitely large.

  $$
  f_c(z) = z^2 + c
  $$

  Concretely, for that pixel with coordinate \(c\), we're interested in
  whether the following sequence of numbers grows infinitely, or stays bounded:

  $$
  0,\ f_c(0),\ f_c(f_c(0)), ...
  $$

  In practice, this property is checked by applying the function \(f\_c\) a certain
  number of times, and seeing if the resulting complex number has a
  {{< sidenote "right" "magnitude greater than 2." >}}
  The reason that 2 is used as the cutoff for the magnitude is because it
  is the largest magnitude of a number in the set (that number is -2).
  {{< /sidenote >}}
  This method of checking for divergence (and thus for generating an image) fits
  the GPU suitability criteria: each pixel's color is completely independent of
  the other pixels, and determining whether or not a pixel is colored requires
  potentially expensive computation (applying the function \(f_c\) multiple times).

  We'll be creating a visualization; for simplicity, this visualization will
  simply be printed to the console using ASCII. To get started, we'll create
  an array called `Mandelbrot` that stores the pixels of our image; since
  an image is two dimensional, our array will be too.
 */

use Time;
var timer: stopwatch;

on here.gpus[0] {
  const width = 36,
        height = 12;
  var Mandelbrot: [-height..height, -width..width/2] bool;
/*
  The variables `width` and `height` above determine the number of pixels
  in our image. Note that a height of 12 (as specified above) doesn't actually
  mean that the whole image will be 12 pixels tall: the first dimension
  of the array's _domain_ (the set of valid indices that can be used to access
  the array) is written to be `-height..height`. Thus, we will have pixels
  corresponding to each number between -12 and 12, of which there are 25.
  Similarly, given a `width` of 36 and a dimension expression `-width..width/2`,
  we'll be creating an array whose x-coordinate spans from -36 to 18,
  a total of 55 numbers. The `width` is divided by 2 in the array's second
  dimension because the Mandelbrot fractal has more filled-in pixels on the
  left of the origin / `(0, 0)`; I've written the bounds to correspond better
  to the fractal's shape.

  This declaration highlights an interesting aspect of Chapel's arrays: their
  indices don't start at 0, like in Java, C, or C++, and nor do they start
  at 1 like Lua. Instead, it is up to the user to specify the indexing scheme
  of the array. Since we've written our two-dimensional array with lower
  bounds `-height` and `-width`, we can use values as low as `(-38, -12)` to
  index into the array. The whole space of valid indices of `Mandelbrot`
  can be visualized as follows:

  $$
  \texttt{A.domain} = \begin{bmatrix}
  (12, -36) & \dots & (12, 18) \\
  \vdots & \ddots & \vdots \\
  (-12, -36) & \dots & (-12, 18) \\
  \end{bmatrix}
  $$

  With this, we can begin on the code to determine the color of each pixel.
  We start by visiting each index of the array; to do so, we can write our
  `foreach` loop to be over `Mandelbrot.domain`. Note that Chapel arrays list
  the number of rows first, which corresponds to the y-coordinate; we thus
  write the loop index as `(y, x)`:
 */
  timer.start();
  foreach (y, x) in Mandelbrot.domain {
/* Now, the actual coordinates of the Mandelbrot don't go as far back as
   `(-12, -36)`. In fact, the lowest x-coordinate of a point in the set is
   -2, and the largest doesn't exceed 1. Thus, we want to translate our pixel
   coordinate into the complex coordinate \(c\). To do so, we need to pick
   a scaling factor: the amount in "real space" that we move for each pixel
   in the image. We'd like `-width` (the smallest x-coordinate of the pixles in
   our array) to correspond to `-2` (the smallest x-coordinate in the fractal).
   This gives us a scaling factor of `2/width`. I picked `-1.5` for the minimum
   y-coordinate in the fractal, and combined with `-height`, this results
   in a scaling factor `1.5/height`. To convert a pixel `(y, x)` into our
   complex coordinate \(c\), it's sufficient to multiply `y` and `x` by
   their respective scaling factors:

 */
    var cReal = 2.0 / width * x,
        cImag = 1.5 / height * y;
/* All that's left is to keep applying \(f\_c\) until we either exceed
   the number of iterations we've decided to attempt, or until the current
   complex number exceeds 2 in magnitude. To do so, we first declare the
   initial value of our complex number \(z\), writing its real and imaginary
   parts into separate variables `re` and `im`. We also declare a flag
   that we'll set if we exceed 2 in magnitude, which indicates divergence.
 */
    var re, im = 0.0;
    var diverged = false;
/* Then, we run our iterations. I picked 1000 iterations pretty arbitrarily.
   The equations for `re` and `im` can be derived from the definition of
   complex numbers; I, however, discovered them in
   [Wikipedia's "Computer Drawings"](https://en.wikipedia.org/wiki/Mandelbrot_set#Computer_drawings)
   section of the Mandelbrot fractal's article.
 */
    for i in 1..1000 {
        re = re*re - im*im + cReal;
        im = 2*re*im + cImag;

        if re*re + im*im > 2*2 {
            diverged = true;
            break;
        }
    }
/* Having computed our answer (stored in the `diverged` variable), we can write
   it into the `Mandelbrot` array. We'll write to the array such that a `true`
   value indicates that a pixel should be colored in, and `false` that it should
   be left blank. Since divergence _excludes_ a number from the set, we negate
   `diverged` here.
 */
    Mandelbrot[y, x] = !diverged;
  } // end 'foreach' loop
  timer.stop();

/* And there we have it, `Mandelbrot` is populated with the colors (black or
   white) of our fractal. To print it, we can make a new array of strings,
   in which `"*"` will be used to color in a pixel, and `" "` will be used
   as blank space. We can make this array the same size and shape as the
   `Mandelbrot` array by using its domain. Then, in another loop over `Mandelbrot`,
   we set each pixel in the `Rendered` array to its desired representation.
 */

  var Rendered: [Mandelbrot.domain] string;
  for (y, x) in Mandelbrot.domain {
    Rendered[y, x] = if Mandelbrot[y, x] then "*" else " ";
  }

/* Chapel knows how to print two-dimensional arrays out of the box; using
   `writeln` is sufficient to print `Rendered` as ASCII art.
 */
  writeln(Rendered);
  writeln("Elapsed time for kernel execution: ", timer.elapsed());
} // end 'on' statement
writeln("__BREAK__");

/* We get our `kernel launch` messages, indicating the GPUs were engaged! */
