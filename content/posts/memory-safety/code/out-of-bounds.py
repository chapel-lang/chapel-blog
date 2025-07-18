import sys

def main(args):
    idx = int(args[1])
    array = [0]
    x = array[idx]
    print("array at index", idx, " is ", x) 

if __name__ == "__main__":
    main(sys.argv)
