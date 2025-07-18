fn main() {
    let mut x: i64; // OOPS! forgot to initialize x
    let y = x;
    println!("y is {}", y);
}
