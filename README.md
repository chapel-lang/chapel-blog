# Chapel Language Blog

## Interested in Writing an Article for the Chapel Blog?  Here's How

If there's a post you'd like to write for the Chapel blog, we want to
hear about it!  Or, if there's a topic you'd like us to write about,
propose that to us as well.

The first step is to write a short pitch describing what the blog
article will cover and the message you plan to deliver with it.  This
should be something short and sweet, like 1–2 paragraphs, or a rough
outline of bullets.  The goal of the proposal is to notify the blog's
editors about your intentions before writing the article to avoid the
possibility of writing something that duplicates someone else's
efforts or that might not be a good match for the Chapel blog.

Blog topics can be proposed in our [Blog
category](https://chapel.discourse.group/c/blog/) on Discourse, or by
reaching out to the editors by Discord, Discourse, Slack, or one of
our other [community forums](https://chapel-lang.org/community/).)

The blog's editors will review the proposal, giving feedback on the
directions and theme as necessary.  Once you have confirmation that
the article is of interest, you can dive into writing.  For details on
the mechanics of writing and previewing a Chapel blog article, see the
subsequent sections in this file.

Most blog articles should target a word count of around 1500–2500
words, excluding sidenotes, details sections, and code.  It's
absolutely fine for articles to be shorter as well.  If an article is
longer, consider whether it would be reasonable to break it into a
series of articles.  If not, ask if an exception can be made.

Once you have completed a draft of the article, ask a trusted
colleague or Chapel community member to review it and provide initial
feedback.  Once you believe the article is ready for publication, open
a Pull Request on the
[chapel-blog](https://github.com/chapel-lang/chapel-blog) GitHub
repository for it (if you haven't already) and notify the blog
editor(s) that you're ready for their review.

At present, Brad Chamberlain is serving as the principal blog editor,
though this may evolve or expand in the future.  His review will
strive to distinguish between suggestions and things that ought to be
addressed before publication.  Ideally, after one round of review the
article will be published, but in some cases multiple rounds may be
necessary depending on the magnitude of the changes involved.

Once the editors and authors are happy with the article, we will set a
target date for publishing—usually within a few days of the article
being finalized, unless other articles are already ahead of it in the
queue.  Ideally, the publication date will be at a time that authors
can help address questions or comments that may come up on Discourse
or various community forums (e.g., HackerNews).

Read on to learn more about the mechanics of formatting and previewing
articles for the Chapel blog.  If you have problems with this process
or are not comfortable with the tools and formats used, feel free to
ask for help from the editorial staff getting your article into the
necessary format.  For example, it may be possible to write the
article in Word or Google Docs and have an editor transliterate it to
the hugo markdown format we use.


## Quick Restart
If you've already set up your environment (installed Hugo etc.), the following
commands, executed in the `chapel-blog` folder, should get your workspace ready
for continuing to work on the blog again:

```bash
# Set up the Chapel environment to get CHPL_HOME set
source /path/to/chapel/util/setchplenv.bash

# Launch the preview server
make preview
```

Or, more manually:

```Bash
# Set up the Chapel environment to get CHPL_HOME set
source /path/to/chapel/util/setchplenv.bash

# Enable Python packages installed in virtual environment
source ./venv/bin/activate

# Launch the preview server
./scripts/chpl_blog.py serve --fast -D -F
```

The last command will launch a web server reachable at
`http://localhost:1313` (or possibly another port if 1313 is already
in use... check the output to be sure).

## Table of Contents
- [Setting Up Your Environment](#setting-up-your-environment)
    - [Cloning the Blog Repository](#cloning-the-blog-repository)
    - [Installing Hugo](#installing-hugo)
    - [Installing the Python Dependencies](#installing-the-python-dependencies)
    - [Install Chapel](#installing-chapel)
- [Launching the Preview Server](#launching-the-preview-server)
- [Authoring Articles](#authoring-articles)
    - [Chapel-Driven Articles](#chapel-driven-articles)
    - [Markdown-Driven Articles](#markdown-driven-articles)
    - Creating an Author Page
    - Creating a Series Page
- [Generating HTML for Publishing](#generating-html-for-publishing)

## Setting Up Your Environment
Broadly speaking, the blog has three dependencies:

* The [Hugo site generator](https://gohugo.io). This is a program that is
  responsible for creating the HTML files for this blog.
* The Python dependencies used by the blog's scripts. The scripts are
  responsible for generating some Markdown content from Chapel source
  files, and helping rebuild the blog when these files change.
* Chapel. In particular, some of the Python scripts use modules provided
  by the Chapel language. Furthermore, we require that all articles added
  to the blog have their code tested, which involves compiling and
  running the programs; thus, the `chpl` compiler needs to be available.

First things first, though -- you need to have this repository checked out!

### Cloning the Blog Repository
Clone this repository (recursively, so that any used themes are cloned as well)
```Bash
git clone --recursive https://github.com/chapel-lang/chapel-blog.git
cd chapel-blog
```

Alternatively, if the `https` link doesn't work, you can instead use:
```Bash
git clone --recursive git@github.com:chapel-lang/chapel-blog.git
cd chapel-blog
```

Subsequent commands in this guide are intended to be executed in the
`chapel-blog` folder (as we have `cd`'ed into it above).

### Installing Hugo
The Hugo static site generator is just a regular program. It can be installed
using your system's package manager. For macOS, the following Homebrew command
would suffice:

```Bash
brew install Hugo
```

See also the [Installation](https://gohugo.io/installation/) page on the Hugo
website.

### Installing the Python Dependencies
To install the blog's Python dependencies, we recommend using Python's virtual
environments feature. By creating a virtual Python environment for the blog and 
installing packages into it, your global Python installation is left intact.

If you use the `Makefile` in this directory, then commands like `make
preview` (which launches a local webserver that gives you a preview of
the blog) will automatically create, set up, and activate the Python
virtual environment for you, and you can skip ahead to the next
section.

If you would prefer to do it manually, the following command will
create a Python virtual environment for you called `venv`:

```Bash
python3 -m virtualenv venv
# or: virtualenv venv
```

You will then need to _active_ the environment, which switches the
`python` command to use the virtual environment's Python interpreter,
which can use the environment's installed packages.  This can be
done using:

```Bash
source ./venv/bin/activate
```

This last command needs to be run once per terminal session; it's not a one-time
step. For this reason, it's also listed in the _Quick Restart_ section above.

Finally, you can install the required dependencies into the virtual environment
using the following command:

```Bash
pip install -r requirements.txt
```

### Installing Chapel

You need to have the Chapel repository available somewhere on your system,
and to have the `CHPL_HOME` environment variable set to the path to said
repository. You can do this by using commands like the following:

```Bash
git clone https://github.com/chapel-lang/chapel.git path/to/chapel/repo
source path/to/chapel/repo/util/setchplenv.bash
```

Much like in the virtual environment case above, the last command needs to
be run once per terminal session, to make the `CHPL_HOME` be available to the
blog scripts.

## Launching the Preview Server

Once you have all the dependencies installed (see [Setting Up Your Environment](#setting-up-your-environment)),
you should be able to start a Hugo server using either of the following commands:

```Bash
make preview-drafts  # to preview the blog, including any draft articles
```

```Bash
make preview  # to only preview non-draft articles
```

or a more explicit command like:

```Bash
./scripts/chpl_blog.py serve --fast -D -F
```

Here’s what the arguments in the manual option mean:
* `serve` -- start a web server to preview the site (default URL is `localhost:1313`)
* `--fast` -- disable slow parts of the build (currently: computing program output)
* `-D` -- render drafts (the demo post is a draft, but it's a good demonstration
  of blog features, so it's nice to render it)
* `-F` -- render not-yet-published articles (you probably want this if you’re drafting)

After this, you should be able to see the complete blog at [`localhost:1313`](http://localhost:1313/). Try
visiting the demo page, which should be visible at: http://localhost:1313/posts/demo/ (assuming you enabled draft articles).

## Authoring Articles
Currently, there are two modes of writing a Chapel blog post:
* Chapel-driven -- a single `.chpl` file with code whose comments contain blog
  text. A Markdown file is generated from the comments.
* Markdown-driven -- a Markdown file together with any number of supporting `.chpl` files
  for code. Markdown is written by hand.

In practice, the first mode tends to be best when the blog article is
describing a single Chapel program, e.g., walking a user through the
code bit by bit in the body of the article.  The second mode is far
more general-purpose and can be used for anything (including cases
that are a good fit for the first mode, if you choose).

In both cases, the end product is a Markdown file, which Hugo
interprets to create an HTML page. However, the two supported modes
are fairly different, and are covered separately in the following
sections.  Examples of articles in both styles can be found in
`./chpl-src/*.chpl` or `./content/posts/*/index.md`, respectively.

### Chapel-Driven Articles

Chapel-driven articles are essentially Chapel source files with comments.
When rendered to HTML, the comments are interpreted as the article text, written
in Markdown. The non-comment code is inserted as code blocks. A Chapel-driven
article should be a valid Chapel program: the non-commented code should compile
using `chpl`.

Chapel-driven articles have two strong points:
* Code and text are automatically spliced together (files and code snippets can’t go out of sync).
* They do not require working with a directory structure like a Markdown-driven article would

However, they may not be a good fit in the following situations:
* The code being presented requires multiple files
* The project has code in other languages (e.g. C++ or Python for comparison with Chapel)
* The article requires figures (it can be done, but just requires a bit more directory management)

If the above limitations are undesirable, consider a Markdown-driven article,
described in the [Markdown-Driven Articles](#markdown-driven-articles) section.

Below is a miniature example of an article in this form:

```Chapel
// Blog post title
// draft: true
/* Blog article text in comments!
   Can use markdown.
   Here is a [markdown cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).
   Also see `chpl-src/demo.chpl`.
*/
// More blog text. Either comment works fine, just like chpl2rst.

proc f() {

}
```

The base filename of the `.chpl` source file will also serve as the
article's unique slug in its URL.  For example, if the article above
were saved as `myArticle.chpl`, it would appear on the Chapel website
as `https://chapel-lang.org/blog/posts/myArticle/`.

The comments at the beginning of the file have special meanings. The very
first comment should be a single-line comment with the article name
(here: "Blog post title"). The next zero or more lines are expected to be
in the format `// property: value`; these lines can be used to configure
the [Hugo front matter variables](https://gohugo.io/content-management/front-matter/)
of the article. In the example above, the `draft` property is set to `true`,
marking the article as a draft.

Once merged, Chapel-driven articles will be tested nightly by the
project's regression testing system to ensure that they continue to
work over time.  As a result, an article named `myArticle.chpl` must
also have a file named `myArticle.good` storing the expected compiler
and execution output for the program when compiled and run.  Articles
can and should be tested by authors by running `start_test
myArticle.chpl`.  They can also support other features from the
testing system like `*.compopts`, `*.execopts`, or `*.prediff` files.
If you are not already familiar with Chapel's testing system, refer to
the [Chapel Testing
System](https://chapel-lang.org/docs/developer/bestPractices/TestSystem.html)
documentation for details, or reach out to the developer community
iwth questions.

Note that an article's Chapel version can be specified in the front matter using
the `chplVersion` tag. When set to a particular version (e.g., 1.33.0), the
article will only be tested up to that version of Chapel. This means that
maintainers of such an article only need to ensure that any Chapel code compiles
and runs up to that Chapel version, and readers should have the same expectation —
code blocks will contain a warning that the code has only been tested up to
the designated version. This can be useful for posts that only pertain to an
individual version of Chapel, such as a release announcement. Alternatively, when
`chplVersion` is unset (the default), the article will always be tested with the latest
version of Chapel, with the expectation that any code in the article is being actively
maintained as features evolve. This strategy is beneficial as it prevents code from
becoming stale, which requires effort from readers to get it running.

<details>
<summary>Here's a more detailed example of front matter properties.</summary>

```
// Advent of Code 2022: Twelve Days of Chapel
// tags: ["Advent of Code", "Meta"]
// series: ["Advent of Code 2022"]
// summary: ”...”
// featured: true
// authors: ["Brad Chamberlain"]
// date: 2022-11-30
// draft: true
// chplVersion: 1.33.0
```
</details>

Chapel-driven articles are placed into the `chpl-src` folder. This is where the
blog scripts know where to look for them.

#### Shortcodes for Chapel-Driven Articles
Some Hugo [shortcodes](https://gohugo.io/content-management/shortcodes/) are
provided specifically for Chapel-driven articles.

* The `whole_file_min` shortcode can be used to include an expandable tab
  containing the code given in the article, alongside a download link:
  ```Markdown
  {{< whole_file_min >}}
  ```

### Markdown-Driven Articles
For Markdown-driven articles, instead of getting Markdown from comments in
Chapel files, you write it by hand, in a standalone file. Also, instead of
code getting automatically inserted between comments, it must be manually
included, using a [shortcode](https://gohugo.io/content-management/shortcodes/).

Typically, Markdown-driven articles have the following structure:
```
content/posts/article-name
├── index.md
└── code
    ├── file1.chpl
    ├── file1.good
    ├── ...
    ├── fileN.chpl
    └── fileN.good
```

Notice that unlike Chapel-driven articles, which go in `chpl-src`,
Markdown-driven articles should be placed into the `content/posts/`
folder, where each article has its own folder.  This folder name forms
the article's "slug" in its URL.  For example, the example just above
would result in an article appearing at
`https://chapel-lang.org/blog/posts/article-name/`.

The `index.md` file contains the article Markdown, while the files in
`code` contain the Chapel source files associated with the article.
This `code` directory will be tested nightly by Chapel's regression
testing system once the article is merged to ensure that things
continue working over time.  Authors should ensure that the tests work
properly by running `start_test content/posts/article-name/code`
before handing the article off for its final editing pass.  If you are
not already familiar with Chapel's testing system, refer to the
[Chapel Testing
System](https://chapel-lang.org/docs/developer/bestPractices/TestSystem.html)
documentation for details, or reach out to the developer community
with questions.

The blog repository provides an easy way to create a new Markdown-driven
article.

```Bash
hugo new --kind full-md-post article-name
```

TODO: but this puts it in the content-gen directory for some reason?
If that happens, you have to move it manually.

#### Shortcodes for Markdown-Driven Articles
Some Hugo shortcodes are provided specifically for Chapel-driven articles.

* The `subfile` shortcode is used to include code segments from a particular
  file.

  ```Markdown
  {{< subfile fname=”file.chpl" lang="chapel" lstart=N lstop=M >}}
  ```

  It can be used with code snippets in other programming languages, too:

  ```Markdown
  {{< subfile fname=”file.cpp" lang=”cpp" lstart=N lstop=M >}}
  ```
* The `file_download` shortcode includes the contents of an entire file
  into the article, and provides a download link.

  ```Markdown
  {{< file_download fname="nsStep3.chpl" lang="chapel" >}}
  ```
* The `file_download_min` shortcode does the same thing as `file_download`,
  except the file's contents can be hidden or revealed using a click on an
  arrow near the filename, to save space or avoid
  overwhelming the reader.  By default, such cases are minimized, but
  `open=true` can be used to start them in an expanded mode.

#### Note about HTML Links

By default, links starting with `http` are considered "external links" and will open in a new tab. For referencing a section of the same blog post, use Hugo's `relref` shortcode so it opens in the same tab.

```Markdown
[link text]({{< relref "link target" >}})
```

## Generating HTML for Publishing
Note: this section is only relevant to people managing https://chapel-lang.org/blog.
If you're simply trying to contribute an article, you do not need this section.

To generate the HTML page and move it to `$CHPL_WWW/chapel-lang.org/blog`, use:

```bash
make www
```

or, alternatively, the `build` command of the script, as well as the
`--copy` option.

```Bash
./scripts/chpl_blog.py build --copy
```

The `build` command also understands `--fast` and `-D`, but when you're
uploading the blog files to a particular location, you probably don't
want to render drafts or include "Program output disabled" in your HTML.
That is, you probably do _not_ want `--fast` or `-D` when using `build`.
