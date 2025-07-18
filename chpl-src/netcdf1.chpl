// NetCDF in Chapel, Part 1: Interfacing with the C Library
// tags: ["User Experiences", "How-To", "I/O", "Interoperability"]
// languageFeatures: ["C Interoperability"]
// series: ["NetCDF in Chapel"]
// summary: "An introduction to C interoperability in Chapel using the NetCDF library"
// authors: ["Scott Bachman"]
// date: 2023-04-26

/* 
This blog series demonstrates the use of Chapel's C interoperability features for
reading (and later, writing) files written in the Network Common Data
Format (NetCDF), which is presently the most commonly used format for storing
climate and earth system model data. NetCDF files can contain multiple arrays of
data ("datasets") arranged in a hierarchical format, and they contain all metadata for 
each dataset within the file itself. Here, the capability to read NetCDF files is
provided using the {{< sidenote "right" "`extern` keyword," >}} Other options for interoperability can be found in Chapel's
[language specification](https://chapel-lang.org/docs/language/spec/interoperability.html) and [technical notes](https://chapel-lang.org/docs/technotes/extern.html){{< /sidenote >}} which makes the Chapel compiler aware of 
external C functions and constants we want to use. We will use functions 
from the NetCDF C library, for which full documentation can be found 
at https://docs.unidata.ucar.edu/netcdf-c/current/modules.html.

### Basic C interoperability

Chapel allows the user to refer to external C functions, variables, and types.  
Here, we will do this _explicitly_ by writing a declaration for each C function, 
variable, or type that we wish to use. When there are any additional library 
or header dependencies that are needed, these can be specified on the Chapel 
compiler's command line or by using the ['require'](https://chapel-lang.org/docs/technotes/extern.html#expressing-dependencies) 
statement. As an example, the compilation instruction used for this program
on the author's laptop is:

```bash
$ chpl -I/opt/local/include -L/opt/local/lib -lnetcdf \
  --ldflags="-Wl,-rpath,/opt/local/lib" read_netcdf_parallel.chpl
```

Akin to how compile flags are invoked in C, `-I` and `-L` indicate the paths to 
the header and static libraries where NetCDF is installed, `-l` indicates the 
library to be linked, and `-ldflags` specifies the library location for the linker.
The program described here and in Part 2 of this series is 
`read_netcdf_parallel.chpl`.

**The full code from this post can be seen here:**
{{< whole_file_min >}}

### The problem
In this demonstration we perform the very typical task of reading in a dataset 
from a file whose name is known, _but whose size is unknown_. This is set up 
so that I can specify the file and dataset at runtime from the command line, 
e.g.,

```bash
$ ./read_netcdf_parallel --filename=myFile.nc ‑‑datName=myDataset
```

This post will cover the first 
part of the problem, which will be to read the NetCDF metadata to get 
information about the dataset and the shape of the array we will need to make. 
The distributed reading of the dataset will be shown in Part 2.
*/

require "netcdf.h", "-lnetcdf";
use CTypes, BlockDist;

config const filename = "myFile.nc",
             datName = "test1D";

proc main() {

/* Above, I am declaring a pair of _configuration constants_ to
   specify the NetCDF filename and dataset name, respectively.
   Because these are `config` declarations, their default values can
   be overridden on the executable's command line using flags like
   `--filename="someOtherFile.nc"` or `--datName="someOtherData"`.
   Also, I have elected to use a standard module, `CTypes`, which will
   come in handy shortly, and the `BlockDist` module, which will be
   needed in Part 2 of this series.  We then enter the `main()`
   procedure which defines the program's main computation itself.  */


  var ncid, datid, ndims, dimid: c_int;

  // Open the file
  //      int nc_open(const char* path, int mode, int* ncidp)	
  extern proc nc_open(path: c_ptrConst(c_char), mode: c_int, ncidp: c_ptr(c_int)): c_int;

  extern const NC_NOWRITE: c_int;

  nc_open(filename.c_str(), NC_NOWRITE, c_ptrTo(ncid));

/* Here, I start by declaring some integer variables that will be used to access 
and store some information about the NetCDF file and my desired dataset.  Note 
that I declare these using the `c_int` type, rather than the standard Chapel 
`int` type.  This is necessary because the C specification allows compilers to 
determine how many bits are used in the representation of various types, so 
Chapel and C integer types are not necessarily equivalent. To make life easier, 
the `CTypes` module mentioned earlier defines a set of type aliases that 
describe certain C types using their Chapel equivalents.  In this case, the 
module will guarantee that each `c_int` variable is assigned the correct number 
of bits, and thus is understood correctly by the C functions we use.

At the bottom of this code box, we use our first C function, `nc_open()`, which
simply opens the file for reading or writing. For comparison against our Chapel
definition of this function, in the commented text on line 11, I have placed
the documentation for the original C version. To make `nc_open()` accessible in
Chapel we use an `extern` declaration, and match the formal argument types
against those on line 11. Thus the arguments are a `c_ptrConst(c_char)` for
`path`, a C integer for `mode`, and a C pointer to a C integer for `ncidp`. We
also use `extern` to declare the `NC_NOWRITE` constant, which tells `nc_open()`
that we are only interested in reading from the file.

The call to `nc_open()` assigns the integer ID handle of our NetCDF file to the 
variable `ncid`. In the function call we use the `c_str()` method to convert 
`filename`, which is a Chapel string, into a C string. We also use the 
`c_ptrTo()` method to construct a C pointer type that points to `ncid`, as is 
expected by the function declaration.
*/
  
  // Get the dataset ID
  //
  //      int nc_inq_varid(int ncid, const char* datName, int* varid)
  extern proc nc_inq_varid(ncid: c_int, datName: c_ptrConst(c_char), varid: c_ptr(c_int));

  nc_inq_varid(ncid, datName.c_str(), c_ptrTo(datid));

/* 
Now that the file is open, we need to find out the integer ID of our desired 
dataset, which requires a new function, `nc_inq_varid()`. Our strategy is again 
to match the formal argument types of our `extern` declaration against the C 
version on line 20. The function takes as input arguments the file ID, which 
has been stored in `ncid`, and our dataset name converted into a C string.
It then assigns the integer dataset ID into `datid`. 
*/

  // Get the number of dimensions for this dataset
  //
  //      int nc_inq_varndims(int ncid, int varid, int* ndimsp)
  extern proc nc_inq_varndims(ncid: c_int, varid: c_int, ndimsp: c_ptr(c_int));

  nc_inq_varndims(ncid, datid, c_ptrTo(ndims));

/* Now that we know the ID of our dataset, we must query how many 
dimensions it has. Here, we employ a function, `nc_inq_varndims()`, that stores 
the number of dimensions for our dataset in `ndims`. As before, we match the 
formal argument types in our `extern` definition against the C version on 
line 27. When we call the function, recall that the actual arguments, `ncid`, 
`datid`, and `ndims`, all have the `c_int` type from our earlier declarations, 
and we are using the `c_ptrTo()` method to create a C pointer to `ndims`.
*/

  var dimids: [0..<ndims] c_int;

  // Get the IDs of each dimension
  //
  //      int nc_inq_vardimid(int ncid, int varid, int* dimidsp)
  extern proc nc_inq_vardimid(ncid: c_int, varid: c_int, dimidsp: c_ptr(c_int)): c_int;

  nc_inq_vardimid(ncid, datid, c_ptrTo(dimids));

/*  NetCDF stores dimensions in a similar fashion to variables, in that each 
has a unique integer identifier. The next step is to get the unique ID for each 
dimension, which we store in an _array_ of `c_int` called `dimids`. The square 
brackets tell the compiler that this is an array, where the range `0..<ndims` 
specifies the indices for which the array is defined: from `0` to `ndims-1`
(or "from `0` to `ndims`, excluding `ndims`").

Note that the C definition on line 36 expects its formal argument, `dimidsp`, 
to point to an array, but in C this simply means that it points to the address 
of the first _element_ of the array, hence its type is `int*`. So in our 
`extern` definition we can tell Chapel that the formal argument `dimidsp` is a 
C pointer to a single C integer. In the call to `nc_inq_vardimid()` we can then 
simply use the `c_ptrTo()` method to point at our array `dimids`, which causes 
the compiler to create a C pointer to its first element.
*/

  var dimlens: [0..<ndims] c_size_t;

  // Get the size of each dimension
  //
  //      int nc_inq_dimlen(int ncid, int dimid, size_t* lenp)
  extern proc nc_inq_dimlen(ncid: c_int, dimid: c_int, lenp: c_ptr(c_size_t)): c_int;

  for i in 0..<ndims {
    nc_inq_dimlen(ncid, dimids[i], c_ptrTo(dimlens[i]));
  }

  // Close the NetCDF file
  //
  //      int nc_close(int ncid)
  extern proc nc_close(ncid: c_int);
  nc_close(ncid);

}

/* Finally, we can query the size of each dimension of our dataset, 
which we store in an array of the `c_size_t` type called `dimlens`. We use a 
function called `nc_inq_dimlen()`, and the formal arguments of our `extern` 
definition again match those of the C version on line 45. 

Note that `nc_inq_dimlen()` only expects a single `dimid`, and it returns a single 
dimension size that is stored at the address pointed to by `lenp`. This means 
that we must loop over each dimension of our dataset individually in order to 
fill our array `dimlens`. This is accomplished by a simple `for` loop, where 
we are simply iterating over each element of our arrays `dimids` and `dimlens`. 
We finish this part of our program by calling `nc_close()`, which closes the 
NetCDF file to further reading.

### Summary

In this post we have demonstrated some of Chapel's C interoperability features 
by showcasing their utility for reading NetCDF datasets. Thus far, we have opened 
a NetCDF file and stored information about our dataset's ID, its dimensions, 
and their sizes. In a follow-up post this information will be used to actually 
read the dataset into a distributed array that is stored across our cluster's 
compute nodes. This will employ a bit more of the C interoperability that has been 
discussed here, but will focus more on the nuances of how to do this without 
knowing the dataset's size or shape _a priori_. 

### Updates to this article

{{< changetable >}}
  | Date         | Change                                                      |
  |:-------------|:----------------------------------------------------------------------------------|
  | Apr 4, 2024  | Replaced used of deprecated `c_string` with `c_ptrConst(c_char)` |

*/
