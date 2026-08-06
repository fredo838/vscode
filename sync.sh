#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

UPSTREAM_REMOTE="upstream"
UPSTREAM_URL="https://github.com/microsoft/vscode.git"
MAIN_BRANCH="main"

if [[ -n "$(git status --porcelain)" ]]; then
	echo "error: working tree is not clean. Commit or stash your changes first." >&2
	git status --short
	exit 1
fi

ORIGINAL_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if ! git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1; then
	echo "Adding remote '$UPSTREAM_REMOTE' -> $UPSTREAM_URL"
	git remote add "$UPSTREAM_REMOTE" "$UPSTREAM_URL"
fi

echo "Fetching $UPSTREAM_REMOTE..."
git fetch "$UPSTREAM_REMOTE"

echo "Syncing local '$MAIN_BRANCH' with $UPSTREAM_REMOTE/$MAIN_BRANCH..."
git checkout "$MAIN_BRANCH"
git merge --no-edit "$UPSTREAM_REMOTE/$MAIN_BRANCH"

echo "Pushing '$MAIN_BRANCH' to origin..."
git push origin "$MAIN_BRANCH"

if [[ "$ORIGINAL_BRANCH" != "$MAIN_BRANCH" ]]; then
	echo "Rebasing '$ORIGINAL_BRANCH' onto '$MAIN_BRANCH'..."
	git checkout "$ORIGINAL_BRANCH"
	if ! git rebase "$MAIN_BRANCH"; then
		echo "error: rebase of '$ORIGINAL_BRANCH' onto '$MAIN_BRANCH' hit conflicts." >&2
		echo "Resolve them, then run 'git rebase --continue' (or 'git rebase --abort')," >&2
		echo "and re-run the build step yourself: ./install.sh && npm run compile" >&2
		exit 1
	fi
fi

echo "Installing dependencies..."
./install.sh

echo "Compiling..."
npm run compile

echo "Done. Synced '$MAIN_BRANCH' with $UPSTREAM_REMOTE/$MAIN_BRANCH, pushed to origin,"
echo "rebased '$ORIGINAL_BRANCH' onto it, and rebuilt."
echo "Compiled output is in ./out (launch with ./scripts/code.sh)."
