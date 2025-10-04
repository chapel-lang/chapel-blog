
---
title: "Transformer From Scratch"
date: 2025-10-10
tags: ["Benchmark", "Language Comparison", "Performance", "User Experience"]
summary: "An Attempt at Implementing a Transformer Using Chapel: Performance Comparison with C++ (and PyTorch) on Single- and Multi-Threaded CPUs"
authors: ["Thitrin Sastarasadhit"]
---

### Background

As I finished my third year of my bachelor’s degree at Chulalongkorn University, I got an internship opportunity at the University of Tokyo under the supervision of Professor Kenjiro Taura. There, I learned about Chapel and completed this project comparing the achieved performance of Chapel against C++ by implementing a transformer model from scratch. As Chapel is a programming language designed for High Performance Computing, and at the same time, Transformer model, which is driving current AI, heavily relies on computational power, I saw this as a great project to work on.

In this article, I present my implementation of the Transformer model from scratch in both C++ and Chapel, along with performance comparisons of the two versions on single-threaded and multi-threaded CPUs. I also discuss various performance challenges I encountered and the optimizations I applied in both C++ and Chapel

---

### Methodology

This project compared four implementation versions on both single-threaded and multi-threaded setups. The four versions were C++, Chapel, and two versions of Python using PyTorch that differed in the implementation of the transformer layer. The C++ and Chapel versions were implemented from scratch, while the Python version was taken from [this GitHub link](https://github.com/ES7/Transformer-from-Scratch). This version was then split into two: one was the original, and in the other, the transformer layer was replaced with `torch.nn.tranformer` from PyTorch. The implementations of all versions can be obtained from [this GitHub link](https://github.com/markthitrin/Transformer.git). Both the C++ and Chapel implementations were tested with generated test cases from the PyTorch versions, ensuring numerical correctness of each layer. Additionally, the Chapel and C++ implementations were very similar; all variables could be mapped from one to the other.

The main focus of this project is to compare the achievable performance in training a transformer model using C++ and Chapel. However, having two additional Python implementations that use PyTorch as their backbone, representing existing well-known frameworks, allowed the results to be contextualized with these as references.

All versions were tested on the following configurations and environments.
- Single thread, Machine A, Small model size
- Single thread, Machine B, Full model size
- Multi thread, Machine B, Full model size

{{< details summary="**Click here to view the details of the test machines and configurations**" >}}

#### Environment

Machine A
- CPU : AMD Ryzen 7 4800H with Radeon Graphics
- RAM : 6.67 GB
- Clang : Ubuntu clang version 19.1.1 (1ubuntu1)
  Target: x86_64-pc-linux-gnu
  Thread model: posix
- Chapel : chpl version 2.4.0
  built with LLVM version 19.1.1
  available LLVM targets: xtensa, m68k, xcore, x86-64, x86, wasm64, wasm32, ve, systemz, sparcel, sparcv9, sparc, riscv64, riscv32, ppc64le, ppc64, ppc32le, ppc32, nvptx64, nvptx, msp430, mips64el, mips64, mipsel, mips, loongarch64, loongarch32, lanai, hexagon, bpfeb, bpfel, bpf, avr, thumbeb, thumb, armeb, arm, amdgcn, r600, aarch64_32, aarch64_be, aarch64, arm64_32, arm64
- Python : Python 3.11.13
  PyTorch : 2.3.0
  Numpy : 2.3.0

Machine B
- Intel(R) Xeon Phi(TM) CPU 7250 @ 1.40GHz
- RAM : 204.45 GB
- Clang : clang version 19.1.3
  Target: x86_64-unknown-linux-gnu
  Thread model: posix
- Chapel : chpl version 2.4.0
  built with LLVM version 19.1.3
  available LLVM targets: amdgcn, r600, nvptx64, nvptx, aarch64_32, aarch64_be, aarch64, arm64_32, arm64, x86-64, x86
- Python : Python 3.11.13
  PyTorch : 2.5.1
  Numpy : 2.0.1

#### Configuration

Compile flags
- Chapel : `chpl ./file.chpl --fast --no-ieee-float`
- C++ : `clang++ ./file.cpp -O3 --std=c++20 -fopenmp -funroll-loops -ftree-vectorize -mavx2 -msse -ffast-math -march=native -fveclib=libmvec`
- Python : `python ./file.py`

Model
- Floating Point: 32 bits
- Small-Size Model
  - dModel : 32 - *Dimension of embedding layer of the encoder and decoder*
  - sequenceLength : 128 - *Maximum length of input seqeuence*
  - dFF : 256 - *Dimension of the feed-forward layer inside the encoder and decoder*
  - N : 6 - *Number of transformer encoder, decoder layers (stacked).*
  - head : 8 - *Number of attention heads in multi-head attention layer.*
  - srcVocab : 15700 - *Size of source vocabulary (number of unique tokens).*
  - tgtVocab : 22470 - *Size of target vocabulary*

- Full-Size Model
  - dModel : 512 - *Dimension of embedding layer of the encoder and decoder*
  - sequenceLength : 256 - *Maximum length of input seqeuence*
  - dFF : 2048 - *Dimension of the feed-forward layer inside the encoder and decoder*
  - N : 6 - *Number of transformer encoder, decoder layers (stacked).*
  - head : 8 - *Number of attention heads in multi-head attention layer.*
  - srcVocab : 15700 - *Size of source vocabulary*
  - tgtVocab : 22470 - *Size of target vocabulary*

{{< /details >}}

Machine A (AMD Ryzen) facilitated easy inspection of compiled code with permission to the `perf` command, allowing bottlenecks to be identified easily, while Machine B (Xeon Phi) did not. On the other hand, Machine A had a limited memory of 6.67 GB and was incapable of running the full-size model, whereas Machine B had 204.45 GB, allowing the full-size model to be run.

In order to measure the time required by each layer, timers were inserted into all layers. The model was then run on the Italian-English machine translation task, with the dataset obtained from opus_books ([Hugging Face link](https://huggingface.co/datasets/Helsinki-NLP/opus_books)). The model was executed for 500 and 40 iterations on Machines A and B, respectively. The timing results of each iteration for each layer were gathered and sorted; the fastest and slowest 10% of iterations were removed, and the mean and standard deviation were computed.
 
### Small-Size Model on Single Thread

First, I tested the small version of the model on Machine A. With this version, I was able to continuously inspect each part of the compiled program using the `perf` command and optimize the slow parts. The models were run for 500 iterations, and the mean and standard deviation were collected as described in the methodology section. The detailed results can be viewed in [this Google Spreadsheet](https://docs.google.com/spreadsheets/d/1aHkE9Ckl0-waxVwu-f4dIJ0peM6jIUQv3IU1-bFa0p0/edit?usp=sharing), and the single-thread implementation is available at [this GitHub link](https://github.com/markthitrin/Transformer/tree/SingleThread)

#### Result of Forward Pass

  {{< figure src="single-thread/each-forward.png" class="fullwide"
  caption="**Fig. 1.** Time spent on each layer (in microseconds) during a single forward-pass training iteration for each model, tested on Machine A (single-threaded) using the small model configuration.">}}

Since inserting timers into each layer of the transformer layer (`torch.nn.transformer`) in the PyTorch B model was difficult—because some layers, such as Softmax and ReLU, are function calls embedded between layers, preventing flexible placement of timer checkpoints—the detailed data for individual layers is missing. Therefore, only C++, Chapel, and PyTorch A’s individual layer elapsed times can be shown. This also applies to the other sections.

According to Fig. 1, most layers in Chapel performed as well as those in C++ and PyTorch A. Some layers even performed better, while only a few, such as Softmax and Dropout, performed worse. The poor performance of the Dropout layer is primarily due to the inefficiency of the random number generator (`randomstream.fill()`). I will discuss the performance issues of these layers in the next section.

You might expect the Linear and Multi-Headed Attention layers to dominate the execution time. While this is true for a larger model, in this small version, the execution time of these layers did not contribute as much. Additionally, the PyTorch version might be expected to be significantly faster than the C++ and Chapel versions, as it is equipped with optimized linear algebra libraries. However, since this is a small-size model, the execution time of Linear and Multi-Headed Attention layers did not dominate, and the matrix sizes were not very large. As a result, the performance of all versions was comparable.

#### Result of Backward pass

  {{< figure src="single-thread/each-backward.png" class="fullwide"
  caption="**Fig. 2.** Time spent on each layer (in microseconds) during a single backward-pass training iteration for each model, tested on Machine A (single-threaded) using the small model configuration.">}}

As for the backward pass, Fig. 2 shows that C++ and Chapel overall performed better than both Python versions. it also shows that Chapel could achieve relatively the same performance as C++, resulting in the total backward-pass time of Chapel and C++ in this configuration being almost the same.

#### Overall Result

  {{< figure src="single-thread/total.png" class="fullwide"
  caption="**Fig. 3.** Time spent on each layer (in microseconds) per training iteration (including forward, backward, and update) for each model, tested on Machine A (single-threaded) using the small model configuration.">}}

Fig. 3 shows the total time required for each training iteration, including the forward pass, backward pass, loss computation, and optimization. It can be seen that the Chapel version was slower than the others, primarily because the Softmax and Dropout layers were slower in the forward pass, while the other layers performed comparably. Since this was the small version of the model, the advantage of using PyTorch’s optimized linear algebra modules did not significantly manifest here, causing the performance to be comparable with C++ and Chapel. This advantage, however, will become more apparent in the results of the full-size model experiment on Machine B.

### Discussion Small-Size Model Performance

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
The Chapel version, however, uses an alternative approach. It uses built-in arrays to represent all matrices and tensors. Unlike C++, `ref` is not allowed to be in `class` or `record`, so a `TensorView` structure-like in Chapel cannot be constructed. I see this as a feature that would be beneficial to implement in the future.
```Chapel
class TensorView {
  // ref data; error, ref can not be declare in class or record 
}
```

Another interesting design choice I made is to use a 1D array instead of a multidimensional array to represent each matrix and tensor. In an earlier draft, I initially used a multidimensional array with the `LinearAlgebra` module. However, I found its performance to be significantly worse than expected. Upon inspecting the compiler-generated code, I discovered that iterating over elements in a multidimensional array invoked a function called `advance_chpl`, a function that retrieves the next item in an array, which introduced considerable overhead and prevented vectorization. This issue had already been reported in a GitHub issue titled ["Regarding multidimensional zippered iteration (or promotion) kills performance"](https://github.com/chapel-lang/chapel/issues/13147) and was noted as a known performance concern on the [Chapel website](https://chapel-lang.org/docs/technotes/optimization.html#performance-problems-with-multidimensional-zippered-iteration).

Although this could be mitigated by iterating over the array’s domain instead of its elements, doing so might introduce unknown performance issues with multidimensional arrays in the future. For these reasons, I decided to use the 1D array design, which is one of the methods suggested on the Chapel Performance Concerns website.

I also experimented with nested arrays, such as `var arr: [0..#N][0..#N] real(32)`. This approach yielded better performance, as the compiler treated it as a 1D array of 1D arrays. However, this made the array non-contiguous in memory, as each row is not guaranteed to be contiguous with the others, effectively equivalent to a `float**` in C++. As a result, it was still less efficient than using a pure 1D array.

#### Matrix Multiplication

The algorithm used for matrix multiplication is blocked matrix multiplication, in which the operation is divided into smaller blocks to exploit cache locality. A block size of 64×64 was chosen, as it provided the best performance in my environment. Both the C++ and Chapel versions use the same algorithm and block size.

After some tests, Chapel outperformed C++ for certain matrix sizes and underperformed for others, even though the compiler-generated code of the inner loops were nearly identical. This caused the performance of the linear layer, when tested on the full-size model, to be faster in Chapel than in C++. The cause of this variation remains unknown to me.

#### Matrix Operations

This section discusses general operations such as element-wise multiplication, addition, division, etc. As I wanted to have control over parallelism, there were several candidate designs, including overloading the array operators like `+`, `-`,  `*`, and `/` or creating new functions for these operations. As I experimented with performance and inspected the generated assembly, I found that the design and implementation of these operations had a greater impact on the model than I had expected. Therefore, I tested five versions of the sum-reduction function used in LayerNorm to calculate the mean. (However, the implementation of LayerNorm that used this function was later changed to be similar to the C++ version).

```Chapel
// query the domain from the array argument
proc PlusReduce1(ref A: [?D] real(32) out output: real(32),) : void {
    output = 0.0;
    for i in D {
       output += A[i];
    }
}

// pass domain explicitly
proc PlusReduce2(D: domain(1), ref A: [] real(32), out output: real(32)) : void {
    output = 0.0;
    for i in D {
        output += A[i];
    }
}

// pass starting and ending points explicitly
proc PlusReduce3(in start: int, in count: int, ref A: [] real(32), out output: real(32)) : void {
    output = 0.0;
    for i in start..#count {
        output += A[i];
    }
}

// use + reduce expression
proc PlusReduce4(ref A: [?D] real(32), out output real(32)) : void {
    output = + reduce(A);
}

// operator overloading
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
Plus();
Exp();
Mul();
// The compiler might combine them into a single loop 
// that performs plus, exp, and mul in each iteration.
```

4. The fourth method generates the same loop as the first but also creates a Chapel task when it is called.

5. The fifth method, overloading the operator, enabled clean code. However, it gave the same result as the first method.

Please note that this effect may or may not occur in specific cases. When I tested `PlusReduce1` and `PlusReduce2` individually outside the model, the optimization occurred normally, with the entire function inlined into `chpl_gen_main` (the main function appearing in the compiler-generated code).

As a result, I chose the third design, passing the array with start and end point manually, as it gives the best performance result. I also want to point out another reason that I didn't choose overloading operator even though it enables much cleaner code. As it requires additional memory allocation or copying in expressions that have three or more operands such as `C = A + B`, it costs unnecessary additional execution time, both in Chapel and C++.
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

It also appeared that using `rng.fill` is faster than using `rng.next` while iterating over an array. Since this function forces parallelism when available, `CHPL_RT_NUM_THREADS_PER_LOCALE=1` must be set accordingly when experimenting with a single thread.

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
The problem is that the compiler refuse to vectorize and unroll this loop. This was solved by seperating the loop into two section.
```Chapel
for i in D {
    outputGradient[i] = if input[i] >= 0 then outputGradient[i] else 0.0:real(32);
}
Copy(0,0,D.size,outputGradient,inputGradient);
```
Despite the optimization, Chapel is still a little slower than C++, as the copy section in the C++ version is recognized and replaced with `memcpy`

Chapel also got better performance than C++ in the forward pass of this layer. The compiled code is almost the same, with the same vectorizing and loop unrolling degree; the difference is that Chapel do load, max, and store separately, while C++ merge load and max oprations into one instruction.
```asm
// Chapel
load mem -> res
max 0,res -> res
store res -> mem
// C++
max 0,mem -> res
store res -> mem
```
This somehow makes the function in the Chapel version faster than that in C++ when tested on the small-size model. However, when tested on the full-size model, it makes the function in the Chapel version much slower than the function in the C++ version. Additionally, this performance drop when testing on the full-size model can also be seen in the backward pass of LayerNorm. I currently don't understand the reason that causes this effect.

#### Other Layers

The other layers seem fine and perform as well as or better than the PyTorch version. Moreover, the model optimization part, specifically the loss computation and Adam optimizer, appears to perform much better than in the PyTorch versions.

### Full-Size Model on Single and Multiple Threads

Now we moved our experiment to Machine B and set the model to full-size, as it has enough memory. The C++ version is integrated with OpenMP to enable multi-threaded computation, and for Chapel, multiple language features such as `forall`, `coforall`, and custom iterators were used. The parallel algorithms used in both C++ and Chapel are exactly the same. Synchronization happens at the end of each layer in both the forward pass and backward pass. The degree of parallelism for each layer is estimated individually to achieve the best performance on Machine B; for example, Softmax performs best on 68 cores, while LayerNorm performs best on 52 cores.

To see the gained speed-up, all models were tested with both single-thread and multi-thread on Machine B. The benchmark was conducted in the same way as on Machine A, but with only 40 iterations instead, as single-thread benchmarking took a while. The detailed data from this experiment can be viewed in [this Google Spreadsheet](https://docs.google.com/spreadsheets/d/15OgtaSJbzP82hHbCX5l9eBHmcuK-GTmn3bShM3-8Fxc/edit?usp=sharing), and all implementations can be obtained from [this GitHub link](https://github.com/markthitrin/Transformer/tree/MultiThread)

#### Result of Forward Pass

  {{< figure src="multi-threads/each-single-forward.png" class="fullwide"
  caption="**Fig. 4.** Time spent on each layer (in microseconds) during a single forward-pass training iteration for each model, measured on Machine B (single-threaded) using the full-size model configuration.">}}

  {{< figure src="multi-threads/each-multi-forward.png" class="fullwide"
  caption="**Fig. 5.** Time spent on each layer (in microseconds) during a single forward-pass training iteration for each model, measured on Machine B (multi-threaded) using the full-size model configuration.">}}
  
  {{< figure src="multi-threads/each-speedup-forward.png" class="fullwide"
  caption="**Fig. 6.** Speedup of each layer's forward pass in each model, tested on Machine B compared to its single-threaded version, using the full-size model configuration.">}}

Now, it can be seen in Fig. 4 and Fig. 5 that both PyTorch versions gain a huge advantage from having an optimized linear algebra library integrated into the model, resulting in better performance in the Linear and Multihead-Attention layers. Nevertheless, they still lost to Chapel and C++ on other layers. Although it might seem unfair to compare the Chapel and C++ versions, which are made from scratch, I think it is still a good idea to have existing frameworks as reference.

The Chapel version somehow outperforms the C++ version, thanks to performance in the Linear layer, which consumes huge resources. However, layers such as DropOut and Softmax in the Chapel version are still slower than in the C++ version. The reasons for such effects are likely the same as the reasons mentioned in the single-thread discussion.

#### Result of Backward Pass

  {{< figure src="multi-threads/each-single-backward.png" class="fullwide"
  caption="**Fig. 7.** Time spent on each layer (in microseconds) during a single backward-pass training iteration for each model, measured on Machine B (single-threaded) using the full-size model configuration.">}}

  {{< figure src="multi-threads/each-multi-backward.png" class="fullwide"
  caption="**Fig. 8.** Time spent on each layer (in microseconds) during a single backward-pass training iteration for each model, measured on Machine B (multi-threaded) using the full-size model configuration.">}}

  {{< figure src="multi-threads/each-speedup-backward.png" class="fullwide"
  caption="**Fig. 9.** Speedup of each layer's backward pass in each model, tested on Machine B compared to its single-threaded version, using the full-size model configuration.">}}
  
As you can see from Fig 8. performance of almost all layers of Chapel and C++ are on par with each other in backward pass, except LayerNorm that happened to be slower. Besides, both need more optimization on linear algebra in order to be as good as PyTorch. Fig 9. shows that in this case, Chapel exploited the parallalism better than C++ in many layers. I have not fully understood the reason but I suspected that this is probably due to the lower computation per time achieved in single thread with the same memory bandwith request. Thus the achivable performance of such layers is limited by memory bandwith of the machine itself, and the final performance turned out to be the same.

#### Overall Result

  {{< figure src="multi-threads/total-single.png" class="fullwide"
  caption="**Fig. 10**. Time spent on each layer (in microseconds) per training iteration (including forward, backward, and update) for each model tested on Machine B (single-threaded) using the full-size model configuration.">}}

  {{< figure src="multi-threads/total-multi.png" class="fullwide"
  caption="**Fig. 11**. Time spent on each layer (in microseconds) per training iteration (including forward, backward, and update) for each model tested on Machine B (multi-threaded) using the full-size model configuration.">}}

  {{< figure src="multi-threads/speedup-total.png" class="fullwide"
  caption="**Fig. 12**. Speedup of total time per training iteration (including forward, backward, and update) for each model tested on Machine B compared to its single-threaded version using the full-size model configuration.">}}

In conclusion, the overall performance achieved is reasonable, with Chapel performing slightly better than C++ thanks to its improved multi-thread attention and linear layers. All versions gained about 20 times speedup with multi-thread enabled.

### Discussion Full-Size Model Performance

I will discuss the implementation details and optimizations I applied to achieve these results in this section.

#### Matrix Multiplication

The method I chose is to parallelize the two outermost loops of the blocked tiled matrix multiplication. Since the computation-to-memory-access ratio in the inner loop is very high, the degree of parallelism for this function does not need to be limited.

```Chapel
forall (ii, jj) in MatMulPar(d1, d3) { // iterate ii and jj in parallel
    for kk in 0..<d2 by BLOCK_SIZE { // iterate kk sequentially
        // Perform matrix multiplication for each block
    }
}
```

#### Matrix Operations

These functions simply divide the work into consecutive blocks. Since element-wise operations such as `+`, `-`, `*`, `/`, and other reduction functions have a low computation-to-memory-access ratio, the parallelism of these methods needs to be limited. According to estimation and testing, the suitable number of threads is typically around 24.

#### Softmax

This layer requires a special care, as the algorithm needs a buffer to cache the exponential values. When introducing parallelism, separating the buffer for each thread is necessary.

I encountered a problem defining the buffer, as I initially tried to declare the buffer inside the loop the same way I did in the C++ version.

```Chapel
// Chapel
forall i in D {
    var buffer: [dom] real(32); // memory allocation
    exp(input, buffer) // compute exp one time
    sumreduce(buffer, sum) // use 1
    Div(buffer, output) // use 2
    // automatically deallocated of buffer at the end of this iteration
}
```
```cpp
// C++
#pragma omp parallel
for(int i = 0;i < row;i++) {
    float buffer[size]; // stack memory
    exp(input, buffer)
    sumreduce(buffer, sum) // use 1
    Div(buffer, output) // use 2
    // no memory deallocation for buffer
}
```
The performance turned out to be very poor. This is likely because declaring the buffer inside the loop causes memory allocation and deallocation on every iteration, whereas in C++, declaring `float buffer[size];` allocates the memory on the stack, avoiding this overhead. To solve this problem, the buffer must be declared outside the loop, with each thread accessing a different segment of the buffer.
```Chapel
var buffer: [dom] real(32); // memory allocation one time

forall i in D {
    exp(input, buffer[thread[i]]) // compute exp into thread i's buffer chunk
    sumreduce(buffer[thread[i]], sum) // use 1
    Div(buffer[thread[i]], output) // use 2
    // no memory deallocation for buffer
}
```

#### LayerNorm

An observation that can be seen in Fig. 8 is that LayerNorm is surprisingly much slower than C++ in the backward pass. This occurs in both single-thread and multi-thread execution on the full-size model. I have not yet fully understood the reason behind LayerNorm being the slowest on large-size matrices, even though the compiled loops are the same. Chapel causes much more L1 cache misses than C++ does when tested with `perf stat`.

#### Multihead Attention

The new design of this layer is not complicated. Although the flow of the multihead attention layer offers opportunities for parallelism, the size of the matrices used to compute in this layer are already very large and utilize all the resources on the machine during the multiplication. Therefore, parallelization on some of the outer loops is not required.

```Chapel
proc forward(/*...*/) {
    // ...

    // Matrix is large and consumes all resources when computed, 
    // so no need for parallelization here
    for i in 0..#batch {
        MatMulABTPar(WQ, inputQ[(i * block)..#block], QT[(i * block)..#block]); // QT = (WQ)^T * inputQ
        MatMulABTPar(WK, inputK[(i * block)..#block], KT[(i * block)..#block]); // KT = (WK)^T * inputK
        MatMulABTPar(WV, inputV[(i * block)..#block], VT[(i * block)..#block]); // VT = (WV)^T * inputV
    }

    // Matrix inside is small, so parallelization here is preferable
    forall i in 0..#batch {
        for j in (i * head)..#head {
            MatMulATBPar(QT[(j * blockPerHead)..#blockPerHead], KT[(j * blockPerHead)..#blockPerHead], A[(j * blockAtt)..#blockAtt]); // A = (Q)^T * K
        }
    }
    // ...
}
```

#### Other Layers

As for the implementation of other layers, it is straightforward. Some layers might not be able to exploit all available parallelism, for example, the embedding layer, which doesn’t use much computation. Fortunately, this layer doesn’t consume as many resources as the linear and multi-head Attention layers and therefore does not impact performance significantly.

During optimization, every parameter update was done individually using task creation features in both C++ OpenMP and Chapel. This part of the training process is already much better than in PyTorch when running single-threaded, and it improves even more with parallelism. Additionally, both C++ and Chapel tend to have the same performance when doing the parameter updating.

### Discussion on Productivity

As this is my very first Chapel project, and while I have been writing C++ for years, productivity isn't fairly comparable. However, it did exhibit some advantages and disadvantages throughout the project, allowing me to share some thoughts about them as a user.

There are several things that I like about Chapel:
- The language is easy to learn as it's similar to Python.
- It provides easy parallel programming through for loops, custom parallel iterators, automated thread scheduling, etc.
- As a language that requires type declaration of variables, this allows the user to detect errors at compile time.
- Object memory management
- Memory management between threads
- It is easier to make the program run on multi-locales.

Nevertheless, there are several shortcomings I found about Chapel, too:
- Long compilation time, which is especially so when multi-locale is introduced.
- Downcasting among numeric types, such from `real(64)` to `real(32)`, is done implicitly in C++, but not in Chapel (I am not sure which approach is better).
- All the performance issues that I mentioned in this blog. This causes tricky fixes to be made and it makes the code messy.

Chapel took as long as C++ to implement this transformer model in this project as it required some tricky fixes. The productivity of implementing and parallel programming tends to be the same as C++ and OpenMP, as far as this project is concerned. I believe that having the same level of expertise, Chapel could be more productive than C++ and Python in doing scientific simulations that require parallelism on multithread and multilocale as it automates data movement and configuration. However, it has much less support frameworks than Python, making it hard to create a project, and less control over the machine than C++, making it difficult to conduct performance research.

One controversial thought I have is that generative AI, such as ChatGPT, should be able to help programmers fix and implement projects, for example, by creating simple test cases. However, since the language is not very popular and has less code available on the Internet, combined with the backwards-incompatible evolution of the language, current large language models do not have much knowledge of it and can easily become confused, which can cause them to produce faulty code. Interestingly, there is already a Chapel blog, [Experimenting with the Model Context Protocol and Chapel](https://chapel-lang.org/blog/posts/claude-mcp/), that explores this idea. By using the Model Context Protocol (MCP), they achieved surprisingly good results. I believe that improving the capability of large language models in Chapel programming could greatly impact productivity and should be investigated and improved further.

In the end, Chapel serves well as a programming language dedicated to parallel programming and indeed increases productivity compared to C++. It also has many features that can improve the language’s performance and efficiency.

Even though today it might be more feasible to enable parallel programming by creating a programming language dedicated to it, I dream of having a highly capable compiler, interpreter, or tool that can handle all parallelization, optimization, and deployment automatically and can be applied to any programming language.

### Conclusion

This project illustrates an attempt to implement the Transformer model in Chapel. The final performance achieved is reasonable and comparable to C++, and potentially to PyTorch if its optimized linear algebra algorithms are utilized. Nevertheless, many performance issues were encountered during implementation, such as problems with multidimensional arrays, vectorization, loop unrolling, and more. While many issues can be resolved or avoided using special tricks that add complexity to the code, some problems are unavoidable, such as random number generation and non-vectorized exponential functions.

Additionally, I would like to see some language features implemented, such as `ref` in classes and records, as well as stack-allocated arrays. Faster compilation times would also be a great improvement.

Regarding the limitations of this project, due to time constraints and my current capabilities, the scope is limited to CPU performance, both single-threaded and multi-threaded. GPU and multi-locale performance are interesting topics but were not explored. These areas could be investigated further in the future to evaluate performance differences on GPU and multi-locale systems.

As this is my first Chapel project and one of the first performance-measurement projects at this scale, many improvements can surely be made in code design, implementation, testing, benchmarking, and presentation. I would greatly appreciate any advice and comments. You can submit them via email at thitrin.sastarasadhit@gmail.com. I look forward to improving myself, growing in this field, and making a meaningful impact.