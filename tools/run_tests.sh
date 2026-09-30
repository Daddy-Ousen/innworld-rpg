#!/usr/bin/env bash
# Run GUT test scripts, one Godot call per script, and print a short summary.
# Works in Git Bash (Windows) and in a cloud session (Linux).
#
#   bash tools/run_tests.sh unit_rng unit_spells        # named scripts (exact names, no .gd)
#   bash tools/run_tests.sh 'unit_spell*'               # a glob over game/tests/
#   bash tools/run_tests.sh --all                       # every script (the full suite)
#   options: -t <secs> timeout per script (default 600), -o <dir> log dir
#
# One call per script because a single full run can crash Godot (seen in unit_winter) and
# because -gselect matches substrings (unit_combat hits five scripts): this passes "<name>.gd",
# which matches one file. (-gtest does not help: .gutconfig.json still adds all of res://tests.)
# Exit code: 0 when every script passed, 1 otherwise.
# Output: one line per script plus the bad lines of failed scripts. Full logs in the log dir.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMEOUT=600
LOGDIR="${TMPDIR:-/tmp}/innworld-tests"
names=()
all=0
while [ $# -gt 0 ]; do
  case "$1" in
    -t) TIMEOUT="$2"; shift 2 ;;
    -o) LOGDIR="$2"; shift 2 ;;
    --all) all=1; shift ;;
    *) names+=("$1"); shift ;;
  esac
done

GODOT_BIN="${GODOT:-godot}"
command -v "$GODOT_BIN" >/dev/null 2>&1 || { echo "godot not found (set GODOT or run tools/cloud/setup.sh --force)"; exit 2; }

scripts=()
if [ "$all" = 1 ]; then
  while IFS= read -r f; do scripts+=("$f"); done < <(cd "$ROOT/game/tests" && find . -name '*.gd' | sed 's|^\./||; s|\.gd$||' | sort)
else
  for n in "${names[@]}"; do
    n="${n%.gd}"
    matched=0
    while IFS= read -r f; do scripts+=("$f"); matched=1; done < <(cd "$ROOT/game/tests" && find . -path "./$n.gd" | sed 's|^\./||; s|\.gd$||' | sort)
    [ "$matched" = 1 ] || { echo "no test script: $n"; exit 2; }
  done
fi
[ "${#scripts[@]}" -gt 0 ] || { echo "usage: bash tools/run_tests.sh [-t secs] [-o dir] --all | <script>..."; exit 2; }

mkdir -p "$LOGDIR"
SUMMARY="$LOGDIR/summary.txt"
: > "$SUMMARY"
tot_s=0; tot_t=0; tot_p=0; bad=0
for s in "${scripts[@]}"; do
  log="$LOGDIR/$(echo "$s" | tr '/' '_').log"
  timeout "$TIMEOUT" "$GODOT_BIN" --headless --path "$ROOT/game" -s addons/gut/gut_cmdln.gd \
    -gdir=res://tests -ginclude_subdirs -gselect="$(basename "$s").gd" -gexit > "$log" 2>&1
  rc=$?
  clean="$(tr -d '\000' < "$log" | sed 's/\x1b\[[0-9;]*m//g')"
  tests=$(echo "$clean" | awk '/^Tests[ ]+[0-9]+/ {print $2; exit}')
  pass=$(echo "$clean" | awk '/^Passing Tests[ ]+[0-9]+/ {print $3; exit}')
  errs=$(echo "$clean" | grep -E "Parse Error|SCRIPT ERROR|Failed to load|\[Failed\]|Failing Tests|Risky|Invalid call|Crash|signal 11" | head -8)
  tot_s=$((tot_s + 1)); tot_t=$((tot_t + ${tests:-0})); tot_p=$((tot_p + ${pass:-0}))
  if echo "$clean" | grep -q "All tests passed" && ! echo "$clean" | grep -qE "Parse Error|SCRIPT ERROR"; then
    if [ "$rc" = 124 ]; then line="OK    $s  ${pass}/${tests}  (hung at exit, killed)"; else line="OK    $s  ${pass}/${tests}"; fi
  else
    bad=$((bad + 1))
    if [ "$rc" = 124 ]; then why="TIMEOUT after ${TIMEOUT}s"; else why="exit $rc"; fi
    line="FAIL  $s  ${pass:-0}/${tests:-?}  ($why)"
    [ -n "$errs" ] && line="$line"$'\n'"$(echo "$errs" | sed 's/^/      /')"
  fi
  echo "$line" | tee -a "$SUMMARY"
done
echo "TOTAL scripts=$tot_s tests=$tot_t passing=$tot_p failed_scripts=$bad  (logs: $LOGDIR)" | tee -a "$SUMMARY"
[ "$bad" = 0 ]
