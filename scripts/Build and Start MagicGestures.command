#!/bin/zsh

ROOT="${0:A:h:h}"
STATUS=0

cd "$ROOT"

echo "Building and starting MagicGestures..."
echo

python3 ./generate_config.py && ./scripts/build.sh && ./scripts/start.sh || STATUS=$?

echo
if [[ $STATUS -eq 0 ]]; then
  echo "MagicGestures is ready."
else
  echo "MagicGestures failed with exit code $STATUS."
fi
echo
read '?Press Enter to close this window...'
exit $STATUS
