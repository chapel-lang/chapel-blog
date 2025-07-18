import sys
from chapel import *

context = Context()
context.set_module_paths([], [])
modules = context.parse(sys.argv[1])

def parent_module(node):
    while not isinstance(node, Module):
        node = node.parent_symbol()
    return node

ROOT_URL = "https://chapel-lang.org/docs/modules/standard/"

def build_url(module):
    modules = []
    while module:
        modules.append(module.name())
        module = module.parent_symbol()
    return "/".join(reversed(modules)) + ".html"

def build_anchor(node):
    if isinstance(node, Module):
        return ""

    names = []
    while node:
        names.append(node.name())

        # Anchors don't contain outer modules
        if isinstance(node, Module):
            break

        node = node.parent_symbol()
    return "#" + ".".join(reversed(names))

def find_doc_link(node):
    module = parent_module(node)
    full_url = ROOT_URL + build_url(module) + build_anchor(node)
    return full_url

for module in modules:
    for ident, _ in each_matching(module, set([Identifier, Dot])):
        to_node = ident.to_node()
        if not to_node:
            continue

        line_no, _ = ident.location().start()
        full_url = find_doc_link(to_node)
        print("On line {}, URL: {}".format(line_no, full_url))

