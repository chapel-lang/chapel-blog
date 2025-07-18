use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();
    let mut greeting = String::from("hi ");
    greeting += &args[1];
    println!("{}", greeting);

    let c = greeting.as_bytes()[args.len()];
    println!("{}", c);
}
