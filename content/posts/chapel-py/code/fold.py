from chapel import *
from chapel.replace import run

def simplify(opnode, lhs, rhs):
  op = opnode.op()
  lhs_val = int(lhs.text())
  rhs_val = int(rhs.text())

  if op == "+":
    return lhs_val + rhs_val
  elif op == "-":
    return lhs_val - rhs_val
  elif op == "*":
    return lhs_val * rhs_val
  elif op == "/":
    return lhs_val // rhs_val
  else:
    return None

def simple_constant_fold(rc, module):
    pattern = [OpCall, ("?lhs", IntLiteral), ("?rhs", IntLiteral)]
    for op, vars in each_matching(module, pattern):
        result = simplify(op, vars["lhs"], vars["rhs"])
        if result is not None:
            yield (op, str(result))

run(simple_constant_fold)
