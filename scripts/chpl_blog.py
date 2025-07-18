#!/usr/bin/env python3
import glob
import os
import pathlib
import sys
import tempfile
import re
import argparse
import watchdog.events
import watchdog.observers
import subprocess
import shutil
from pathlib import Path
from common import compute_options

input_dir = 'chpl-src'
output_dir = "content-gen/posts"
convert_script = os.path.dirname(__file__) + "/chpl2md.py"

print("Deleting generated content folder {}".format(output_dir))
shutil.rmtree(output_dir, ignore_errors=True)

def create_output_dir_for(file):
    base_name = os.path.basename(file).removesuffix(".chpl")
    file_output_dir = output_dir + "/" + base_name
    # Create a path for the files. If we create the path for the code, the
    # folder above it will be created too.
    pathlib.Path(file_output_dir + "/code").mkdir(parents=True, exist_ok=True)
    return file_output_dir

def generate_markdown(file, file_output_dir):
    base_name = os.path.basename(file).removesuffix(".chpl")
    command = "{} {} --code-path=code/{}.chpl > {}/index.md".format(convert_script, file, base_name, file_output_dir)
    os.system(command)
    command = "{} --code {} > {}/code/{}.chpl".format(convert_script, file, file_output_dir, base_name)
    os.system(command)

def generate_chunks_for_option(file, file_output_dir, tmpdir, option):
    print("Processing option", option)
    (suffix, compopt, execopt) = option
    if suffix != '': suffix = '.' + suffix

    needs_output = False
    with open(file) as f:
        if "__BREAK__" in f.read():
            needs_output = True

    if not needs_output: return

    base_name = os.path.basename(file).removesuffix(".chpl")
    good_file = os.path.dirname(file) + "/" + base_name + suffix + ".good"
    sample_file = good_file + ".sample"

    # If a .good or .good.sample file exists, no need to compile and run the
    # program.
    if os.path.exists(sample_file):
        with open(sample_file) as file:
            text = file.read()
    elif os.path.exists(good_file):
        with open(good_file) as file:
            text = file.read()
    else:
        os.system("chpl {} {} -o {}/prog".format(compopt, file, tmpdir))
        os.system("{}/prog {} > {}/prog.out".format(tmpdir, execopt, tmpdir))
        with open("{}/prog.out".format(tmpdir)) as file:
            text = file.read()

    chunks = re.split('^__BREAK__$', text, flags=re.MULTILINE)
    for (i, chunk) in enumerate(chunks):
        chunk_path = file_output_dir + "/output{}.{}".format(suffix, i)
        if i > 0: chunk = chunk[1:] # remove leading newline
        with open(chunk_path, "w") as chunkfile:
            chunkfile.write(chunk)

def generate_chunks(file, file_output_dir):
    with tempfile.TemporaryDirectory() as tmpdir:
        for option in compute_options(file):
            generate_chunks_for_option(file, file_output_dir, tmpdir, option)

def process_file(file):
    print("Options:", compute_options(file))
    print("Creating directory for", file)
    file_output_dir = create_output_dir_for(file)
    # we only generate external markdown for the link command, so no need for chunks
    if not args.fast and args.command != 'link':
        print("Generating chunks for", file)
        generate_chunks(file, file_output_dir)
    print("Generating Markdown for", file)
    generate_markdown(file, file_output_dir)

class ChapelFileHandler(watchdog.events.FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory: return
        file = event.src_path
        if not file.endswith(".chpl"): return

        print("File created:", file)
        process_file(file)

    def on_modified(self, event):
        if event.is_directory: return
        file = event.src_path
        if not file.endswith(".chpl"): return

        print("File modified:", file)
        process_file(file)

def process_args():
    parser = argparse.ArgumentParser(
            prog='generate_md',
            description='Run Hugo server for literate chapel')

    def add_common_args(parser):
        parser.add_argument('-D', '--buildDrafts', action='store_true',
                            help='Include draft pages in output (forwarded to Hugo)')
        parser.add_argument('-f', '--fast', action='store_true',
                            help='Enable fast render mode, avoiding recompiling the program')
        parser.add_argument('-F', '--buildFuture', action='store_true',
                            help='Include content with publishdate in the future (forwarded to Hugo)')

    subparsers = parser.add_subparsers(dest='command')
    serve_parser = subparsers.add_parser('serve')
    build_parser = subparsers.add_parser('build')
    link_parser = subparsers.add_parser('link')

    build_parser.add_argument('-c', '--copy', action='store_true',
                              help='Copy generated files into CHPL_WWW/blog')

    link_parser.add_argument('-a', '--article', help='The article for which to generate an external markdown file')

    add_common_args(parser)
    add_common_args(serve_parser)
    add_common_args(build_parser)

    return parser.parse_args()

def get_hugo_options(args):
    hugo_args = []
    # link doesn't have common flags since it uses a custom config.
    configs = ['config.toml']
    if args.command != 'link':
        if args.buildDrafts: hugo_args.append('-D')
        if args.buildFuture: hugo_args.append('-F')
        if args.fast:
            # Also use fast config, which skips rendering chunks (which we may
            # not be generating)
            configs.append('config-fast.toml')
        else:
            # Use default config, no need to specify anything.
            pass
    else:
        # Configure the .md-only output for linking
        configs.append('config-hpe-dev.toml')
        configs.append('config-fast.toml')
    if args.command == 'serve':
        configs.append('config-server.toml')
    hugo_args.append(f"--config={','.join(configs)}")
    return hugo_args

def generate_html(options):
    hugo_args = ['hugo'] + options
    print("Building output using Hugo command:", *hugo_args)
    return subprocess.Popen(hugo_args)

def start_hugo(options):
    hugo_args = ['hugo', 'server'] + options
    print("Running Hugo server with command:", *hugo_args)
    return subprocess.Popen(hugo_args)

def run_watcher():
    event_handler = ChapelFileHandler()
    observer = watchdog.observers.Observer()
    observer.schedule(event_handler, input_dir, recursive=True)
    print("Starting filesystem watcher on dir:", input_dir)
    observer.start()
    try:
        while observer.is_alive():
            observer.join(1)
    finally:
        observer.stop()
        observer.join()

args = process_args()
options = get_hugo_options(args)

print("Creating initial Markdown and chunks for all files")
for file in glob.glob(input_dir + "/*.chpl"):
    process_file(file)

if args.command == 'build':
    print("Deleting Hugo output folder before re-generating")
    shutil.rmtree('public', ignore_errors=True)

    generate_html(options).wait()

    if args.copy:
        www_dir = os.getenv('CHPL_WWW')
        if www_dir is None:
            raise Exception("CHPL_WWW not set; nowhere to copy files")
        dest_dir = www_dir + '/chapel-lang.org/blog'
        Path(dest_dir).mkdir(parents=True, exist_ok=True)
        shutil.copytree('public', dest_dir, dirs_exist_ok=True)
elif args.command == 'link':
    generate_html(options).wait()

    shutil.copy(os.path.join('public', 'posts', args.article, 'index.md'), args.article + '.md')
    print(args.article + '.md')

else:
    start_hugo(options)
    run_watcher()
