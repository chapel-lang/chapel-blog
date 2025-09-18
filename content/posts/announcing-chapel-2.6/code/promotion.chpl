enum myColors { red = 1, green, blue, yellow = green : int + 10, cyan, magenta }

proc myColors.someMethod() do return (this : string, this : int);

var A: [1..10] myColors;
var B = A.someMethod();
var C = A : int;
