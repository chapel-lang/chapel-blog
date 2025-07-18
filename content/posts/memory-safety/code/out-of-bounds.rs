use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();
    let idx = args[1].parse::<usize>().expect("need a number");
    let array: [i32; 1] = [0; 1];
    let x = array[idx];
    println!("array at index {} is {}", idx, x);
}
