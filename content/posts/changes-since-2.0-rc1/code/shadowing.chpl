module M {
  module N {
    proc foo() {
      writeln("In M.N.foo");
    }
  }
}

module N {
  proc foo() {
    writeln("In N.foo");
  }
}

module Main {
  proc main() {
    use M;
    use N;  // This ends up using M.N instead of the top level N
    foo();  // and as a result this calls M.N.foo, which may be surprising
  }
}
