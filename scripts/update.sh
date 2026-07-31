#!/bin/zsh
# Updates a clean source checkout from public origin/main, previews incoming
# commits, validates the result, rebuilds the app, and restarts it.
set -euo pipefail

ROOT="${0:A:h:h}"
ASSUME_YES=0

if [[ "${1:-}" == "--yes" ]]; then
  ASSUME_YES=1
elif [[ -n "${1:-}" ]]; then
  echo "Usage: $0 [--yes]" >&2
  exit 2
fi

cd "$ROOT"

if [[ "$(git branch --show-current)" != "main" ]]; then
  echo "Switch to the main branch before updating. Nothing changed." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "The checkout has uncommitted changes. Commit or set them aside before updating." >&2
  exit 1
fi

git fetch origin main

LOCAL="$(git rev-parse HEAD)"
REMOTE="$(git rev-parse origin/main)"

if [[ "$LOCAL" == "$REMOTE" ]]; then
  echo "Magic Gestures is already up to date."
  exit 0
fi

if ! git merge-base --is-ancestor "$LOCAL" "$REMOTE"; then
  echo "The local branch cannot fast-forward to origin/main. Nothing changed." >&2
  exit 1
fi

echo "Incoming Magic Gestures changes:"
git log --oneline --no-decorate "$LOCAL..$REMOTE"

if (( ! ASSUME_YES )); then
  echo
  read "REPLY?Install this update? [y/N] "
  [[ "$REPLY" == [Yy] ]] || {
    echo "Update canceled."
    exit 0
  }
fi

git merge --ff-only "$REMOTE"
./scripts/check.sh
./scripts/build.sh
./scripts/stop.sh
./scripts/start.sh

echo "Magic Gestures updated successfully."
