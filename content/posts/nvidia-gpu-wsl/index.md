---
title: "Measure the Performance of your Gaming GPU with Chapel"
date: 2024-08-27
tags: ["GPUs", "How-to", "Windows"]
series: ["GPU Programming in Chapel"]
summary: "This post demonstrates using the Windows Subsystem for Linux to run Chapel code on a GPU from NVIDIA"
authors: ["Ahmad Rezaii"]
---
### Put your gaming system to work with Chapel
Modern gaming systems have tremendous parallel potential. Today's offerings from
AMD and Intel combine with GPUs from NVIDIA to build multi-CPU systems that command
thousands of GPU cores. While not supercomputers, they are definitely _super_
computers. It would be nice if we could use Chapel to take control of all that
raw power, but it is almost always locked inside the Windows operating system,
making it an inhospitable development environment for HPC programs.
Although Chapel runs natively on Linux and MacOS, support for Chapel on Windows
was previously limited to Cygwin, degrading the performance and limiting Chapel
to an incomplete set of features. The Windows Subsystem for Linux (WSL)
allows Chapel to behave and perform more like it would on native Linux and is now
the preferred way to develop Chapel programs on Windows.

In this post, I'm going to show that we can use WSL to run Chapel code on our NVIDIA
GPUs hosted in Windows, while also getting performance that is on par with lower-level CUDA code.
We'll be evaluating performance with a commonly used memory streaming benchmark
known as [STREAM Triad](https://www.cs.virginia.edu/stream/).
The STREAM Triad algorithm performs simple processing on three arrays of equal length
to form a synthetic benchmark that is suitable for measuring memory bandwidth.

The pseudocode for the calculation looks something like this:

```chapel
for i in 1..A.size do
  A[i] = B[i] + k * C[i]
```

Memory bandwidth is the measurement of how much data your graphics card can move between
the GPU and the card's vRAM in a fixed amount of time. This is an important metric
for gaming, especially at higher resolutions and refresh rates that are becoming
more popular; but it's also important for image processing and machine
learning applications that can have their performance limited by the interface
between the GPU and vRAM. The STREAM Triad benchmark will help you understand how the
actual bandwidth of your GPU compares to its maximum theoretical bandwidth.

To follow along on your own with this demonstration, you'll need access to what I'm
going to daringly call a {{< sidenote "right" "\"typical\" gaming computer" -14 >}}
[Steam hardware surveys](https://store.steampowered.com/hwsurvey/)
over the previous 18 months report a pretty consistent 90–95% market dominance by
Windows 10 and 11. According to the same surveys, NVIDIA GPUs are the most popular
in gaming systems, accounting for around 70–75% of systems with dedicated graphic
processing units.
{{< /sidenote >}} — that is, one
that runs Windows and has a GPU from {{< sidenote "right" "NVIDIA" 1 >}}
Note that Chapel's GPU support enables Chapel code to run on GPUs from both AMD and
NVIDIA. It's just that AMD does not support accessing your card from WSL at the time of
this writing.
{{< /sidenote >}}.

To start, let's review the setup. I'll assume you have a Windows 10- or 11-based
PC and a GPU from NVIDIA's 10XX series or newer. You'll also need several GB of
free disk space, the amount varying depending on what you might already have installed.
We should also get an idea of our card's theoretical maximum memory bandwidth.
This can often be found on third-party websites that track these sorts of stats.
For my RTX 2070 Super, the memory bandwidth is reported to be ~448&nbsp;GB/s.

To help navigate this guide, choose your own adventure based on your initial state:

* **I do not have WSL installed:** [continue to the next section](#install-wsl) (3–4 GB free space needed)
* **I have WSL, but not the CUDA Toolkit:** [start by installing the CUDA Toolkit](#install-the-cuda-toolkit) (<2 GB free space needed)
* **I have WSL and the CUDA Toolkit, take me to the ~~final boss~~ [last step in this post](#build-chapel-with-gpu-support)**. (<1 GB free space needed)

### Install WSL
To use WSL you must have virtual machine extensions enabled for your CPU. These
are called VT-x for Intel and AMD-V for AMD systems. You'll also need to enable
the Windows feature called _Virtual Machine Platform_. It's possible your system
already has these settings enabled, but if not, Microsoft has a [handy guide](https://support.microsoft.com/en-us/windows/enable-virtualization-on-windows-11-pcs-c5578302-6e43-4b4b-a449-8ced115f58e1)
for enabling the necessary features.

You can install WSL from PowerShell or even from the [Windows Store](https://apps.microsoft.com/detail/9p9tqf7mrm4r?hl=en-lk&gl=LK),
but I will follow the PowerShell installation method in this demo.

Operations:

  1. open up PowerShell or a command prompt
  2. run `wsl --install -d Ubuntu`
  3. reboot

At this point, you should have WSL installed. You can start WSL in a variety of ways,
but for now we'll just keep using the command prompt.
Go ahead and type `wsl` at a PowerShell prompt to get a new Ubuntu shell.

### Use CUDA from WSL

NVIDIA has published specific instructions and even [made a video](https://www.youtube.com/watch?v=JaHVsZa2jTc)
detailing how to utilize your video card from WSL. In order to compile CUDA code in WSL
we need the CUDA compiler `nvcc` provided by the CUDA Toolkit; but otherwise
the WSL installation can run CUDA code out of the box using the drivers already in Windows.
This leads to an important detail of the next step: installing the GPU driver in WSL is not necessary!
It requires some care on our part to avoid accidentally installing drivers alongside the CUDA Toolkit
because doing so can cause problems when trying to run CUDA code in WSL.
Thankfully, NVIDIA has made a specific set of downloads available for WSL Ubuntu installations
that leave the driver installation out by default.

Before we get to installing the toolkit, we should verify that we can access the
video card using the [NVIDIA drivers](https://www.nvidia.com/en-us/geforce/drivers/)
that are already installed in Windows. If you happen to update your drivers
during this process, remember to close and restart WSL before going forward with
the next steps.

#### Test WSL access to GPU

* Launch WSL
* Type `nvidia-smi` and examine the output


 {{< details summary="**(Example nvidia-smi output)**" >}}
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 560.31.01              Driver Version: 560.81         CUDA Version: 12.6     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 2070 ...    On  |   00000000:01:00.0  On |                  N/A |
| 28%   35C    P5             18W /  215W |    1165MiB /   8192MiB |     25%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```

**note:** If you don't get this output check that `/usr/lib/wsl/lib/` exists and
contains `nvidia-smi`. You may need to close and restart WSL.
{{< /details >}}

### Install the CUDA Toolkit

To compile CUDA programs, we are going to need the CUDA Toolkit installed in WSL.
To avoid the additional complexity of getting a more recent version of LLVM on our
Ubuntu distribution, we are going to use CUDA version 11.8, as using a newer
version requires us to perform some {{< sidenote "right" "additional steps." -4 >}}
  We'd need to have LLVM > 15 available for CUDA 12. If you're feeling up to the
  task, installing LLVM >= 16 will allow for CUDA 12. You can read more about the
  requirements from [Chapel's GPU setup notes](https://chapel-lang.org/docs/technotes/gpu.html#setup)
  {{< /sidenote >}}

There are several ways to get the CUDA Toolkit; in this demonstration, we'll use
the [runfile published by NVIDIA](https://developer.nvidia.com/cuda-11-8-0-download-archive?target_os=Linux&target_arch=x86_64&Distribution=WSL-Ubuntu&target_version=2.0&target_type=runfile_local).
The installation instructions are reproduced here for convenience:

```bash
wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run
sudo sh cuda_11.8.0_520.61.05_linux.run
```

  * Accept the EULA
  * Install default options selected (only need toolkit — **do not install driver!**)
  * Ignore warning that says driver wasn't installed, if it comes up

Follow Instructions to update local environment variables. These instructions will
be given in the final output from the CUDA Toolkit install, but I am reproducing
them here for completeness.

```bash
export PATH=/usr/local/cuda-11.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH
```
Note that if you close this Ubuntu shell you'll need to redo these export commands.
You can avoid this by adding them to your `~/.bashrc` file so they will be automatically
executed in every new Ubuntu shell. See the `chapel-wsl-demo.txt` file at the end
for a list of commands used to set up this demo.

#### Test CUDA Toolkit installation in WSL

{{< file_download_min fname="cuda-stream.cu" lang="cpp" >}}

Save the code sample above as `cuda-stream.cu` and compile it using `nvcc`:
```bash
nvcc -O3 -o cuda-stream cuda-stream.cu
```

The `-O3` flag tells the compiler to perform all the optimizations and `-o` just
gives our output file a good name other than the default, `a.out`.

Now run the compiled binary:
```bash
./cuda-stream -s -b 512
```

Here the `-s` tells `cuda-stream` to write the output in SI units (e.g., KB as opposed to KiB),
and the `-b 512` sets the block size to 512 threads per block, which matches
Chapel's default.

You should see some output like this:
```terminal
 STREAM Benchmark implementation in CUDA
 Array size (double precision) = 536.87 MB
 using 512 threads per block, 131072 blocks
 output in SI units (KB = 1000 B)

Function      Rate (GB/s)   Avg time(s)  Min time(s)  Max time(s)
-----------------------------------------------------------------
Triad:         399.5623      0.00418501   0.00403094   0.00468612
```

Note that the memory throughput reported by `cuda-stream` is about 400 GB/s,
roughly 11% less than the theoretical maximum of 448 GB/s for the NVIDIA 2070 Super
we looked up earlier.

If you were able to compile and run the sample program, then we are ready for the
next (and final) steps, building Chapel with GPU support.

### Build Chapel with GPU support

#### Prepare for Chapel

To prepare our new Ubuntu instance for Chapel, there are some packages we'll
need to install. The easiest way to do this is to grab the list of packages from
the [Chapel documentation](https://chapel-lang.org/docs/usingchapel/prereqs.html#installation).
I have posted the commands for Ubuntu 22.04 from the Chapel documentation here
for convenience.

This will install all the things we need to build the Chapel compiler and runtime
in a later step.

```bash
sudo apt-get update
sudo apt-get install gcc g++ m4 perl python3 python3-dev bash make mawk git pkg-config cmake
sudo apt-get install llvm-dev llvm clang libclang-dev libclang-cpp-dev libedit-dev
```


#### Acquire Chapel sources

We are going to need a copy of the Chapel sources to build from. This demonstration
relies on portability features that were first released with Chapel 2.0, which you can
read more about in [its release announcement](https://chapel-lang.org/blog/posts/announcing-chapel-2.0/).
The sources for all Chapel releases are available from [the releases page](https://github.com/chapel-lang/chapel/releases).
Version 2.1 is the latest release at the time of this writing.

In your WSL shell, these commands will download and extract the Chapel source code
into a new directory named 'chapel-2.1.0'.

```bash
wget https://github.com/chapel-lang/chapel/releases/download/2.1.0/chapel-2.1.0.tar.gz
tar -xzf chapel-2.1.0.tar.gz
```
Go ahead and move into the `chapel-2.1.0` directory now.

```bash
cd chapel-2.1.0
```
Next, we'll configure and build Chapel.

#### Configure and build Chapel

Starting from the `chapel-2.1.0` directory, we'll set some environment variables
and build Chapel.

First, source the configuration script `util/setchplenv.bash`:

```bash
source util/setchplenv.bash
```
This will set up the `CHPL_HOME` directory and add the output `bin` directory to
the system `PATH`. This ensures the Chapel compiler `chpl` is available without
having to know the full path when we want to {{< sidenote "left" "use it later" 0 >}}
Note that each `export` or `source` command only affects the current terminal,
so as with setting the environment variables for CUDA before, you can either perform
these steps each time you open a new terminal, or configure the system to do that
for you by placing these lines in your `.bashrc` file, typically located at `~/.bashrc`.
See the `chapel-wsl-demo.txt` file at the end of this post for a list of all the
commands used to set up this demo.
{{< /sidenote >}}.
Because we want to build Chapel with GPU support, we need to set a few other
environment variables to configure the Chapel compiler and runtime.

```bash
export CHPL_LLVM=system
export CHPL_LOCALE_MODEL=gpu
```

The first line tells Chapel to use the LLVM we installed earlier as the code
generation backend. LLVM is required when building Chapel with GPU support.
Setting the {{< sidenote "right" "locale model" 0>}}
  The locale model is an abstraction for how a computer's processors and memory
  are exposed to a Chapel program, and it is a defining feature of Chapel. Other blog posts that discuss locales are [Advent of Code 2022]({{< relref "aoc2022-day13-wrap-up#chapels-locales-and-their-role-in-supporting-distributed-parallelism" >}})
  and [Intro to GPUs]({{< relref "intro-to-gpus#locales-and-on-statements-the-foundation-of-chapel" >}}).
  {{< /sidenote >}}
to `gpu` is essentially the big switch that tells Chapel to use the GPU for eligible
portions of your Chapel code. See the [documentation](https://chapel-lang.org/docs/technotes/gpu.html#overview)
for more information about loop structures that are eligible for GPU locales.


At this point, it might be useful to run `printchplenv` to see the various environment
variables and values that Chapel will build and run with. The descriptions and
more details about the individual variables are available in the Chapel documentation
that describes [setting up your environment](https://chapel-lang.org/docs/usingchapel/chplenv.html).
Most of these should not need to be adjusted from whatever the Chapel environment
scripts selected for your system, but let's look at a few of the important
ones for our setup, `CHPL_LLVM`, `CHPL_GPU`, and `CHPL_LOCALE_MODEL`.

```terminal
CHPL_LOCALE_MODEL: gpu *
  CHPL_GPU: nvidia
...
CHPL_LLVM: system *
```

Notice that the build scripts correctly detected that we're using an NVIDIA GPU,
and that the output indicates values we've explicitly set in the environment with an `*`.

{{< details summary="**(Full output of my `printchplenv`, for the curious reader)**" >}}
```
machine info: Linux HECTOR 5.15.133.1-microsoft-standard-WSL2 #1 SMP Thu Oct 5 21:02:42 UTC 2023 x86_64
CHPL_HOME: /home/ahmad/chapel-2.1.0 *
script location: /home/ahmad/chapel-2.1.0/util/chplenv
CHPL_TARGET_PLATFORM: linux64
CHPL_TARGET_COMPILER: llvm
CHPL_TARGET_ARCH: x86_64
CHPL_TARGET_CPU: native
CHPL_LOCALE_MODEL: gpu *
  CHPL_GPU: nvidia
CHPL_COMM: none
CHPL_TASKS: qthreads
CHPL_LAUNCHER: none
CHPL_TIMERS: generic
CHPL_UNWIND: none
CHPL_MEM: jemalloc
CHPL_ATOMICS: cstdlib
CHPL_GMP: bundled
CHPL_HWLOC: bundled
CHPL_RE2: bundled
CHPL_LLVM: system *
CHPL_AUX_FILESYS: none
```
{{</details>}}


Now we just need to build Chapel with the `make` command. I recommend a parallel
build using the `-j` option limited to the number of cores on your system. We can
use the `nproc` utility to determine the number of cores available, and if we have
sufficient memory available on the PC, we should be able to just use all the cores.

```bash
make -j`nproc`
```

### Measure GPU memory bandwidth using Chapel

Once Chapel is built, we are ready to compile and run our example code!

The `chapel-stream` code is an implementation of the STREAM Triad benchmark that
has been adapted from similar examples in C++ and CUDA. Recall from the introduction
that it is a synthetic benchmark to measure memory bandwidth. You can read more
about data movement and GPU programming with Chapel in earlier posts from the [GPU Programming]({{< relref  "gpu-programming-in-chapel" >}}) series that this article is a part of.

{{< file_download_min fname="chapel-stream.chpl" lang="chapel" >}}

Now let's compile the example program! Whenever we want to evaluate the performance
of a Chapel program, it's imperative that we compile with the `--fast` flag. You
can read more about this flag and others in the list of [most useful flags](https://chapel-lang.org/docs/usingchapel/compiling.html#most-useful-flags).

Run the Chapel compiler, `chpl`, telling it to look for additional modules in the
`examples` directory with the use of the `-M` flag. This is important because our
`chapel-stream` program makes use of a module that is not in Chapel's standard or package
libraries.

```bash
chpl chapel-stream.chpl --fast -M=$CHPL_HOME/examples/benchmarks/hpcc
```
{{< details summary="**(Error message and explanation when `-M` is not included or path is not found)**" >}}


When trying to compile a Chapel program, you may encounter an error similar to the
following if all the source code isn't in the same directory:
```terminal
chapel-stream.chpl:10: error: cannot find module or enum named 'HPCCProblemSize'
```
The error is telling us about a missing module or enum named `HPCCProblemSize`.
If we look at the code in `chapel-stream.chpl` around line 9, we can see that
it is bringing another module into scope with the `use HPCCProblemSize;` statement.

{{< subfile fname="chapel-stream.chpl" lang="chapel" lstart=6 lstop=10 section="first" >}}

The problem is that we have either asked Chapel to load a user-defined module without
telling it where to find it, or the path we gave was not found. To fix the error, we can set or
update the environment variable, [`CHPL_MODULE_PATH`](https://chapel-lang.org/docs/usingchapel/chplenv.html#chpl-module-path),
or pass the `-M` flag with the correct path to our modules when we compile our programs.
{{</details>}}

Finally, we are ready to run the `chapel-stream` executable using our GPU!

```bash
./chapel-stream
```

```terminal
Problem size = 67108864 (2**26)
Bytes per array = 536870912
Total memory required (GB) = 1.5
Number of trials = 10

Execution time:
  avg = 0.00423325
  min = 0.0041151
  max = 0.00458097
Performance (GB/s) = 391.39
```

Success! We have executed the compiled program on our NVIDIA GPU, and we never
had to use anything more than regular Chapel code to do it!

Let's look at how the performance compares with our initial check using the CUDA implementation.
The throughput for each is very similar on my machine, although the
exact value can vary. Both programs consistently report ~385–400 GB/s when performing
the STREAM Triad benchmark on 2^26, or about 67.1 million elements.

Note that this same Chapel code runs on AMD GPUs as written! If you have
access to a machine to try it on, I encourage you to check it out. See the
[vendor portability](https://chapel-lang.org/docs/technotes/gpu.html#vendor-portability)
section of the GPU technote for more information.

### Next steps and additional exploration

At this point, we have demonstrated that we can use Chapel to write code in WSL that
runs directly on your NVIDIA GPU hosted in Windows. We have also shown that Chapel's
GPU performance has the capacity to match lower-level CUDA code in the STREAM Triad benchmark.

Recall that STREAM Triad is a relatively simple algorithm we used to
demonstrate Chapel's ability to write cross-platform capable code that performs similarly to native CUDA implementations — but Chapel is capable of so much more!

Check out these other excellent blog entries to see how you can use Chapel to put your gaming system to work for you, for science, or wherever your creativity leads you! The first two articles provide more information on writing Chapel programs that target the GPU, and the third gives an example of a problem that can be adapted to improve large-scale performance by exploiting the overwhelming core counts of the GPU. Happy coding!

* [Introduction to GPU Programming in Chapel]({{< relref "intro-to-gpus" >}})
* [Data Movement on the GPU]({{< relref "gpu-data-movement" >}})
* [Introduction to Navier-Stokes in Chapel]({{< relref "bns1" >}})

For more information and other [examples](https://chapel-lang.org/docs/technotes/gpu.html#examples),
[benchmarks](https://chapel-lang.org/docs/technotes/gpu.html#benchmark-examples) and
[tests](https://chapel-lang.org/docs/technotes/gpu.html#test-examples), see the
[GPU technote](https://chapel-lang.org/docs/technotes/gpu.html).

{{< file_download_min fname="chapel-wsl-demo.txt" lang="text" >}}