#!/bin/zsh

ROOT="${0:A:h:h}"
STATUS=0

cd "$ROOT"

echo "Building and starting Trickpad..."
echo

./scripts/build.sh && ./scripts/start.sh || STATUS=$?

echo
if [[ $STATUS -eq 0 ]]; then
  echo "Trickpad is ready."
else
  echo "Trickpad failed with exit code $STATUS."
fi
echo
read '?Press Enter to close this window...'
exit $STATUS
