#!/usr/bin/env python3
# encoding: utf-8

"""chpl2md converts a chapel program to an md file, where all comments are
rendered md, and all code is wrapped in code blocks.

Chapel files are converted as follows:

* Line comments starting at the beginning of the line are converted to text
* Block comments starting anywhere are converted to text
* All other lines are wrapped as code-blocks

example.chpl
============

/* This is
     an example */
proc foo() {
    // this comment will be in the code block
    var bar = 1; }
// this comment will be text

example.md
===========

This is
  an example

```chapel
proc foo() {
    // this comment will be in the code block
    var bar = 1; }
```

this comment will be text"""

import os
import re
import sys
import argparse
import itertools
from common import compute_options

# Get access to the "Literate Chapel" script distributed with Chapel. To do
# so, we need to add the CHPL_HOME to our Python search path.
chplHome = os.environ["CHPL_HOME"]
sys.path.append(os.path.join(chplHome, "doc", "util"));

from literate_chapel import to_pieces, title_comment

def get_arguments():
    """
    Get arguments from command line
    """
    parser = argparse.ArgumentParser(
        prog='chpl2md',
        usage='%(prog)s  file.chpl [options] ',
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('chapelfiles', nargs='+',
                        help='Chapel files to convert to md')
    parser.add_argument('--code', help='Extract code from the file, instead',
                        action='store_true')
    parser.add_argument('--code-path', help='Where the code file should expect code to be, relative to its directory')
    return parser.parse_args()


def print_good(output, good_options, chunk_index):
    """Print the output from .good files"""

    output.append('')
    output.append('{{< console_output >}}')
    if len(good_options) == 1:
        # Just one good option means no need to generate menu
        output.append('{{{{< console_single suffix="" chunk="{}">}}}}'
                        .format(chunk_index))
    else:
        output.append('{{{{< console_multi chunk="{}" >}}}}'.format(chunk_index))
        for (suffix, compopt, execopt) in good_options:
            text = compopt + ' ' + execopt

            # Note: something about inserting indentation here breaks highlighting,
            # causing newlines to get printed. So these are unindentented.
            output.append('{{{{< console_option suffix=".{}" label="{}" >}}}}'.format(suffix, text))
            output.append('{{< console_single dummy="" >}}')
            output.append('{{< /console_option >}}')
        output.append('{{< /console_multi >}}')
    output.append('{{< /console_output >}}')

def extract_line_anchor(line_str):
    match = re.search(r'//\s*hugo-tag="(.+)"', line_str)
    if match is not None:
        tag = match.group(1)
        return (match.string[:match.start(0)]+
                match.string[match.end(0):], tag)
    else:
        return None

def extract_line_anchors(lines, line_no):
    anchors = []
    new_lines = []
    for (i, line_str) in enumerate(lines):
        result = extract_line_anchor(line_str)
        if result is not None:
            trimmed_line, tag = result
            anchors.append((tag, line_no + i))
            new_lines.append(trimmed_line)
        else:
            new_lines.append(line_str)
    return (new_lines, anchors)

def gen_md(pieces, chapelfile, **kwargs):
    output = []
    good_options = compute_options(chapelfile)
    front_matter = []

    first_code_idx = -1
    last_code_idx = -1
    line_number = 1
    code_indices = []
    for (i, (kind, content)) in enumerate(pieces):
        if kind != 'code':
            continue
        code_indices.append(i)
        new_content, anchors = extract_line_anchors(content, line_number)

        # Modify content in place with procesed lines (which strip anchor markers)
        content[:] = new_content

        # Push anchor markers before any content is in output to ensure they're
        # always in scope. This way, you can refer to lines that are shown later
        # as early as the first sentence of the prose.
        for (tag, line) in anchors:
            output.append(f'{{{{< mark_line_anchor tag="{tag}" line={line} >}}}}')

        line_number += len(content) + 1;

    # Each line is md or code-block
    line_number = 1
    for i, (kind, content) in enumerate(pieces):
        if kind == 'title':
            front_matter.append('title: "{0}"'.format(content[0]))
        elif kind == 'frontmatter':
            front_matter.extend(content)
        elif kind == 'prose':
            output.extend(content)
        elif kind == 'code':
            code_section = 'middle'
            if i == first_code_idx and i == last_code_idx: code_section = 'only'
            elif i == first_code_idx: code_section = 'first'
            elif i == last_code_idx: code_section = 'last'

            attrs = f'data-code-type=main,data-code-section={code_section},linenos=true,linenostart={line_number}'
            if kwargs['code_path'] is not None:
                attrs += f',data-code-path="{kwargs["code_path"]}",data-start-line={line_number}'
            output.append('```Chapel {{{}}}'.format(attrs))
            output.extend(content)
            output.append('```')

            line_number += len(content) + 1;
        elif kind == 'output':
            print_good(output, good_options, content)
        output.append('')
    return '---\n{}\n---\n{}'.format('\n'.join(front_matter), '\n'.join(output))

def gen_code(pieces, chapelfile, **kwargs):
    output = []

    # Each line is md or code-block
    for (kind, content) in pieces:
        if kind == 'title':
            pass
        elif kind == 'frontmatter':
            pass
        elif kind == 'prose':
            pass
        elif kind == 'code':
            content, _ = extract_line_anchors(content, 0)
            output.append(content)
        elif kind == 'output':
            pass
    return '\n'.join(''.join(line+'\n' for line in code) for code in output)

def goodfiles(chapelfile):
    """Yield (file_name, options_string) for .good files corresponding to
    each combination of compile and execution options."""

    filedir, filename = os.path.split(chapelfile)
    basename, _ = os.path.splitext(filename)
    compoptsFile = os.path.join(filedir, ''.join([basename, '.compopts']))
    execoptsFile = os.path.join(filedir, ''.join([basename, '.execopts']))

    iters = []
    compoptsList = variant_list(compoptsFile)
    if compoptsList is not None: iters.append(compoptsList)
    execoptsList = variant_list(execoptsFile)
    if execoptsList is not None: iters.append(execoptsList)

    for (name, opts) in get_combinations(iters):
        yield (basename, name, ' '.join(opts))

def write(mdoutput, output):
    """Write to output"""
    sys.stdout.write(mdoutput)

def main_args(**kwargs):
    """Driver function - convert each file to md and write to output"""
    for chapelfile in kwargs['chapelfiles']:
        with open(chapelfile, 'r', encoding='utf-8') as handle:
            pieces = to_pieces(handle, False)
            mdoutput = (gen_code if kwargs['code'] else gen_md)(pieces, chapelfile, **kwargs)

        sys.stdout.write(mdoutput)

def main():
    # Parse arguments and cast them into a dictionary
    arguments = vars(get_arguments())
    main_args(**arguments)

if __name__ == '__main__':
    main()
