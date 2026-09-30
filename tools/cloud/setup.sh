#!/usr/bin/env bash
# Cloud session setup (Claude Code on the web). Runs from the SessionStart hook in
# .claude/settings.json. Does nothing on a local machine unless you pass --force.
#   1. Godot 4.7.2 on PATH (tools/cloud/install_godot.sh)
#   2. Python tool deps (tools/requirements.txt)
#   3. Book text: links book<N>/ from the PRIVATE repo Daddy-Ousen/innworld-canon-raw into canon/raw/
#   4. git identity for commits (Daddy-Ousen, no Claude trailer)
#   5. Godot import (makes game/.godot, the class_name cache; tests need it)
# Output is short on purpose: it lands in the session context. Full log: /tmp/innworld-setup.log
set -u

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ] && [ "${1:-}" != "--force" ]; then
  exit 0
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG=/tmp/innworld-setup.log
: > "$LOG"
say() { echo "[setup] $*"; echo "[setup] $*" >> "$LOG"; }

# 1. Godot
if bash "$ROOT/tools/cloud/install_godot.sh" >> "$LOG" 2>&1; then
  say "$(tail -1 "$LOG")"
else
  say "Godot install FAILED. Tests cannot run. See $LOG"
fi
export PATH="$HOME/.local/bin:$PATH"

# 2. Python deps (Pillow for the art tools)
if python3 -c "import PIL" 2>/dev/null; then
  say "python deps: ok"
elif python3 -m pip install -q -r "$ROOT/tools/requirements.txt" >> "$LOG" 2>&1 \
  || python3 -m pip install -q --break-system-packages -r "$ROOT/tools/requirements.txt" >> "$LOG" 2>&1; then
  say "python deps: installed"
else
  say "python deps: install FAILED (Pillow). See $LOG"
fi

# 3. Book text (copyrighted: canon/raw/ is gitignored; never commit it)
CANON=""
for d in "${INNWORLD_CANON_DIR:-}" "$ROOT/../innworld-canon-raw" "$HOME/innworld-canon-raw"; do
  if [ -n "$d" ] && [ -d "$d" ] && ls "$d"/book* >/dev/null 2>&1; then CANON="$d"; break; fi
done
if [ -z "$CANON" ]; then
  if GIT_TERMINAL_PROMPT=0 timeout 120 git clone -q --depth 1 https://github.com/Daddy-Ousen/innworld-canon-raw.git "$HOME/innworld-canon-raw" >> "$LOG" 2>&1; then
    CANON="$HOME/innworld-canon-raw"
  fi
fi
if [ -n "$CANON" ]; then
  mkdir -p "$ROOT/canon/raw"
  books=""
  for b in "$CANON"/book*/; do
    n="$(basename "$b")"
    [ -e "$ROOT/canon/raw/$n" ] || ln -s "$(cd "$b" && pwd)" "$ROOT/canon/raw/$n" 2>/dev/null || cp -r "$b" "$ROOT/canon/raw/$n"
    books="$books $n"
  done
  say "book text:$books (in canon/raw/, gitignored)"
else
  say "book text: NOT FOUND. Canon batches need it. Add repo Daddy-Ousen/innworld-canon-raw to the session (see docs/CLOUD.md)."
fi

# 4. git identity (the user's rule: commits show only Daddy-Ousen)
git -C "$ROOT" config user.name "Daddy-Ousen"
git -C "$ROOT" config user.email "97149447+Daddy-Ousen@users.noreply.github.com"

# 5. Godot import. Known: the import can segfault now and then; it still imports. Retry once.
if command -v godot >/dev/null 2>&1; then
  for try in 1 2; do
    timeout 900 godot --headless --path "$ROOT/game" --import >> "$LOG" 2>&1
    [ -f "$ROOT/game/.godot/global_script_class_cache.cfg" ] && break
  done
  if [ -f "$ROOT/game/.godot/global_script_class_cache.cfg" ]; then
    say "godot import: ok"
  else
    say "godot import: FAILED. See $LOG"
  fi
  # A fresh import may rewrite tracked .import files. Put them back so git stays clean.
  git -C "$ROOT" ls-files -m -- game | grep '\.import$' | (cd "$ROOT" && xargs -r git checkout --) 2>/dev/null
fi

say "done. Run tests with: bash tools/run_tests.sh <script> ...   (see CLAUDE.md, Cloud sessions)"
exit 0
