#!/usr/bin/env python3
import pathlib
import argparse
import bs4
import os
import collections
import functools
import bisect
import json
import re

CACHE_DEST = "file-link-cache.json"

class ReferenceContainer:
    def applicable_links(self, start_line, end_line):
        # find the first reference that starts after the start_line
        start_key = [[start_line, 0], [-1, -1]]
        start_index = bisect.bisect_right(self.references, start_key, key=lambda x: x[0])
        # find the last reference that ends before the end_line
        end_key = [[end_line, float("inf")], [-1, -1]]
        end_index = bisect.bisect_left(self.references, end_key, key=lambda x: x[0])

        # return the references in the range [start_index, end_index)
        return self.references[start_index:end_index]

class CachedFile(ReferenceContainer):
    def __init__(self, filepath, references):
        self.filepath = filepath
        self.references = references

# The following code only works if chapel-py is installed. However, if we're
# just using the cache, we don't need chapel-py at all.
try:
    from chapel import each_matching
    from chapel.core import Context, Identifier, Dot, FnCall, Function, Module, NamedDecl, AggregateDecl


    ### Copied / adjusted from https://chapel-lang.org/blog/posts/chapel-py/

    ROOT_URL = "https://chapel-lang.org/docs/"

    def rewrite_module_name(name):
        if name == "ChapelIO": return "IO"
        if name == "AutoMath": return "Math"
        if name == "ChapelSysCTypes": return "CTypes"
        return name

    def parent_module(node):
        while not isinstance(node, Module):
            node = node.parent_symbol()
        return node

    def build_url(module):
        modules = []
        while module:
            modules.append(rewrite_module_name(module.name()))
            module = module.parent_symbol()
        return "/".join(reversed(modules)) + ".html"

    def build_anchor(node):
        if isinstance(node, Module):
            return ""

        names = []
        names.append(node.name())
        # for secondary and tertiary methods, need to insert their receiver type
        if isinstance(node, Function) and node.is_method() and not isinstance(node.parent_symbol(), AggregateDecl):
            this_formal = node.this_formal()
            if this_formal:
                names.append(str(this_formal.type_expression()))

        node = node.parent_symbol()
        while node:
            names.append(rewrite_module_name(node.name()))

            # Anchors don't contain outer modules
            if isinstance(node, Module):
                break

            node = node.parent_symbol()
        return "#" + ".".join(reversed(names))

    def find_doc_link(node):
        file = pathlib.Path(node.location().path())
        root = file
        internal = False
        gen = None
        while root.name != "modules":
            if root.name == "internal":
                internal = True

            if root.name == "gen":
                gen = root

            root = root.parent
            if root is None or root == root.parent:
                return None

        if gen:
            relpath = str(gen.parent.relative_to(root.parent)) + "/"
        else:
            relpath = str(file.parent.relative_to(root.parent)) + "/"


        module = parent_module(node)
        if module.name() == "String" and internal:
            url = ROOT_URL + "language/spec/strings.html" + build_anchor(node)
            return url.replace("_string", "string")
        if module.name() == "ChapelRange" and internal:
            url = ROOT_URL + "language/spec/ranges.html" + build_anchor(node)
            return url.replace("_range", "range")
        if module.name() == "ChapelArray" and internal:
            url = ROOT_URL + "language/spec/arrays.html" + build_anchor(node)
            return url.replace("_array", "array").replace("array.", "")
        elif internal:
            return None

        return ROOT_URL + relpath + build_url(module) + build_anchor(node)

    ### End copied from chapel-py

    def _extract_location(node):
        if isinstance(node, Dot):
            return node.field_location()
        elif isinstance(node, FnCall):
            return _extract_location(node.called_expression())
        return node.location()

    def _resolve_call(call, via=None):
        rr = call.resolve_via(via) if via else call.resolve()
        if not rr:
            return None

        candidate = rr.most_specific_candidate()
        if not candidate:
            return None

        sig = candidate.function()
        fn = sig.ast()
        if not fn or not isinstance(fn, Function):
            return None

        return (sig, fn)

    #https://stackoverflow.com/questions/2912231/is-there-a-clever-way-to-pass-the-key-to-defaultdicts-default-factory

    class Instantiation:
        def __init__(self, parent_file, sig, fn):
            self.references = []
            self.parent_file = parent_file

            for (call, _) in each_matching(fn, set([FnCall, Dot])):
                res = _resolve_call(call, sig)
                if res is None: continue
                other_sig, other_fn = res
                self.references.append((_extract_location(call), other_fn))
                parent_file.get_inst(other_sig, other_fn)

    class ParsedFile(ReferenceContainer):
        def _collect_decls(self):
            for module in self.modules:
                for (decl, _) in each_matching(module, NamedDecl):
                    self.declarations[decl.unique_id()] = decl

        def _process_scope_resolve(self, module):
            for (identifier_or_dot, _) in each_matching(module, set([Identifier, Dot])):
                refers_to = identifier_or_dot.to_node()
                if refers_to is not None:
                    self.references.append((_extract_location(identifier_or_dot), refers_to))

        def _process_resolve(self, module):
            for (call, _) in each_matching(module, set([FnCall, Dot])):
                res = _resolve_call(call)
                if res is None: continue
                sig, fn = res

                # callable var invocations are confusing when they link to the 'this' method,
                # skip them.
                if fn.name() == "this": continue

                self.references.append((_extract_location(call), fn))
                self.get_inst(sig, fn)

        def _process(self):
            for module in self.modules:
                self._process_scope_resolve(module)

            # skip some problematic modules
            if "aoc2022-day02-rochambeau.chpl" in str(self.filepath):
                return

            for module in self.modules:
                self._process_resolve(module)

        def get_inst(self, sig, fn):
            if fn.unique_id() not in self.instantiations:
                self.instantiations[fn.unique_id()] = {}

            insts_for_sig = self.instantiations[fn.unique_id()]
            if sig not in insts_for_sig:
                # First, create the entry so that recursion doesn't break things
                insts_for_sig[sig] = None
                insts_for_sig[sig] = Instantiation(self, sig, fn)

            return insts_for_sig[sig]

        def __init__(self, filepath):
            ctx = Context()
            ctx.set_module_paths([], [])

            self.filepath = filepath
            self.references = []
            self.declarations = {}
            self.instantiations = {}
            self.modules = ctx.parse(str(filepath))

            self._collect_decls()
            self._process()

            # for each function in this file that has a single instantiation,
            # copy its references too.
            for decl in self.declarations.values():
                if decl.unique_id() in self.instantiations:
                    insts = self.instantiations[decl.unique_id()]
                    if len(insts) == 1:
                        # this is a function with only one instantiation
                        # copy its references to the current file
                        for inst in insts.values():
                            self.references.extend(inst.references)

            # Convert references to lists (which JSON can encode) and rule
            # out things without links.
            converted_references = []
            for (location, node) in self.references:
                found_link = find_doc_link(node)
                if found_link is None:
                    continue
                start = [num for num in location.start()]
                end = [num for num in location.end()]
                converted_references.append([[start, end], found_link])
            self.references = converted_references
            self.references.sort(key=lambda x: x[0])
except ImportError:
    def ParsedFile(filepath):
        raise ImportError("The Python bindings for the compiler front-end are needed to parse and analyze Chapel files.")


def main():
    parser = argparse.ArgumentParser(description="Insert links into HTML files that contain Chapel blocks.")
    parser.add_argument('files', help='HTML files to post-process', nargs='+')
    parser.add_argument('--regenerate-links', help='Re-run resolution in affected files to determine linked locations', action='store_true', default=False)
    args = parser.parse_args()

    @functools.cache
    def resolution_cache():
        if os.path.exists(CACHE_DEST):
            with open(CACHE_DEST, 'r', encoding='utf-8') as f:
                content = json.load(f)
                return content
        return None

    # Can't use functools cache here since we want to inspect the keys later
    chpl_file_cache = dict()
    def parse(filename):
        nonlocal args, chpl_file_cache
        filename_str = str(filename)

        if filename_str in chpl_file_cache:
            return chpl_file_cache[filename_str]

        if not args.regenerate_links:
            cached = resolution_cache()
            if cached and filename_str in cached:
                res = CachedFile(filename, cached[filename_str]['references'])
                chpl_file_cache[filename_str] = res
                return res
            return None

        res = ParsedFile(filename)
        chpl_file_cache[filename_str] = res
        return res

    current_dir = pathlib.Path(os.getcwd())
    for html_file in args.files:
        html = pathlib.Path(os.path.realpath(html_file))
        html_folder = html.parent
        soup = bs4.BeautifulSoup(html.read_text(), 'html.parser')

        # Collect all Chapel files, if any, used in this HTML file.
        # Do not fetch key outside the loop so that if no Chapel files are found,
        # the file is not in the dictionary.
        for block in soup.find_all('div', attrs={'data-code-path': True}):
            start_line = int(block['data-start-line'])
            code_path = str(block['data-code-path'])
            if not code_path.endswith(".chpl"):
                continue
            parsed = parse((html_folder / code_path).relative_to(current_dir))
            if not parsed: continue

            for idx, line in enumerate(block.find_all('span', attrs={'class': 'line'})):
                cur_line = start_line + idx
                cur_col = 1
                links = parsed.applicable_links(cur_line, cur_line)
                link_idx = 0

                def check_position(text):
                    nonlocal link_idx, cur_col
                    # Advance past links that are before the current column
                    while link_idx < len(links) and links[link_idx][0][1][1] < cur_col:
                        link_idx += 1

                    if link_idx >= len(links):
                        return False

                    cur_link = links[link_idx]
                    if cur_col >= cur_link[0][0][1] and cur_col + len(text) <= cur_link[0][1][1]:
                        return True

                    return False

                def traverse(node):
                    # if the whole node fits into a link, paint it directly,
                    # and do not recurse
                    nonlocal link_idx, cur_col
                    text = node.text
                    if check_position(text):
                        doc_link = links[link_idx][1]

                        if doc_link:
                            node = node.wrap(soup.new_tag('a', href=doc_link))

                        cur_col += len(text)
                        return

                    # This string wasn't painted by anything, so just
                    # advance the cursor and move on.
                    if isinstance(node, bs4.element.NavigableString):
                        cur_col += len(text)
                        return

                    # the whole node didn't fit, but one of its children might
                    for child in node.children:
                        traverse(child)


                # walk each line, insert links where possible
                traverse(line)

        # save the modified HTML file
        with open(html, 'w', encoding='utf-8') as f:
            f.write(str(soup))

    # Update entries in the cache if we are updating it
    if args.regenerate_links:
        cache = resolution_cache() or {}
        if not isinstance(cache, dict):
            cache = {}

        for (path, result) in chpl_file_cache.items():
            cache[str(path)] = { 'references': result.references }

        # https://stackoverflow.com/a/72611442
        towrite = json.dumps(cache, indent=2, ensure_ascii=False)
        pat = re.compile(f'\n(  ){{3}}((  )+|(?=(}}|])))')
        towrite = pat.sub('', towrite)

        with open(CACHE_DEST, 'w', encoding='utf-8') as f:
            f.write(towrite)

if __name__ == "__main__":
    main()
