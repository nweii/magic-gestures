#!/bin/zsh

ROOT="${0:A:h}"
STATUS=0

cd "$ROOT"

echo "Removing MagicGestures from launch at login..."
echo

./uninstall-login-agent.sh || STATUS=$?

echo
if [[ $STATUS -eq 0 ]]; then
  echo "MagicGestures will no longer start automatically after login."
else
  echo "Uninstall failed with exit code $STATUS."
fi
echo
read '?Press Enter to close this window...'
exit $STATUS
