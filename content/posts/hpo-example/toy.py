"""
Usage:
	python toy.py --x=<value>

Example:
	python toy.py --x=25

This will calculate the summation from 1 to 25 and print the result.
"""
import sys

def main():
	# Extract the value after '=' and convert to integer
	arg = sys.argv[1]
	x = int(arg.split('=')[1])

	# Calculate the summation from 1 to x
	summation = sum(range(1, x + 1))

	# Print only the value of summation to standard out
	print(summation)

if __name__ == "__main__":
	main()
