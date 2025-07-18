var A = [ 1, 2; 3, 4 ];
var B: [A.domain] real;

var maxReciprocal = 0.0;
forall (x, y) in A.domain with (max reduce maxReciprocal) {
  B[x, y] = 1.0 / A[x, y];
  maxReciprocal reduce= B[x, y];
}
