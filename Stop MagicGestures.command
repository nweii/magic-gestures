#!/bin/zsh

ROOT="${0:A:h}"
STATUS=0

cd "$ROOT"

echo "Stopping MagicGestures..."
echo

./stop.sh || STATUS=$?

echo
if [[ $STATUS -eq 0 ]]; then
  echo "MagicGestures has stopped."
else
  echo "MagicGestures failed with exit code $STATUS."
fi
echo
read '?Press Enter to close this window...'
exit $STATUS
