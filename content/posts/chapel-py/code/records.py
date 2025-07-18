import re
import sys
from chapel import *

def is_camel_case(name: str):
    return re.fullmatch(r"([a-z]+([A-Z][a-z]*|\d+)*|[A-Z]+)?", name)

context = Context()
modules = context.parse(sys.argv[1])

for module in modules:
    for record, _ in each_matching(module, Record):
        if not is_camel_case(record.name()):
            print("Record name is not in camel case:", record.name())
