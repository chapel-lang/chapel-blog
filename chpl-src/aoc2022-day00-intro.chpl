// Advent of Code 2022: Twelve Days of Chapel
// tags: ["Advent of Code", "Meta"]
// series: ["Advent of Code 2022"]
// summary: "The Chapel team's plan for blogging during Advent of Code 2022."
// featured: true
// authors: ["Brad Chamberlain"]
// date: 2022-11-30
// weight: 99

/*

To kick off the Chapel blog and gain some experience with the site
during this month's "soft launch", we plan to spend the next few weeks
writing daily articles about participating in [Advent of Code
2022](https://adventofcode.com/2022/) (AoC 2022) using Chapel.


### About Advent of Code

If you're not familiar with Advent of Code, it is an annual community
event focused around a well-engineered series of programming
challenges released daily from December 1–25 on the [AoC
website](https://adventofcode.com/).  The challenges (loosely) tell an
ongoing story over the course of the month, where participants are
encouraged to write programs that solve them.

Participants are each given a unique input dataset, and submitting
correct answers earns them stars on the AoC site.  Each day's exercise
has two parts, where the second part is more challenging and often
highlights potential scalability issues when using brute-force
approaches for the first part.  The exercises also grow in complexity
as the month goes on.  Each day, the first 100 correct solutions are
recognized on a site-wide leaderboard for their speed.  For most of
us, though, AoC is less about the race, and more about exercising our
programming skills in a fun context.

Once the first 100 stars have been awarded, sites like ours are
permitted to blog about their entries, which brings us to...

### Our Twelve Days of Chapel Plan

Our plan is to use AoC 2022 as an opportunity to start populating this
blog by writing about our solutions on a daily basis, and using them
to introduce Chapel features.  As a result, this series will serve as
something of a tutorial for Chapel, focused on the language features
we end up using in our solutions.

At present, we are planning on blogging primarily for just the first
twelve days of AoC 2022 to avoid having it take over the whole month.
We also plan to cover just the first part of each day's exercise in
detail, with high-level notes or hints about part two.

Each article will build on the previous ones.  As a result, early
articles will cover very basic features of the language, whereas
subsequent ones will only teach about concepts that are new.  We will
assume that readers have a basic programming background, and will not
be focusing on teaching relevant, well-known algorithms.  Instead, we
will be writing about how Chapel can be used to solve each of the
daily puzzles, focusing specifically on opportunities to make use of
its unique features for parallel computing.

As we go, we'll also be posting our codes to our [GitHub
repository](https://github.com/chapel-lang/chapel/tree/main/test/studies/adventOfCode/2022/)
for browsing or download.


### How to participate

If you are interested, we encourage you to participate with us in
Chapel's Advent of Code 2022.  Depending on your interests, you can
follow this series of articles as a reader, discuss the exercises on
Discourse, write your own solutions, and/or download and experiment
with ours.  If you would like to ask questions or make comments about
our solutions, please feel encouraged to do so in the [Blog
category](https://chapel.discourse.group/c/blog/) of Chapel's
Discourse forum.

To compile and run our sample Chapel programs, you will need to:
  1. [Install Chapel](https://chapel-lang.org/download.html)
  2. Save the code from the blog or GitHub into a file of your choosing (e.g., `dayNN.chpl`)
  3. Compile the code:
     ```bash
     $ chpl dayNN.chpl
     ```
  4. Run the resulting executable:
     ```bash
     $ ./dayNN
     ```

     Note that, in most cases, you will also need to save the
     program's input from the AoC site into a file (e.g., `dayNN.in`)
     and pipe it into the Chapel program when running it:

     ```bash
     ./dayNN < dayNN.in
     ```

See you back here tomorrow!

*/
