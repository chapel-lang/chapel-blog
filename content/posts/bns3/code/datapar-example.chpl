use BlockDist;

const dom = blockDist.createDomain({1..8, 1..8}, targetLocales=Locales);
var A: [dom] int = 1;

forall a in A do
  a = a.locale.id;

writeln(A);
