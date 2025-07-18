proc collatz(x: int(64)) {
    if x == 1 { return; }

    if x % 2 == 0 {
        collatz(x/2);
    } else {
        collatz(x*3+1);
    }
}
collatz(13);
collatz(1);
collatz(8);
