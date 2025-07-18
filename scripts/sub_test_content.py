#!/usr/bin/env python3

import os
import sys
from sub_test_help import version_matches, run_valid_tests

def valid_idx_version(file, version):
    return os.path.isfile("../index.md") is not None and version_matches("../index.md", version)

run_valid_tests(valid_idx_version, sys.argv[1])
