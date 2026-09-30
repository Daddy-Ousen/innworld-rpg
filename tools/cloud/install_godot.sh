#!/usr/bin/env bash
# Install the Godot build this project uses (Linux x86_64) and link it as `godot`.
# Cloud sessions only (Ubuntu). Safe to run again: it skips when the right version is there.
# Tries the official GitHub release first, then the unchanged backup copy in this repo's
# Releases (tag tools-godot-4.7.2), because the cloud GitHub proxy may block other repos' assets.
set -u

GODOT_VER="4.7.2"
ZIP="Godot_v${GODOT_VER}-stable_linux.x86_64.zip"
BIN="Godot_v${GODOT_VER}-stable_linux.x86_64"
SHA512="9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65"
URLS=(
  "https://github.com/godotengine/godot/releases/download/${GODOT_VER}-stable/${ZIP}"
  "https://github.com/Daddy-Ousen/innworld-rpg/releases/download/tools-godot-${GODOT_VER}/${ZIP}"
)

if command -v godot >/dev/null 2>&1 && godot --headless --version 2>/dev/null | grep -q "^${GODOT_VER}\."; then
  echo "godot ${GODOT_VER}: already installed"
  exit 0
fi

DEST="/opt/godot-${GODOT_VER}"
LINK_DIR="/usr/local/bin"
if ! mkdir -p "$DEST" 2>/dev/null || [ ! -w "$LINK_DIR" ]; then
  DEST="$HOME/.local/godot-${GODOT_VER}"
  LINK_DIR="$HOME/.local/bin"
  mkdir -p "$DEST" "$LINK_DIR"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
ok=0
for url in "${URLS[@]}"; do
  if curl -fsSL --retry 2 --connect-timeout 20 -o "$TMP/$ZIP" "$url" \
     && echo "${SHA512}  $TMP/$ZIP" | sha512sum -c --status; then
    echo "godot ${GODOT_VER}: downloaded from $url"
    ok=1
    break
  fi
  echo "godot ${GODOT_VER}: download failed or bad checksum: $url"
done
if [ "$ok" != 1 ]; then
  echo "godot ${GODOT_VER}: INSTALL FAILED (no download worked)"
  exit 1
fi

if command -v unzip >/dev/null 2>&1; then
  unzip -oq "$TMP/$ZIP" -d "$DEST"
else
  python3 -m zipfile -e "$TMP/$ZIP" "$DEST"
fi
chmod +x "$DEST/$BIN"
ln -sf "$DEST/$BIN" "$LINK_DIR/godot"

if ! "$LINK_DIR/godot" --headless --version >/dev/null 2>&1; then
  # A headless run needs only a few system libs; add them if the image lacks them.
  (apt-get update -qq && apt-get install -y -qq libfontconfig1 libgl1 >/dev/null) 2>/dev/null || true
fi
echo "godot: $("$LINK_DIR/godot" --headless --version 2>/dev/null | head -1) at $LINK_DIR/godot"
