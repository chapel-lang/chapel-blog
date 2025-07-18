#!/usr/bin/env python3

import sys
from sub_test_help import version_matches, run_valid_tests
# as with sub_test, accept the chpl compiler to use (with path) as an argument
if len(sys.argv) == 2:
  run_valid_tests(version_matches, sys.argv[1])
else:
  raise TypeError("sub_test_chpl_src.py requires one argument, the path to `chpl`")
