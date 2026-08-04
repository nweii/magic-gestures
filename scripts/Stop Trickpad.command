#!/bin/zsh

ROOT="${0:A:h:h}"
STATUS=0

cd "$ROOT"

echo "Stopping Trickpad..."
echo

./scripts/stop.sh || STATUS=$?

echo
if [[ $STATUS -eq 0 ]]; then
  echo "Trickpad has stopped."
else
  echo "Trickpad failed with exit code $STATUS."
fi
echo
read '?Press Enter to close this window...'
exit $STATUS
