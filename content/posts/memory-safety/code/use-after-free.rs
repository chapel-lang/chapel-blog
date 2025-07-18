fn main() {
    // Allocate an integer value on the heap
    let mut buf: Box<i32> = Box::new(1);

    // Create a reference to the value
    let ref_to_val: &mut i32 = &mut *buf;

    *ref_to_val = 10; // modify the value through the reference
                      
    {
        buf = Box::new(2); // replace the pointer

        drop(buf);         // explicitly drop 'buf' to avoid compiler error
    }
    
    println!("value: {}", ref_to_val);
}
