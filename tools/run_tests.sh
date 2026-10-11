#!/usr/bin/env bash
# Run the headless GUT test suite. Extra args go to GUT, e.g.:
#   tools/run_tests.sh -gselect=test_map_layout      (one script)
#   tools/run_tests.sh -gunit_test_name=entrances    (matching tests)
#   FS_LOG_ECHO=1 tools/run_tests.sh                  (echo debug log to stdout)
set -euo pipefail
cd "$(dirname "$0")/.."
# Builds the global class cache on a fresh checkout; cheap when nothing changed.
godot --headless --import >/dev/null 2>&1 || true
exec godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json "$@"
