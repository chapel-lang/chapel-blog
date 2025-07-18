proc square(x: real(64)): real(64) {
  return x*x;
}

const pi: real(64) = 3.1415,
      pi2: real(64) = square(pi);

writeln((pi,pi2));
