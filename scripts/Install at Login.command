#!/bin/zsh

ROOT="${0:A:h:h}"
STATUS=0

cd "$ROOT"

echo "Installing Trickpad to launch at login..."
echo

./scripts/install-login-agent.sh || STATUS=$?

echo
if [[ $STATUS -eq 0 ]]; then
  echo "Trickpad will now start automatically after login."
else
  echo "Install failed with exit code $STATUS."
fi
echo
read '?Press Enter to close this window...'
exit $STATUS
