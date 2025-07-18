fn main() {
    // Allocate a an integer value on the heap
    let mut buf: Box<i32> = Box::new(1);

    // Create a pointer to the value
    let ptr: *mut i32 = &mut *buf as *mut i32;

    unsafe {
        *ptr = 10;         // modify the value through the pointer
                           //
        buf = Box::new(2); // free the pointer
        println!("value: {}", *ptr); // OOPS: use-after free, prints garbage

        drop(buf);         // explicitly drop 'buf' to avoid compiler error
    }
}
