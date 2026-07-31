#!/bin/zsh
set -euo pipefail

# Compiles and runs the configuration parser checks. No framework, no fixtures:
# the parser is the one part of this project that is pure input to output, and
# a wrong binding there reads as success while doing nothing.

ROOT="${0:A:h:h}"
OUT="$(mktemp -d)/configcheck"
SDKROOT="$(xcrun --show-sdk-path)"

clang \
  -fobjc-exceptions \
  -fno-objc-arc \
  -I"$ROOT/src" \
  -isysroot "$SDKROOT" \
  -framework Foundation \
  -framework ApplicationServices \
  -framework Carbon \
  "$ROOT/src/Config.m" \
  "$ROOT/src/ConfigCheck.m" \
  -o "$OUT" 2>/dev/null

"$OUT" "$ROOT/config.default.txt"
