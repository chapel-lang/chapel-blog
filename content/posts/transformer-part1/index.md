
---
title: "Transformers From Scratch in Chapel and C++, Part 1"
date: 2025-10-29
tags: ["User Experience", "Language Comparison", "Performance", "Benchmark"]
summary: "An implementation of a transformer using Chapel, comparing to C++ and PyTorch"
authors: ["Thitrin Sastarasadhit"]
---

### Introduction

As I finished the third year of my bachelor’s degree at Chulalongkorn University, I got an internship opportunity at the University of Tokyo under the supervision of Professor Kenjiro Taura. There, I learned about Chapel and completed this project comparing the achieved performance of Chapel against C++ by implementing a transformer model from scratch. As Chapel is a programming language designed for High Performance Computing, and at the same time the transformer model—which is driving current AI—heavily relies on computational power, I saw this as a great project to work on.

In this blog series, I present my implementation of the Transformer model from scratch in both C++ and Chapel, along with performance comparisons of the two versions on single-threaded and multi-threaded CPUs. I also discuss various performance challenges I encountered and the optimizations I applied in both C++ and Chapel

This blog is divided into two parts: the first part, presented here, discusses the experimental methodology and the first test, using a small-size model on a single thread; while the second part focuses on the second test, a full-size model on single and multiple threads, along with a discussion on productivity.

---

### Methodology

This project compared four implementation versions on both single-threaded and multi-threaded setups. The four versions were C++, Chapel, and two versions of Python using PyTorch that differed in the implementation of the transformer layer. The C++ and Chapel versions were implemented from scratch, while the Python version was taken from [this GitHub repository](https://github.com/ES7/Transformer-from-Scratch). This version was then split into two: one was the original, and in the other, the transformer layer was replaced with `torch.nn.tranformer` from PyTorch. The implementations of all versions can be obtained from [this GitHub link](https://github.com/markthitrin/Transformer.git). Both the C++ and Chapel implementations were tested with generated test cases from the PyTorch versions, ensuring numerical correctness of each layer. Additionally, the Chapel and C++ implementations were very similar; all variables could be mapped from one to the other.

The main focus of this project is to compare the achievable performance in training a transformer model using C++ and Chapel. However, having two additional Python implementations that use PyTorch as their backbone, representing existing well-known frameworks, allowed the results to be contextualized with these as references.

All versions were tested on two tests. The first test, discussed in this post, was conducted on Machine A using a small-size model configuration on a single thread only. The second test, discussed in the next post in this series, was conducted on Machine B using a full-size model configuration on both single and multiple threads.

{{< details summary="**Click here to view the details of the test machines and configurations**" >}}

#### Environment

<u>Machine A</u>
- **CPU:** AMD Ryzen 7 4800H with Radeon Graphics
- **RAM:** 6.67 GB
- **Clang:** Ubuntu clang version 19.1.1 (1ubuntu1)<br>
  Target: x86_64-pc-linux-gnu<br>
  Thread model: posix
- **Chapel:** chpl version 2.4.0<br>
  built with LLVM version 19.1.1<br>
  available LLVM targets: xtensa, m68k, xcore, x86-64, x86, wasm64, wasm32, ve, systemz, sparcel, sparcv9, sparc, riscv64, riscv32, ppc64le, ppc64, ppc32le, ppc32, nvptx64, nvptx, msp430, mips64el, mips64, mipsel, mips, loongarch64, loongarch32, lanai, hexagon, bpfeb, bpfel, bpf, avr, thumbeb, thumb, armeb, arm, amdgcn, r600, aarch64_32, aarch64_be, aarch64, arm64_32, arm64
- **Python:** Python 3.11.13<br>
  PyTorch: 2.3.0<br>
  Numpy: 2.3.0

<u>Machine B</u>
- **CPU:** Intel(R) Xeon Phi(TM) CPU 7250 @ 1.40GHz
- **RAM:** 204.45 GB
- **Clang:** clang version 19.1.3<br>
  Target: x86_64-unknown-linux-gnu<br>
  Thread model: posix
- **Chapel:** chpl version 2.4.0<br>
  built with LLVM version 19.1.3<br>
  available LLVM targets: amdgcn, r600, nvptx64, nvptx, aarch64_32, aarch64_be, aarch64, arm64_32, arm64, x86-64, x86
- **Python:** Python 3.11.13<br>
  PyTorch: 2.5.1<br>
  Numpy: 2.0.1

#### Configuration

<u>Compiler flags</u>
- **Chapel:** `chpl ./file.chpl --fast --no-ieee-float`
- **C++:** `clang++ ./file.cpp -O3 --std=c++20 -fopenmp -funroll-loops -ftree-vectorize -mavx2 -msse -ffast-math -march=native -fveclib=libmvec`
- **Python:** `python ./file.py`

<u>Model</u>

   | Parameter      | Small Size | Full Size | Meaning              |
   |:---------------|:-----------|:----------|:---------------------|
   | dModel         | 32         | 512       | *Dimension of embedding layer of the encoder and decoder* |
   | sequenceLength | 128        | 256       | *Maximum length of input seqeuence* |
   | dFF            | 256        | 2048      | *Dimension of the feed-forward layer inside the encoder and decoder* |
   | N              | 6          | 6         | *Number of transformer encoder, decoder layers (stacked)* |
   | head           | 8          | 8         | *Number of attention heads in multi-head attention layer* |
   | srcVocab       | 15700      | 15700     | *Size of source vocabulary (number of unique tokens)* |
   | tgtVocab       | 22470      | 22470     | *Size of target vocabulary*

   (_note that the model uses 32-bit floating point values_)

{{< /details >}}

Machine A (AMD Ryzen) facilitated easy inspection of the compiled code thanks to the `perf` command and having super-user access, allowing bottlenecks to be identified easily, while Machine B (Xeon Phi) did not. On the other hand, Machine A had a limited memory of 6.67 GB and was incapable of running the full-size model, whereas Machine B had 204.45 GB, allowing the full-size model to be run.

In order to measure the time required by each layer, timers were inserted into all layers. The model was then run on the Italian-English machine translation task, with the dataset obtained from `opus_books` ([Hugging Face link](https://huggingface.co/datasets/Helsinki-NLP/opus_books)). The model was executed for 500 and 40 iterations on Machines A and B, respectively. The timing results of each iteration for each layer were gathered and sorted; the fastest and slowest 10% of iterations were removed, and the mean and standard deviation were computed.
 
### Small-Size Model on a Single Thread

In this experiment, I tested the small version of the model on Machine A. With this version, I was able to continuously inspect each part of the compiled program using the `perf` command and optimize the slow parts. The models were run for 500 iterations, and the mean and standard deviation were collected as described in the methodology section. The detailed results can be viewed in [this Google Spreadsheet](https://docs.google.com/spreadsheets/d/1aHkE9Ckl0-waxVwu-f4dIJ0peM6jIUQv3IU1-bFa0p0/edit?usp=sharing), and the single-threaded implementation is available at [this GitHub link](https://github.com/markthitrin/Transformer/tree/SingleThread)

#### Forward Pass Results

  {{< figure src="each-forward.png" class="fullwide"
  caption="**Figure 1.** Time spent on each layer (in microseconds) during a single forward-pass training iteration for each model, tested on Machine A (single-threaded) using the small model configuration.">}}

Since inserting timers into each layer of the transformer layer (`torch.nn.transformer`) in the PyTorch B model was difficult—because some layers, such as Softmax and ReLU, are function calls embedded between layers, preventing flexible placement of timer checkpoints—the detailed data for individual layers is missing. Therefore, only C++, Chapel, and PyTorch A’s individual layer elapsed times can be shown. This also applies to the other sections.

According to Figure 1, most layers in Chapel performed as well as those in C++ and PyTorch A. Some layers even performed better, while only a few, such as Softmax and Dropout, performed worse. The poor performance of the Dropout layer is primarily due to the inefficiency of the random number generator (`randomstream.fill()`). I will discuss the performance issues of these layers in the next section.

You might expect the Linear and Multi-Headed Attention layers to dominate the execution time. While this is true for a larger model, in this small version, the execution time of these layers did not contribute as much. Additionally, the PyTorch version might be expected to be significantly faster than the C++ and Chapel versions, as it is equipped with optimized linear algebra libraries. However, since this is a small-size model, the execution time of the Linear and Multi-Headed Attention layers did not dominate, and the matrix sizes were not very large. As a result, the performance of all versions was comparable.

#### Backward Pass Results

  {{< figure src="each-backward.png" class="fullwide"
  caption="**Figure 2.** Time spent on each layer (in microseconds) during a single backward-pass training iteration for each model, tested on Machine A (single-threaded) using the small model configuration.">}}

As for the backward pass, Figure 2 shows that, overall, C++ and Chapel performed better than both Python versions. it also shows that Chapel could achieve relatively the same performance as C++, resulting in the total backward-pass time of Chapel and C++ in this configuration to be almost the same.

#### Overall Results

  {{< figure src="total.png" class="fullwide"
  caption="**Figure 3.** Time spent on each layer (in microseconds) per training iteration (including forward, backward, and update) for each model, tested on Machine A (single-threaded) using the small model configuration.">}}

Figure 3 shows the total time required for each training iteration, including the forward pass, backward pass, loss computation, and optimization. It can be seen that the Chapel version was slower than the others, primarily because the Softmax and Dropout layers were slower in the forward pass, while the other layers performed comparably. Since this was the small version of the model, the advantage of using PyTorch’s optimized linear algebra modules did not significantly manifest here, causing the performance to be comparable with C++ and Chapel. This advantage, however, will become more apparent in the results of the full-size model experiment on Machine B.

### Discussion: Small-Size Model Performance

Throughout the implementation process, I encountered and resolved many interesting performance issues and gained valuable insights. I will discuss them in this section.

#### Matrix Repsentation

This is the most critical building block of the model. In C++, I created a `Tensor` class to store the data and a `TensorView` class to capture a portion of the tensor when performing calculations.
```cpp
class Tensor {
    Tensor(int row, int column) {data = new float[row * column];}
    ~Tensor() {delete[] data;}

    float* data;
};

class TensorView {
    TensorView(Tensor& t) {data = t.data;}
    ~TensorView() {/*do nothing*/}

    float* data;
};

```
The Chapel version, however, uses an alternative approach. It uses built-in arrays to represent all matrices and tensors. Unlike C++, `ref` fields are not currently supported in a `class` or `record`, so a `TensorView`-like structure in Chapel cannot be constructed:
```Chapel
class TensorView {
  ref data;  // error: References cannot be members of classes or records yet.
}
```
I see this as a feature that would be beneficial to implement in the future.

Another interesting design choice I made is to use a 1D array instead of a multidimensional array to represent each matrix and tensor. In an earlier draft, I initially used a multidimensional array with the `LinearAlgebra` module. However, I found its performance to be significantly worse than expected. Upon inspecting the compiler-generated code, I discovered that iterating over elements in a multidimensional array invoked a function called `advance_chpl`, a function that retrieves the next item in an array, which introduced considerable overhead and prevented vectorization. This issue had already been reported in a GitHub issue titled "[Multidimensional zippered iteration (or promotion) kills performance](https://github.com/chapel-lang/chapel/issues/13147)" and has been noted as a known performance concern on the [Chapel website](https://chapel-lang.org/docs/2.6/technotes/optimization.html#performance-problems-with-multidimensional-zippered-iteration).

Although this could be mitigated by iterating over the array’s domain instead of its elements, doing so might introduce unknown performance issues with multidimensional arrays in the future. For these reasons, I decided to use the 1D array design, which is one of the methods suggested in the "[Optimizing Performance of Chapel Programs](https://chapel-lang.org/docs/2.6/technotes/optimization.html#performance-problems-with-multidimensional-zippered-iteration)" documentation.

I also experimented with nested arrays, such as `var arr: [0..#N][0..#N] real(32)`. This approach yielded better performance, as the compiler treated it as a 1D array of 1D arrays. However, this made the array non-contiguous in memory, as each row is not guaranteed to be contiguous with the others, effectively equivalent to a `float**` in C++. As a result, it was still less efficient than using a pure 1D array.

#### Matrix Multiplication

The algorithm used for matrix multiplication is blocked matrix multiplication, in which the operation is divided into smaller blocks to exploit cache locality. A block size of 64<small>$\times$</small>64 was chosen, as it provided the best performance in my environment. Both the C++ and Chapel versions use the same algorithm and block size.

After some tests, Chapel outperformed C++ for certain matrix sizes and underperformed for others, even though the compiler-generated code of the inner loops was nearly identical. This caused the performance of the linear layer, when tested on the full-size model, to be faster in Chapel than in C++. The cause of this variation remains unknown to me.

#### Matrix Operations

This section discusses general operations such as element-wise multiplication, addition, division, etc. As I wanted to have control over parallelism, there were several candidate designs, including overloading the array operators like `+`, `-`,  `*`, and `/` or creating new functions for these operations. As I experimented with performance and inspected the generated assembly, I found that the design and implementation of these operations had a greater impact on the model than I had expected. Therefore, I tested five versions of the sum-reduction function used in LayerNorm to calculate the mean. (However, the implementation of LayerNorm that used this function was later changed to be similar to the C++ version).

```Chapel
// query the domain from the array argument
proc PlusReduce1(ref A: [?D] real(32), out output: real(32)) {
    output = 0.0;
    for i in D {
       output += A[i];
    }
}

// pass the domain explicitly
proc PlusReduce2(D: domain(1), ref A: [] real(32), out output: real(32)) {
    output = 0.0;
    for i in D {
        output += A[i];
    }
}

// pass the starting and ending points explicitly
proc PlusReduce3(in start: int, in count: int, ref A: [] real(32), out output: real(32)) {
    output = 0.0;
    for i in start..#count {
        output += A[i];
    }
}

// use a + reduce expression
proc PlusReduce4(ref A: [?D] real(32), out output real(32)) {
    output = + reduce(A);
}

// {{<sidenote "right" "operator overloading">}}
  Note that while this overload is
  identical to Chapel's built-in
  \+ operator on arrays, in my work
  I actually wanted more control
  over the parallelism, so the body
  was more complicated than shown here,
  simplified for the purposes of
  this discussion.{{</sidenote>}}
operator +=(ref sum: real(32), ref A: [] real(32)) {
    var output: real(32) = 0.0;
    for i in A.domain {
        output += A[i];
    }
    sum = output;
}
```

1. The first method is the one mentioned in the primers section of the Chapel documentation, which receives a portion of the matrix along with its domain. This version generates non-unrolled loops without vectorization, making it the slowest.

2. The second method receives the domain separately, which appears to reduce data transfer overhead. Additionally, it generates a large unrolled loop, but still without vectorization.

3. The third method is the best, as it generates unrolled loops with vectorization. Moreover, when used consecutively with other operations implemented in the same way, the compiler can recognize the pattern and combine them into a single vectorized loop if necessary. For instance:
   ```Chapel
   // The compiler might combine these into a single loop 
   // that performs plus, exp, and mul in each iteration.
   Plus();
   Exp();
   Mul();
   ```

4. The fourth method generates the same loop as the first but also creates a Chapel task when it is called.

5. The fifth method, overloading the operator, enabled clean code. However, it gave the same result as the first method.

Please note that this effect may or may not occur in specific cases. When I tested `PlusReduce1` and `PlusReduce2` individually outside the model, the optimization occurred normally, with the entire function inlined into `chpl_gen_main` (the main function appearing in the compiler-generated code).

As a result, I chose the third design, passing the array with start and end points manually, as it gives the best performance result. I also want to point out that another reason I didn't choose overloading operator even though it enables much cleaner code is that it requires additional memory allocation or copying in expressions that have three or more operands such as `C = A + B`, it costs unnecessary additional execution time, both in Chapel and C++.
```Chapel
operator +(ref A: [] real(32), ref B: [] real(32)) {
    var C: [A.domain] real(32); // allocation
    for i in A.domain {
        C[i] = A[i] + B[i];
    }
    return C; // copy
}
```

#### Softmax

This is the most critical layer, as it is significantly slower in both versions compared to PyTorch, with Chapel being the slowest. I do not know the reason behind the slowness of the C++ version, as it is slower than both of the Python versions, but I understand why it performs better than the Chapel version. The Chapel version refuses to use `_ZGVdN8v_expf_avx2`, the vectorized exponential function in the GNU C Library, in exponential computation, while the C++ version uses the function (`clang` requires the `-fveclib=libmvec` flag to enable `_ZGVdN8v_expf_avx2`). I have tried the following methods to enable the use of `_ZGVdN8v_expf_avx2` in Chapel but failed:
- Simple for loop iterating over the array’s domain
- Simple for loop iterating over the array’s elements
- Switching from `real(32)` to `real(64)`
- Direct assignment `B = exp(A)`
- Using `foreach` loops.
- Passing the same flags used in Clang via `--ccflag`
- Using `--no-ieee-float`

As Chapel uses LLVM as its backbone, Chapel should be able to access this function like clang does. This issue should be further investigated (or the function should be integrated if it hasn't been) so that Chapel can benefit from it.

#### DropOut

This is another layer that performed significantly worse in Chapel. The random number generator I used in the Chapel version is from the `Random` standard module. As for the C++ version, I tried to implement the same random algorithm, `pcg_setseq_64_xsh_rr_32`.

Initially, I generated random floating-point numbers, which turned out to be 4–5 times slower than generating random integers. Therefore, I switched to generating random integers with an integer threshold.

It also appeared that using `rng.fill` is faster than using `rng.next` when iterating over an array. Since this function forces parallelism when available, `CHPL_RT_NUM_THREADS_PER_LOCALE=1` must be set accordingly when experimenting with a single thread.

In the end, the Dropout layer in Chapel still performed worse than in the other versions.

#### Multihead Attention

This layer consumes the most resources and plays a major role in the model. In this layer, I designed the process to avoid explicitly transposing any matrix and instead utilized specialized matrix multiplication functions for transposed operations, such as `MatMulPlusATB`, which performs `C += dot(A.T,B)`

The performance issue I found in this layer was both interesting and mysterious. While the forward process of both versions performed as expected, the backward pass of the Chapel version initially performed very poorly. After some investigation, I discovered that in the final step, where the weight gradients of Q, K, and V are computed along with the gradient for the next layer, the matrix multiplication was performing poorly because the compiler refused to fully vectorize it. Instead, the loop was heavily unrolled without any vectorization.
```Chapel
proc backward(/*...*/) {
// ...
// These matrix multiplications are slow
    for i in 0..#batch {
        MatMulPlusAB(QTGradient[(i * block)..#block], inputQ[(i * block)..#block], WQOpt.gradient);
        MatMulPlusAB(KTGradient[(i * block)..#block], inputK[(i * block)..#block], WKOpt.gradient);
        MatMulPlusAB(VTGradient[(i * block)..#block], inputV[(i * block)..#block], WVOpt.gradient);
    }
    for i in 0..#batch {
        MatMulPlusATB(QTGradient[(i * block)..#block], WQ, inputGradientQ[(i * block)..#block]);
        MatMulPlusATB(KTGradient[(i * block)..#block], WK, inputGradientK[(i * block)..#block]);
        MatMulPlusATB(VTGradient[(i * block)..#block], WV, inputGradientV[(i * block)..#block]);
    }
}

```

Surprisingly, this issue was resolved by altering some code in the Config file, which is a Chapel file that defines values known at compile time, such as model dimension, sequence length, matrix multiplication block size, etc. Since these values are known at compile time, the `param` keyword was initially used. However, when I changed from `param` to `var`, loosening the variable restriction, the issue in multi-head attention vanished, and the compiler was able to recognize the pattern and optimize the function normally.
```Chapel
// ...
config /*param*/ var dModel: int = 32;
config /*param*/ var head: int = 8;
config /*param*/ var sequenceLength: int = 128;
// ... 
```

Fortunately, this alteration did not negatively affect the performance of other layers. Still, this phenomenon should be investigated further, as the conditions for triggering this issue seem very specific; even commenting out unrelated code could make the issue disappear, making it difficult to reproduce outside of the full model.

#### ReLU

One issue found in this layer is in the backward process. At first, the backward pass of this layer was implemented in one line.
```Chapel
for i in D {
    inputGradient[i] = if input[i] >= 0 then outputGradient[i] else 0.0:real(32);
}
```
The problem is that the compiler refused to vectorize and unroll this loop. This was solved by seperating the loop into two sections:
```Chapel
for i in D {
    outputGradient[i] = if input[i] >= 0 then outputGradient[i] else 0.0:real(32);
}
Copy(0,0,D.size,outputGradient,inputGradient);
```

Chapel also got better performance than C++ in the forward pass of this layer. The compiled code is almost the same, with the same vectorizing and loop unrolling degree; the difference is that Chapel did the load, max, and store operations separately, while C++ merges the load and max oprations into one instruction.
```asm
// Chapel
load mem -> res
max 0,res -> res
store res -> mem
// C++
max 0,mem -> res
store res -> mem
```
This somehow makes the function in the Chapel version faster than that in C++ when tested on the small-size model. However, when tested on the full-size model, it makes the function in the Chapel version much slower than the function in the C++ version. Additionally, this performance drop when testing on the full-size model can also be seen in the backward pass of LayerNorm. I currently don't understand the cause of this effect.

#### Other Layers

The other layers seem fine and perform as well as, or better than, the PyTorch version. Moreover, the model optimization part, specifically the loss computation and Adam optimizer, appears to perform much better than in the PyTorch versions.

### Conclusion

In this post, we explore the methodology of the experiment and the first test, running a small-size model on single thread. The performance of the C++ and Chapel models is comparable to that of the two PyTorch models, with the C++ version being the fastest, as the benefits of PyTorch’s optimized linear algebra are not very apparent in this small-scale test. The Chapel version was slowest in this test, mainly due to the Dropout and Softmax layers. Several unexpected performance issues were also encountered, requiring tricky solutions during Chapel’s development.

In the next post in this series, we will explore the second test, using a full-size model on single and multiple threads, along with a discussion on productivity.