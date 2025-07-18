# Modified from the following StackOverflow answer:
#
# https://stackoverflow.com/a/59109706

# prefix components:
space =  '    '
branch = '│   '
# pointers:
tee =    '├── '
last =   '└── '


def tree(node, prefix: str=''):
    """A recursive generator, given a an AST node,
    will yield a visual tree structure line by line
    with each line prefixed by the same characters
    """
    contents = list(node.__subclasses__())
    # contents each get pointers that are ├── with a final └── :
    pointers = [tee] * (len(contents) - 1) + [last]
    for pointer, child in zip(pointers, contents):
        yield prefix + pointer + child.__name__
        if len(child.__subclasses__()) > 0: # extend the prefix and recurse:
            extension = branch if pointer == tee else space
            # i.e. space because last, └── , above so no more |
            yield from tree(child, prefix=prefix+extension)

from chapel import *
print(AstNode.__name__)
for line in tree(AstNode):
    print(line)

