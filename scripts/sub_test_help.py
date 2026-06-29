#!/usr/bin/env python3

import os
import sys
import subprocess
import re
import io
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

# run 'sub_test' on a single file, with CHPL_ONETEST scoped to this file's own
# subprocess environment (rather than mutating os.environ) so it is safe to call
# from multiple threads. All output is captured and returned alongside the exit
# code so the caller can emit it without interleaving concurrent runs.
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

# determine how many worker threads to use for parallel sub_test runs.
# returns 1 (serial) unless CHPL_PARALLEL_SUB_TEST is set: a positive integer
# value selects that many workers, any other set value falls back to cpu count.
def parallel_workers():
    workers_env = os.environ.get("CHPL_PARALLEL_SUB_TEST")
    if not workers_env:
        return 1
    if workers_env.isdigit() and int(workers_env) > 0:
        return int(workers_env)
    return os.cpu_count() or 1

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

        num_workers = min(parallel_workers(), len(valid_files))

        # opt-in parallel execution via CHPL_PARALLEL_SUB_TEST; capture each
        # file's output and write it out in order so logs are not interleaved
        if num_workers > 1:
            with concurrent.futures.ThreadPoolExecutor(max_workers=num_workers) as executor:
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
        else:
            for src_file in valid_files:
                # set the src_file as the single test file for 'sub_test' to run
                os.environ["CHPL_ONETEST"] = os.path.basename(src_file)

                # start $CHPL_HOME's 'sub_test' script on the selected file
                #  the 'compiler' argument is passed on             \/
                err = max(err, run_and_log([chpl_home_subtest, sys.argv[1]]))

        exit(err)
