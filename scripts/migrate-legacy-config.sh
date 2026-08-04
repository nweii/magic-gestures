#!/bin/zsh
# Moves the pre-release Magic Gestures settings folder to Trickpad when the new
# destination does not exist. Competing folders are left untouched.
set -euo pipefail

LEGACY_CONFIG_DIR="$HOME/.config/magic-gestures"
CONFIG_DIR="$HOME/.config/trickpad"

if [[ -d "$LEGACY_CONFIG_DIR" && ! -e "$CONFIG_DIR" ]]; then
  mkdir -p "$HOME/.config"
  mv "$LEGACY_CONFIG_DIR" "$CONFIG_DIR"
elif [[ -d "$LEGACY_CONFIG_DIR" && -e "$CONFIG_DIR" ]]; then
  echo "Both $LEGACY_CONFIG_DIR and $CONFIG_DIR exist; using Trickpad without merging them." >&2
fi
