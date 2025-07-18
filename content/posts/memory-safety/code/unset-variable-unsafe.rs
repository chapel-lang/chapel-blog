// try compiling it with
//   rustc unset-variable-unsafe.rs
fn main() {
    unsafe {
        let mut x: i64; // OOPS! forgot to initialize x
        let y = x;      // compilation error: `x` used here but it isn't initialized
        println!("y is {}", y);
    }
}
