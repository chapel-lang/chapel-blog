#!/usr/bin/env python3

import os
import sys
import subprocess
import re
import concurrent.futures
from packaging import version

# get the current Chapel version at $CHPL_HOME
def get_current_chpl_version(compiler):
    if "CHPL_HOME" not in os.environ:
        print("Please set 'CHPL_HOME' and try again")
        exit(1)
    version_stdout = subprocess.run([compiler, "--version"], capture_output=True, text=True)
    return version.parse(re.search(r"chpl version (\d+\.\d+\.\d+)", version_stdout.stdout).group(1))

# return a list of paths to all the '.chpl' files in a directory
def chpl_files_in_dir(dir):
    files = []
    for dirpath, dirnames, filenames in os.walk(dir):
        for fname in filenames:
            if fname.endswith(".chpl"):
                files.append(os.path.join(dirpath, fname))
    return files

# determine if a file has a 'chplVersion: X.X.X' line matching 'chpl_version'
def version_matches(file_path, chpl_version):
    with open(file_path) as f:
        if (version_line_match := re.search(r"chplVersion: (\d+\.\d+\.?\d*)", f.read())) is not None:
            # does the version match?
            return chpl_version == version.parse(version_line_match.group(1))
        else:
            # there is no version specified, so the file should be tested
            return True

# spawn a subprocess for the given job
# wait until it finishes before returning
def run_and_log(cmd):
    p = subprocess.Popen(cmd)
    p.wait()
    return p.returncode

def run_sub_test_on_file(chpl_home_subtest, compiler, src_file):
    env = os.environ.copy()
    env["CHPL_ONETEST"] = os.path.basename(src_file)
    p = subprocess.run(
        [chpl_home_subtest, compiler],
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    return p.returncode, p.stdout

def parallel_workers():
    workers_env = os.environ.get("CHPL_PARALLEL_SUB_TEST", "1")
    try:
        workers = int(workers_env)
        if workers < 1:
            raise ValueError
        return workers
    except ValueError:
        print(
            f"Invalid value for CHPL_PARALLEL_SUB_TEST: '{workers_env}'. Must be a positive integer."
        )
        exit(1)

def run_valid_tests(version_validator, compiler):
    chpl_version = get_current_chpl_version(compiler)
    chpl_home_subtest = os.path.join(os.environ["CHPL_HOME"], "util", "test", "sub_test")

    # 'start_test' specified an individual file, don't check for a version constraint
    if "CHPL_ONETEST" in os.environ:
        err = run_and_log([chpl_home_subtest, sys.argv[1]])
        exit(err)

    # normal mode: check the current directory for any files that meet the version constraint
    else:
        err = 0
        sys.stdout.write("[Filtering tests for chpl version: '{}']\n".format(chpl_version))
        sys.stdout.flush()

        # select the files that satisfy the version constraint
        valid_files = [
            src_file
            for src_file in chpl_files_in_dir(".")
            if version_validator(src_file, chpl_version)
        ]

        num_workers = parallel_workers()

        with concurrent.futures.ThreadPoolExecutor(max_workers=num_workers) as executor:
            # forward on 'compiler' argument from sys.argv
            results = executor.map(
                lambda src_file: run_sub_test_on_file(
                    chpl_home_subtest, sys.argv[1], src_file
                ),
                valid_files,
            )
            for returncode, output in results:
                sys.stdout.write(output)
                sys.stdout.flush()
                err = max(err, returncode)

        exit(err)
