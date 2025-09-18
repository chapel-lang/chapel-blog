enum myColors { red = 1, green, blue, yellow = green : int + 10, cyan, magenta }

type myColorAlias = myColors;

// param string -> param enum
param color1 = "green" : myColors;

// access enum value via alias
param color2 = myColorAlias.blue;

// compute value for 'cyan', which follows 'yellow', which depends on 'green'
param index1 = myColors.cyan : int;

// iterate over 'enum' range at compile time
// first, take the first 5 with '..#5':
//
//     red, green, blue, yellow, cyan, magenta
//     ~~~  ~~~~~  ~~~~  ~~~~~~  ~~~~
//
// Then, starting at the end, step backwards by 2:
//
//     red, green, blue, yellow, cyan, magenta
//     3           2             1
//
for param c in myColors.red..#5 by -2 {
  compilerWarning(c : string);
}
