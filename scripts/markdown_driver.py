#!/usr/bin/env python3
import sys
import re
import os
from collections import defaultdict

FILE_REGEX = r"^(\s*)```[a-zA-Z\-+_]+ {(.+)}$"
END_REGEX = r"^(\s*)```$"

file_name = sys.argv[1]
base_dir = os.path.dirname(os.path.realpath(file_name))

def error_and_exit(message):
    raise Error(message)

file_contents = defaultdict(lambda: [])
with open(file_name) as file:
    current_snippet = None
    current_file = None
    indent_string = None

    for line in file:
        file_match = re.match(FILE_REGEX, line)
        end_match = re.match(END_REGEX, line)

        if file_match is not None:
            if current_file is not None:
                error_and_exit("Starting a new file without finishing another!")

            # Pieces can be either `key=value` or (maybe) just `attribute`
            pieces = file_match[2].split(",")
            for piece in pieces:
                piece_assign = piece.split("=")
                if len(piece_assign) != 2:
                    # Weird syntax. Just look for other things.
                    continue
                (key, value) = piece_assign
                if key == "file_name":
                    current_file = value
                    current_snippet = []
                    indent_string = file_match[1]
            continue
        elif end_match is not None and current_file is not None:
            indent_end_string = end_match[1]
            if indent_string != indent_end_string:
                error_and_exit("Inconsistent indentation in code blocks!")

            file_contents[current_file].extend(current_snippet)

            current_snippet = None
            current_file = None
            indent_string = None
            continue
        elif current_file is not None:
            current_snippet.append(line.removeprefix(indent_string))

for file in file_contents:
    contents = file_contents[file]
    with open(base_dir + "/" + file, "w") as file_outout:
        file_outout.write("".join(contents))
