// NetCDF in Chapel, Part 2: Reading a Dataset in Parallel
// tags: ["User Experiences", "How-To", "I/O", "Parallel I/O", "Interoperability"]
// languageFeatures: ["C Interoperability"]
// series: ["NetCDF in Chapel"]
// summary: "Exploring distributed file IO in Chapel using distributed domains, arrays, and hyperslabs while handling unknown dataset shapes"
// authors: ["Scott Bachman"]
// date: 2023-05-03

/*
This blog post is a follow-up to the first episode in this series, which focused 
on Chapel's C interoperability features for reading files in NetCDF format. In 
the previous post we used Chapel's `extern` keyword to interface with the NetCDF 
C library, and were able to learn some information about our dataset that we 
will need to store it in a Chapel array. We had not run into any trouble 
regarding the fact that the dataset's shape was unknown beforehand, but in this 
post we will highlight some complications that arise (and how to handle them!). 
Finally, we will take advantage of Chapel's task parallel features to store our 
dataset in an array that is distributed across _locales_, where a locale in Chapel
is a group of processors and their memory, such as a compute node in a cluster or
supercomputer. Storing the data in distributed arrays will set us up for fast, 
parallel computations further down the road.

**The combined code from Part 1 and this post can be seen here:**
{{< whole_file_min >}}

### Recap of Part 1


*/

require "netcdf.h", "-lnetcdf";
use CTypes, BlockDist;

config const filename = "myFile.nc",
             datName = "test1D";

extern proc nc_open(path: c_ptrConst(c_char), mode: c_int, ncidp: c_ptr(c_int)): c_int;
extern const NC_NOWRITE: c_int;

proc main() {

  var ncid, datid, ndims, dimid: c_int;

  // Open the file
  nc_open(filename.c_str(), NC_NOWRITE, c_ptrTo(ncid));

  // Get the dataset ID
  extern proc nc_inq_varid(ncid: c_int, datName: c_ptrConst(c_char), varid: c_ptr(c_int));

  nc_inq_varid(ncid, datName.c_str(), c_ptrTo(datid));

  // Get the number of dimensions for this dataset
  extern proc nc_inq_varndims(ncid: c_int, varid: c_int, ndimsp: c_ptr(c_int));
  nc_inq_varndims(ncid, datid, c_ptrTo(ndims));

  // Get the IDs of each dimension
  var dimids: [0..<ndims] c_int;
  extern proc nc_inq_vardimid(ncid: c_int, varid: c_int, dimidsp: c_ptr(c_int)): c_int;
  nc_inq_vardimid(ncid, datid, c_ptrTo(dimids));

  // Get the size of each dimension
  var dimlens: [0..<ndims] c_size_t;
  extern proc nc_inq_dimlen(ncid: c_int, dimid: c_int, lenp: c_ptr(c_size_t)): c_int;
  for i in 0..<ndims {
    nc_inq_dimlen(ncid, dimids[i], c_ptrTo(dimlens[i]));
  }

  // Close the NetCDF file
  extern proc nc_close(ncid: c_int);
  nc_close(ncid);

/* The above code block is a concise, combined version of the code that was 
presented in Part 1. Here, we have created all the infrastructure we need to 
know the ID and shape of the dataset we want to read. We have stored the 
variable ID in `datid`, the number of dimensions in `ndims`, and the length of 
each dimension in an array, `dimlens`. Thus far, the code has been agnostic to 
the shape of the dataset; once `ndims` is known, it would have simply allocated 
enough heap space for the `dimids` and `dimlens` arrays to handle whatever the 
shape is. Creating the arrays to store the dataset will be a different story, 
however.
*/

  // Create the domain and distributed array to hold the data

  if ndims == 1 {
    var dom_in = CreateDomain(1, dimlens);
    DistributedRead(filename, datid, dom_in);
  }
  else if ndims == 2 then {
    var dom_in = CreateDomain(2, dimlens);
    DistributedRead(filename, datid, dom_in);
  }
  else if ndims == 3 then {
    var dom_in = CreateDomain(3, dimlens);
    DistributedRead(filename, datid, dom_in);
  }
  else if ndims == 4 then {
    var dom_in = CreateDomain(4, dimlens);
    DistributedRead(filename, datid, dom_in);
  }
  // else if etc. etc.
  else {
    halt("Can't yet handle >4 dimensions");
  }
}

/* This block follows immediately after the for-loop calling `nc_inq_dimlen()`, 
where we now call two procedures, `CreateDomain()` and `DistributedRead()` (described 
below). The biggest thing to notice here is that I have used branching logic 
at this step, depending on how many dimensions our dataset has. This is because 
in Chapel the _dimensionality_ of {{< sidenote "right" "domains">}}In Chapel, a _domain_ is a language feature representing an index set.  In practice, domains are used to declare arrays and specify iteration spaces.  As an example `{1..100, 1..100}` is a domain value representing a 2D 100×100 index set. {{< /sidenote >}} and arrays has to be known at compile-time (contrast this to an interpreted language like Python, which allows arrays 
of any rank to be created interactively).  This constraint is one reason that Chapel is 
able to achieve such high performance and optimization for array operations. 
In practice, this means that I have to create a different set of instructions 
for each possible dimension of the dataset (essentially telling the compiler to 
prepare for each potential incoming array rank). This clearly would become a 
pain if the NetCDF file contained data with a large number of dimensions, as a 
lot of boilerplate code would need to be written to handle all possible cases
(though this logic could be hidden from the user by pushing it into a library 
routine, instead of calling directly into C as is done here). 
Here, we are assuming that we're only interested in reading "typical" climate 
science datasets, which tend to have no more than 4 dimensions. An `else` 
statement halts the program and returns an error message if the user reads a 
dataset with more than 4 dimensions.

{{< details summary = "**Sidebar: reducing boilerplate code #1**" >}}
There are some obvious repetitions in the previous code block, namely its 
reliance on repeated lines of very similar (i.e. boilerplate) code, which 
causes us to stop at the `ndims==4` case to keep the program size from
sprawling. Here is an alternative pattern that semantically achieves the same 
result, except in a much more concise way:  

   ``` chapel
   config param maxDims = 4;
   
   if ndims > maxDims then
     halt("Current build can't read " + numdims:string + "-dimensional arrays.\n"
          "Recompile with -smaxDims=" + numdims:string + " to support them.");

   for param p in 1..maxDims {
     if ndims == p {
       var dom_in = CreateDomain(p, dimlens);
       DistributedRead(filename, datid, dom_in);
     }
   }
   ```
The `for` loop here allows us to handle datasets with up to 4 dimensions, 
which, of course, is an arbitrary choice — we could substitute larger integers, 
if desired, though this would incur extra compile time. Note that an
error message has also been included to handle the case when `ndims` is greater 
than `maxDims`. In practice one would probably use the largest dimensionality 
that he or she would expect to encounter in the NetCDF file.

{{< /details >}}

### Preparing for Distributed I/O

*/

proc CreateDomain(param numDims, indicesArr) {

  if numDims == 1 {
    return {0..<indicesArr[0]};
  } else if numDims == 2 {
    return {0..<indicesArr[0], 0..<indicesArr[1]};
  } else if numDims == 3 {
    return {0..<indicesArr[0], 0..<indicesArr[1], 0..<indicesArr[2]};
  } else if numDims == 4 {
    return {0..<indicesArr[0], 0..<indicesArr[1], 0..<indicesArr[2], 0..<indicesArr[3]};
  }
  // else if etc. etc.

}

/* The procedure `CreateDomain()` takes as input an integer literal to represent 
the number of dimensions, as well as our array `dimlens` to inform the shape of 
the domain we need to create. We then create and return a domain, stored
in the variable `dom_in` back at the callsite. 
The range of each dimension `i` is from `0` to `dimlens[i]-1`, 
which is expressed in `CreateDomain()` using the `..<` operator. We will use 
`dom_in` to create our distributed array in the next step.

{{< details summary = "**Sidebar: reducing boilerplate code #2**" >}}
The above code block suffers from the same repetitive patterns that we encountered 
previously, so here is another alternative pattern to tidy this up. I have 
chosen to put this code in the Sidebar to keep the main discussion at an 
introductory level, and to keep the more advanced syntax here from derailing 
the tutorial:

    ``` chapel
    proc CreateDomain(param numDims, indicesArr) {
      var indices: numDims*range;
      for param i in 0..<numDims do
        indices[i] = 0..<indicesArr[i];
      return {(...indices)};
    }
    ```

{{< /details >}}

### Executing the Distributed I/O


*/

inline proc tuplify(x) {
  if isTuple(x) then return x; else return (x,);
}

proc DistributedRead(const filename, datid, dom_in) {

  const D = blockDist.createDomain(dom_in);
  var dist_array: [D] real(64);

/* After we have created our domain in the previous code block, our program 
calls `DistributedRead()` to actually perform the parallelized reading of the 
dataset. This procedure takes as input arguments the domain, `dom_in`, as well 
as `filename` and `datid`, since we have to open up the NetCDF file 
_on each locale_ where we wish to do the reading. Note that I also include here the 
definition of another procedure, `tuplify()`, which will be used shortly.

Our first task inside `DistributedRead()` is to use the `BlockDist` module to create 
a block-distributed version of `dom_in`, which we call `D`. Essentially `D` is a 
partitioning of `dom_in` that is evenly distributed across our locales, in 
preparation for having each locale read only its own chunk of the dataset. We 
then create a distributed array using this domain called `dist_array`, which 
contains elements of type `real(64)` (note that this only specifies the type 
that our dataset will be stored as, _not_ its type in the NetCDF file. That is, 
the data type of the incoming dataset does not have to be `real(64)`, thanks to 
NetCDF cleverly distinguishing between _internal_ and _external_ types; see 
https://docs.unidata.ucar.edu/nug/current/md_types.html for details). Since 
`dist_array` will be used to store the incoming dataset, there is no need to 
assign values to it at this time, so all elements initially have a value 
of zero. */

  coforall loc in Locales do on loc {

    //      int nc_get_vara_double(int ncid, int varid, const size_t* startp, const size_t* countp, float* ip)	
    extern proc nc_get_vara_double(ncid: c_int, varid: c_int, startp: c_ptr(c_size_t), countp: c_ptr(c_size_t), ip: c_ptr(real(64))): c_int;

/* We now use a `coforall` loop and an on-clause, `on loc`, to create a 
task-parallel reading of our NetCDF file. The code block inside the curly 
braces of the `coforall` loop executes on each locale, so our objective here is 
to make the program read in only the part of the dataset from the NetCDF file 
that should be stored on that particular locale, and to store it to the 
corresponding part of `dist_array`. 

The first line inside the loop creates an `extern` declaration of the function 
we need for reading, `nc_get_vara_double()`. As in Part 1, the corresponding C 
version of this function declaration is in the commented text on line 91. This 
function has two arguments that we need to construct carefully that lets us do 
the distributed read: `startp` and `countp`. These are pointers to variables 
`start` and `count`, respectively, which represent _hyperslabs_, which is a 
really just a concise way of saying "rectilinear chunks of the dataset". */

    // Determine where to start reading file, and how many elements to read
    // Start specifies a hyperslab.  It expects an array of dimension sizes
    var start = tuplify(D.localSubdomain().first);

    // Count specifies a hyperslab.  It expects an array of dimension sizes
    var count = D.localSubdomain().shape;

    // Create arrays of c_size_t for compatibility with NetCDF-C functions.
    var start_c, count_c: [0..<dom_in.rank] c_size_t;
    start_c = start;
    count_c = count;

/* `start` is a tuple that represents which element of the dataset to start 
reading at, and `count` is another tuple that represents the size of the chunk 
that we want to read. Notice that the assignment `start` uses a 
procedure, `tuplify()` (shown earlier), to ensure that it always has the  
tuple type (this is mainly used as a guardrail against the `ndims=1` case, 
for which the `first` method would return a scalar instead. Tuples 
are needed here to be compatible with the way we have to loop over these arrays, 
i.e. `start[i]`; the compiler would not allow a scalar to be indexed like this). 
For `start` we use the `localSubdomain().first` method to specify the first 
element of `D` that belongs to this locale, and for `count` we use 
`localSubdomain().shape` to obtain the size of the chunk to read. We then convert 
the elements of `start` and `count` into the `c_size_t` type that is required 
by `nc_get_vara_double()`. */

    var ncid: c_int;
    nc_open(filename.c_str(), NC_NOWRITE, c_ptrTo(ncid));

    nc_get_vara_double(ncid, datid, c_ptrTo(start_c), c_ptrTo(count_c), c_ptrTo(dist_array[start]));

    nc_close(ncid);
  }

  return dist_array;

}

/* Now it is time to open our file again, except this time it is opened on each 
locale since it is inside the `coforall` loop and `on`-clause. Here, we avoid 
a "gotcha" that is crucial to point out! Notice that we passed `filename` 
into the `DistributedRead()` procedure as a Chapel string, and then inside the 
`nc_open()` statement we used the `c_str()` method to cast it into a `c_ptrConst(c_char)`. 
Why could we not just pass it into `DistributedRead()` as a C string in the first 
place?  It turns out that C pointer types like  `c_ptrConst(c_char)`
can only point to local memory, so a routine like `nc_open()` can't 
accept a pointer to remote data, which is what would happen if one created a 
pointer to local data on one locale and then referenced it on another locale.
Essentially this means that if `filename` is already a C string _before_ 
entering the `coforall` loop its string data will _not_ be broadcast to each other locale, 
and the actual argument inside `nc_open()` will have a pointer to arbitrary memory 
instead. So be careful when playing with C interoperability in a distributed 
environment! 

Finally, we can call the `nc_get_vara_double()` function to perform the read, 
keeping in mind that we need to point to `dist_array[start]` so that the local 
reading occurs at the correct part of `dist_array`. After the `coforall` loop 
terminates, the `DistributedRead()` procedure returns the now-filled `dist_array` 
to us, with the distributed dataset stored within. Note that if we wanted to do 
operations on/with this array once it is returned, we would have to declare a 
variable in `main()` to receive it, e.g. `var myArray = DistributedRead(...);`

### Summary

In this post we have built upon the C interoperability lessons from Part 1 and 
added some distributed task parallelism on top. We got to use some elegant Chapel syntax 
to specify where to start reading the dataset on each locale, and which part of 
`dist_array` to put that chunk in. Hopefully this has been a good use case to 
demonstrate these features of Chapel, and will help users get started with 
their own codes that interoperate with C.

Of course for succinctness we have omitted some details that may have caught 
the reader's attention. Here, we hard-coded a `real(64)` type to store our input 
dataset, but what if we want our dataset to be stored using another type, like 
32-bit float or even an integer? Is there a way to handle all possible data 
types succinctly, without a load of boilerplate code? Is the default `blockDist` 
distribution always the best one to use?  What if we want to do arithmetic 
along one axis of our dataset, but that axis is split across multiple locales?  
Wouldn't it be better if we kept that axis all on a single locale, and how do 
we do that? Lastly, NetCDF has a `_FillValue` attribute that tells the user 
which parts of the dataset contain values that should be ignored; how can we 
deal with that in Chapel, and in particular, this code?  

For answers to these questions, stay tuned for future articles on these topics!

### Updates to this article

{{< changetable >}}
  | Date         | Change                                                      |
  |:-------------|:----------------------------------------------------------------------------------|
  | Apr 4, 2024  | Replaced used of deprecated `c_string` with `c_ptrConst(c_char)` |
  | Apr 4, 2024  | Replaced used of deprecated `Block` with `blockDist` |

*/
