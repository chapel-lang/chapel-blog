var A: [1..10] int;
var B,
    C = A;

// Convert 'foreach' loop expression into array by assigning it to a variable.
// The type annotation explicitly shows where the array is created. 
var FromIter = foreach i in 1..10 do i : real;

foreach (x, y, z) in zip(A, B, FromIter) {

}

var AD = A.domain;
var AssocD = {"key", "another key"};
type SubAD = sparse subdomain(A.domain);
var mySD: SubAD;