#!/bin/zsh
set -euo pipefail

# Builds the local trace analyzer and runs it against one exported diagnostic bundle.

ROOT="${0:A:h:h}"
OUT="$(mktemp -d)/analyze-trace"
SDKROOT="$(xcrun --show-sdk-path)"

clang \
  -fblocks \
  -fobjc-exceptions \
  -fno-objc-arc \
  -isysroot "$SDKROOT" \
  -framework Foundation \
  "$ROOT/src/TraceAnalyzer.m" \
  -o "$OUT"

exec "$OUT" "$@"
