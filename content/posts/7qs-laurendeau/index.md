---
title: "7 Questions for Éric Laurendeau: Computing Aircraft Aerodynamics in Chapel"
richtitle: "7 Questions for Éric Laurendeau:<br>Computing Aircraft Aerodynamics in Chapel"
date: 2024-09-17
tags: ["Computational Fluid Dynamics", "User Experiences", "Interviews"]
series: ["7 Questions for Chapel Users"]
summary: "An interview with CHAMPS PI and Professor of Mechanical Engineering, Éric Laurendeau"
authors: ["Engin Kayraklioglu", "Brad Chamberlain"]
interviewee_photo: "laurendeau.jpg"
---


This is the first in a new series of articles we're launching in which
we'll be asking Chapel users a series of questions about their work
and experiences with the language.  In doing so, our goal is to shine
a light on ways in which Chapel is being used, and to hear from users
in their own words.  If you are using Chapel and would like to be
considered for a future installment, or you know of someone who is and
ought to be, please [let us
know](https://chapel.discourse.group/t/7-questions-for-chapel-users-series-questions-comments/37200)!

For our inaugural edition of this series, we turned to Éric
Laurendeau, whose team has developed one of Chapel's most ambitious
flagship applications, CHAMPS.  We could say more to introduce Éric
and CHAMPS, but he does a perfect job of it himself, so let's dive
right in!


### 1. Who are you?

My name is Éric Laurendeau, professor at Polytechnique Montréal. I’m
fortunate to have earned my Bachelor's in Canada (McGill), Master’s in
France (ISAE-SUPAERO), and Ph.D. in the USA (U.&nbsp;Washington). Why?
These are the top 3 worldwide aerospace hubs. Montreal is home to
Bombardier (business jets), CAE (flight simulators), Airbus Canada
(Airbus 220), Pratt & Whitney (engines), Toulouse is Airbus's final
assembly line and Seattle is Boeing’s place. So I have had a chance to
see various approaches to aircraft design and manufacturing.

From 1996–2011, I worked in the advanced aerodynamics department of
Bombardier during the ‘golden years’ of Computational Fluid Dynamics
(CFD). Indeed, major scientific breakthroughs combining numerical
algorithms and fluid dynamics during the 1980’s, combined with
advances in computer power, gave rise to this ‘3rd discipline’,
complementing experimental and theoretical fluid dynamics.

The design of aircraft aerodynamics is now done almost exclusively
using CFD, and the final shapes are validated in a wind tunnel and
then flight-tested for certification purposes. Since aerodynamics is
very closely linked to advances in state-of-the-art research, I took
the challenge of becoming a professor in 2011 to concentrate on the
development of novel computational aerodynamics methods while teaching
at the undergraduate and graduate levels. I typically direct the work
of some 15 Masters and Doctorate students along with one or two
post-doctoral fellows funded through fundamental grants from Canada
and industrial grants, complemented with federal and provincial
governmental grants.


### 2. What do you do? What problems are you trying to solve?

The aerospace industry is more than ever trying to reduce its
environmental footprint, whether CO2 or noise emissions. To achieve
its own goal of net zero emissions by 2050, novel aircraft
configurations like NASA’s Transonic Truss-Braced Wing or Blended Wing
Body concepts are examined (you can look at these on the
internet!). Moreover, since air traffic is ever-increasing, and
atmospheric conditions changing due to global warming, aircraft safety
must be addressed.

{{% pullquote %}}
The aerospace industry is more than ever trying to reduce its
environmental footprint, whether CO2 or noise emissions.
{{% /pullquote %}}

My laboratory therefore examines:

* novel aerodynamic models to allow airflow over wings to be more
  laminar than turbulent (same problem as shark skins),

* multidisciplinary models for complex aircraft phenomena such as
  aero-icing (the phenomena of supercooled liquid droplets forming ice
  on the aircraft surfaces) and aero-elasticity (the phenomena that
  makes aircraft wings oscillate up and down),

* and multi-fidelity models (the various degrees of complexity of
  physical models).

One thing all these models share is the need for
supercomputers. Indeed, several of these models solve for some 10
million to 1 billion unknowns! Thus, applied mathematics and computer
science know-how must be mastered to enable these aerodynamic models
to be used by industry to solve today’s challenges in aviation.


### 3. How does Chapel help you with these problems?

To solve for these incredibly large systems of equations,
supercomputers must be used. In the past century (until year 2000)
these were developed using shared memory systems (e.g., several
computer chips using one brain), and chip synchronization was performed
using the OpenMP protocol. The early 2000’s gave rise to distributed
memory systems (e.g., several computer chips using several
interconnected brains) using the MPI protocol. These protocols add
several layers of complexity to already very complex software. The
result is so top-heavy that it can sometimes lead to software being
too complex to continue further developments (like simply reaching the
limit of highway traffic, where every car literally is stuck on the
freeway). One alternative to these low-level languages is Python, a
very easy-to-program, interpreted language which is very inefficient
for scientific computing.

{{% pullquote %}}
Chapel removes the layers of complexity for code writing,
allowing seamless code development while maintaining computational
performance. It is ideal to develop very large and complex
computational models.
{{% /pullquote %}}


Chapel was designed exactly to address this gap in a very elegant and
efficient way. It removes the layers of complexity for code writing,
allowing seamless code development while maintaining computational
performance. It is ideal to develop very large and complex
computational models. Another great feature is its simplicity. Thus,
when students or staff (e.g., post-docs, researchers) come and go in
the software, the training or time-to-understand is very significantly
reduced while reducing the chances of errors or bugs popping up.

Chapel is such an integral part of our laboratory’s success that our
main aerodynamic solver is named CHAMPS, standing for **Cha**pel
**M**ulti **P**hysics **S**oftware! We run CHAMPS on our desktops and
laptops. This provides flexibility when students perform
out-of-country or outside the laboratory exchanges, simply bringing
their laptops with them. Once simple models are made, very complex
ones are launched on the supercomputers of the Digital Research
Alliance of Canada which are free to use for Canadian researchers
(albeit with a cap on the number of core-years used).


### 4. What initially drew you to Chapel?

While there exist several commercial aerodynamic software packages,
and even open-source ones (industry typically uses proprietary
software), I needed to develop in my lab new software to solve 3D
aerodynamic problems to cater for my laboratory's long-term research
objectives. All aerodynamic software is either using Fortran (yes, you
read correctly!) or C/C++, while all use the MPI protocol. Having
developed in my laboratory a 2D code in C with OpenMP instructions
that had grown so large that it became too difficult to maintain, my
students stumbled on Chapel by chance. They wrote emails to one of the
team developers, Dr. Brad Chamberlain, to ask naïve questions and were
surprised to receive answers to every one of these and with a very
rapid response time! They thus took the bold step to write a prototype
code to see its performance, which ultimately was as good as
advertised! They then proceeded to write a more comprehensive version
that has kept growing ever since with new models/capabilities.


{{% pullquote %}}
The use of Chapel worked as intended: the code maintenance
is very much reduced, and its readability is astonishing. This enables
undergraduate students to contribute to its development, something
almost impossible to think of when using very complex
software.
{{% /pullquote %}}

### 5. What are your biggest successes that Chapel has helped achieve?

We managed to very rapidly develop a state-of-the-art 3D aerodynamic
solver that runs on shared memory and distributed memory
systems. Furthermore, the solver is written in a very compact form,
with some 10x reduction in the number of instruction lines compared to
similar software written using Fortran, C, or C++ with OpenMP/MPI
overhead. The use of Chapel worked as intended: the code maintenance
is very much reduced, and its readability is astonishing. This enables
undergraduate students to contribute to its development, something
almost impossible to think of when using very complex
software. Students enjoy working on a new technology while
contributing to the community’s efforts to address the challenges of
solving very complex mathematical models using simple programming
techniques. This enables researchers to focus on novel contributions
rather than spend energy on writing lines of codes with associated
debugging time.

{{< figure src="CHAMPS.png" class="fullwide" caption="Aircraft Aerodynamic modeling using Chapel on High-Performance Computers" >}}

CHAMPS enabled significant scientific contributions. For instance, it
helps develop new models that are then integrated into the R&D stream
of industrial companies, such as aero-icing capabilities or
state-of-the art global stability analysis of important aerodynamic
phenomena.  It is also used in the many American Institute for
Aeronautics and Astronautics (AIAA) workshops intended to evaluate the
state-of-the-art in [high-lift
(take-off/landing)](https://hiliftpw.larc.nasa.gov) or [drag (cruise
flight)](https://aiaa-dpw.larc.nasa.gov) simulations. CHAMPS thus
stands on par with similar software developed by national research
centers such as NASA (USA), ONERA (France), DLR (Germany), JAXA
(Japan), etc., as well as commercial vendors (Ansys, STAR-CCM+,
etc.). Of these, it is the only one not using OpenMP/MPI protocols and
the only one using Chapel!  These activities showcase the feasibility
of a new parallel paradigm for the aerospace community. Indeed, High
Performance Computing is explicitly listed as a mandatory ingredient
in NASA’s vision for the future (you can read this report: [CFD Vision
2030 Study: A Path to Revolutionary Computational
Aerosciences](https://ntrs.nasa.gov/api/citations/20140003093/downloads/20140003093.pdf),
available on the web). Other contributions are in computational
aeroelasticity, laminar-turbulent transition of airflow, and many
others: you can simply see the list of publications on my [University
website](https://www.polymtl.ca/expertises/laurendeau-eric/publications).

{{% pullquote %}}
CHAMPS thus
stands on par with similar software developed by national research
centers such as NASA&nbsp;(USA), ONERA (France), DLR (Germany),
JAXA&nbsp;(Japan), etc., as well as commercial vendors (Ansys,
STAR-CCM+, etc.). Of these, it is the only one not using OpenMP/MPI
protocols...
{{% /pullquote %}}

CHAMPS has significantly contributed to reach many of the scientific
objectives in my Canada Research Chair award (2017–2024), for which I
am awaiting its renewal decision for 2025–2031! It helps attract
talent, who is always attuned to novelty, and has attracted industrial
contracts. CHAMPS’s success has enabled growth beyond my laboratory:
it is used at Université de Strasbourg (France) by Prof. Y. Hoarau to
examine novel Immersed Boundary Methods to tackle the geometrical
complexities associated with typical aircraft designs, as well as by
Prof. Paoli at Polytechnique Montreal to examine aircraft contrails
(the white twin-streak clouds behind aircraft at high altitudes) that
are the most important contributors to aircraft emissions. CHAMPS is
currently being examined for GPU computing, again via the capabilities
of the Chapel language and to develop very accurate yet very expensive
Hybrid Reynolds-Averaged Navier-Stokes models, which are time-dependent
(increasing the number of aircraft solutions by a factor of 1000) and
mesh discretization dependent (increasing the number of discrete space
solutions to some 200 Million cells, making for some 1.4 Billion
unknowns!).


### 6. If you could improve Chapel with a finger snap, what would you do?

The comments received from my students for improving Chapel are:

* Add an efficient profiler. While profiling is possible (using Intel
  VTune or HPCToolkit), the students often cannot keep track of all
  the information.

* Reduce time for compiling, even if the Chapel team has improved it
  by a factor of 4x in the Chapel 2.0 version, CHAMPS currently being
  one of the largest Chapel software applications, it now takes about
  1 minute to compile, which is still somewhat too large when
  debugging code.

* More readable or understandable error messages. Indeed, some
  compilers from other languages provide better error message
  interpretation.

* Improve on backward compatibility, which we know is not easy to do
  when developing a new language

* Provide an integrated package manager…as we are more users than
  developers of Chapel!



### 7. Anything else you'd like people to know?

Students who leave the laboratory after graduation or to pursue
further studies in another laboratory often tell me they miss Chapel!

---

Thanks very much to Éric for taking the time to kick off this
interview series with us!  If you'd like to hear more about the CHAMPS
team's work, including an introduction to the use of HPC in
computational aerodynamics, be sure to check out the
[video](https://www.youtube.com/watch?v=wD-a_KyB8aI&list=PLuqM5RJ2KYFin_PkkaAJWJF1KjcVGnagh&index=7)
or [slides](https://chapel-lang.org/CHIUW/2021/LaurendeauKeynote.pdf)
from Éric's excellent CHIUW 2021 keynote, _HPC Lessons from 30 Years
of Practice in CFD Towards Aircraft Design and Analysis_.

And/Or, for those attending [SC24](https://sc24.supercomputing.org/),
Éric will be the Distinguished Speaker at [PAW-ATM
2024](https://sourceryinstitute.github.io/PAW/)—the 7th Annual
Parallel Applications Workshop, Alternatives to MPI+X—and we highly
recommend catching his talk, _A Case Study for using Chapel within
the Global Aerospace Industry_.

Finally, if you have any other questions for Éric, or comments on this
series, please direct them to the [7 Questions for Chapel
Users](https://chapel.discourse.group/t/7-questions-for-chapel-users-series-questions-comments/37200)
thread on Discourse.
