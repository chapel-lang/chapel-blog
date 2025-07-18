import sys
from chapel import *

context = Context()
modules = context.parse(sys.argv[1])

for module in modules:
    for op, _ in each_matching(module, OpCall):
        print("Found an operation:", op.op())

    for lit, _ in each_matching(module, IntLiteral):
        print("Found a literal:", lit.text())
