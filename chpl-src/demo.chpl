// A demo post!
// tags: ["Demo"]
// draft: true
// summary: "This post demonstrates the various feature of the Chapel blog framework."
// featured: true
// authors: ["Daniel Fedorin"]

/* Let's write an article! Text in comments (multi-line or single line)
   is interpreted as Markdown. This means you can use all the usual
   Markdown syntax for _italics_, __bold__, `code`
   [links to Advent of Code](http://adventofcode.com). Since
   the site title is a top-level header, and the article name is a
   second-level, I recommend using `h3` and below for section titles. This
   looks like the following:

   ### A title with `h3`
   #### A title with `h4`
   ##### A title with `h5`

   Note that the titles show up in the table of contents (only visible when
   there is enough screen space).

   Tables are another thing that's supported by Hugo's markdown. Here's one
   example.

   | Symbol        | Meaning              |
   |:--------------|:---------------------|
   | \(n\)       |  Numbers             |
   | \(s\)       |  Strings             |
   | \(e\)       |  Expressions         |
   | \(x\)       |  Variables           |
   | \(\tau\)   |  Types               |
   | \(\Gamma\) |  Typing environments |

   There's also an `alttable` shortcode to make the table rows alternate colors,
   and to apply some other styling.

   {{< alttable >}}
   | Symbol        | Meaning              |
   |:--------------|:---------------------|
   | \(n\)       |  Numbers             |
   | \(s\)       |  Strings             |
   | \(e\)       |  Expressions         |
   | \(x\)       |  Variables           |
   | \(\tau\)   |  Types               |
   | \(\Gamma\) |  Typing environments |

   Actual Chapel code shows up as code blocks. They're syntax highlighted
   if you compiled Hugo with Chapel support (or if Hugo finally bumped
   its Chroma version).
*/

proc main() { // hugo-tag="main-start"

}

/* You can also write "not actual" code in code blocks. This could be
   either Chapel or non-Chapel code. The below function is not actually
   fed to the compiler as part of the program, for example.

   ```Chapel
   proc notCompiled() {

   }
   ```

   Here's some C++.

   ```C++
   #define AST_NODE(NAME) \
     bool is##NAME() const { \
       return asttags::is##NAME(this->tag_); \
     }

   // This is a comment, included here to show that it's different from
   // the color of the preprocessor directive above.

   struct ignore_t {
      template <typename T>
      constexpr
      void operator=(T&& value) const noexcept {}
   };
   ```

   And here's some bash.

   ```bash
   chpl --log --log-dir=logfiles --savec savedc source.chpl
   ```

   By using the `hugo-tag="bla"` comment, you can mark locations in the code
   and reference them later. For instance, I can say that `main` was defined
   on line {{< get_line_anchor tag="main-start" >}}, and that there will be
   a `writeln` call on line {{< get_line_anchor tag="iteration" >}}.

   Printing out a certain keyword will cause the generated documented
   to contain the program's runtime output up to that point, since
   the previous time the keyword was used. For example: */
for i in 1..5 {
  writeln("Iteration ", i); // hugo-tag="iteration"
}
writeln("__BREAK__");

/* Any Hugo shortcode can be used from the Markdown content. There are
   a few interesting ones to explore. One of my personal favorites is a
   shortcode of my own creation that allows you to put content in the margins
   of the website. For example,
   {{< sidenote "right" "here's an opinion that may merit _further discussion_." >}}
   And here is additional text discussing the opinion, outside of the flow
   of the document.

   You will notice that it looks better to include trailing punctuation into
   the underlined portion of the note, as I have done here.
   {{< /sidenote >}}
   If your screen isn't big enough to have margins in which we can put content,
   you can click the underlined text to view the "sidenote" inline. Sidenotes
   are CSS-only, and thus are not smart enough to automatically move themselves
   out of the way of other overlapping sidenotes. Thus, if you find yourself
   writing one sidenote near another and running out of room, you can always
   make one of them
   {{< sidenote "left" "show up in the left margin instead." >}}
   On screens only big enough for one margin, the left margin will be hidden,
   and the sidenote will be viewable by clicking on it just like on mobile.
   {{< /sidenote >}}
   Or, you can add an extra 'offset' argument to
   {{< sidenote "right" "manually shift the sidenote downward." 12 >}}
   I'm appearing quite far down!
   {{< /sidenote >}}

   */

/*
   The `pullquote` shortcode can be used to make "visual quotes" -- quotes
   that are inserted in relatively big font and serve a decorative purpose
   similar to images. Note that they use the `%` delimiter, which means
   that their content is auto-rendered markdown.

   {{% pullquote attribution="Daniel Fedorin" %}}
   Let's write an article! I'm talking about something so cool it should be
   called out in a quote like this. Even more stuff!
   {{% /pullquote %}}

   Pull quotes can be created without attribution by just omitting the attribution
   argument.

   {{% pullquote %}}
   I need no introduction.
   {{% /pullquote %}}

*/

/* Though not quite a shortcode, you should probably know that Hugo supports
   LaTeX. Its markdown parser knows how to handle special characters (e.g.,
   backslashes), so you can write it pretty much as-is. Here's an example:

   $$
   f'(x) = \lim_{h\to \infty} \frac{f(x+h)-f(x)}{h}
   $$

   Another shortcode I personally use a lot in my writing is one to mark
   something as not yet done.

   {{< todo >}} This needs to be fleshed out more. {{< /todo >}} */

/* There is also support for including images in posts. This is done using
   the "figure" shortcode. The shortcode works both in markdown-driven and in
   Chapel-driven mode. For Chapel-driven posts like this one, though, you will
   need to create a corresponding folder in `content/<post-name>` to store
   any associated images.

   Here is a demonstration using an image from another post:
   {{< figure src="../bns2/perf_cmp_chpl_cxx_py.png" caption="A performance comparison." >}}

   You can make a few tweaks to figures displayed this way. There are several
   size classes for the figure: `tiny`, `small`, `medium`, and `fullwide`.
   You can also add a border to the image using the `border` class.

   {{< figure src="../bns2/perf_cmp_chpl_cxx_py.png" caption="A performance comparison using `fullwide` and `border`." class="fullwide border" >}}
*/

/* Jeremiah's innovation is being able to show output that depends on config
   params and config variables. So, define one of each, just to give us
   something to play with! */

config param configParam: bool;
config const configConst: bool;

/* Jeremiah's `BREAK` mechanism still works, but we don't want to keep
   updating the output as we write (it takes a long time!). This is
   why we're running in `--fast` mode. However, we can always include
   output markers, even if we can't see what they produce yet: */

writeln("Hello, world, again! Config param: ", configParam, ". Config const: ", configConst);
writeln("__BREAK__");

/* Of course, we can switch off fast mode and see what the program shows.
   It's just much, much slower. */

/*
  {{< changetable >}}
  | Date         | Change                                                      |
  |:-------------|:------------------------------------------------------------|
  | Apr 26, 2023 | Updated to reflect `barrier`-related name changes in Chapel 1.30 |

 */
