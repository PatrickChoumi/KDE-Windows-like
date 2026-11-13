#!/usr/bin/env bash
# Publie un dossier de résultats CI dans UN SEUL commit de la branche ci-out (sous-dossier <nom>).
# Usage : ci/publish.sh <dossier-source> <sous-dossier> ; variables : GITHUB_TOKEN, GITHUB_REPOSITORY, GITHUB_RUN_ID.
# Un seul commit orphelin (pas d'historique d'images) ; les autres sous-dossiers sont conservés ; nouvel essai en cas de course entre workflows.
set -u
SRC="$(realpath "${1:?dossier source}" 2>/dev/null || echo "$1")"; SUB="${2:?sous-dossier}"
STAGE=/tmp/ci-out-stage; rm -rf "$STAGE"; mkdir -p "$STAGE"; [ -d "$SRC" ] && cp -r "$SRC"/. "$STAGE"/ 2>/dev/null
HERE="$PWD"
URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
git config --global --add safe.directory "${GITHUB_WORKSPACE:-.}" 2>/dev/null || true
for try in 1 2 3 4 5 6; do
  W=/tmp/ci-out-work; rm -rf "$W" && mkdir "$W" && cd "$W" || exit 1
  git init -q -b ci-out
  git config user.name ci && git config user.email ci@users.noreply.github.com
  OLD=""
  if git fetch -q --depth 1 "$URL" ci-out 2>/dev/null; then
    OLD=$(git rev-parse FETCH_HEAD); git checkout -q FETCH_HEAD -- . 2>/dev/null
  fi
  rm -rf "./$SUB" && mkdir -p "./$SUB"
  cp -r "$STAGE"/. "./$SUB/" 2>/dev/null
  echo "run $GITHUB_RUN_ID $(date -u +%FT%TZ)" > "./$SUB/RUN.txt"
  git add -A && git commit -q -m "ci-out: $SUB run $GITHUB_RUN_ID"
  if git push -q --force-with-lease="ci-out:$OLD" "$URL" ci-out:ci-out 2>/dev/null; then echo "publié dans ci-out/$SUB (essai $try)"; exit 0; fi
  echo "poussée refusée (course avec un autre workflow), essai $try"; cd "$HERE" || exit 1; sleep $((try*3))
done
echo "::warning::publication ci-out/$SUB impossible"; exit 0
