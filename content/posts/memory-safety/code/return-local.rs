fn foo() -> &'static mut i32 {
    let mut x: i32 = 1;

    let y: &mut i32 = &mut x;

    return y;
}
fn main() {
    foo();
}
