import sys

def main(args):
    greeting = "Hello "
    greeting += args[1]
    print(greeting)

if __name__ == "__main__":
    main(sys.argv)
