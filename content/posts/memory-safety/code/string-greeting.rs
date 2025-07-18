use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();
    let mut greeting = String::from("Hello ");
    greeting += &args[1];
    println!("{}", greeting);
}
