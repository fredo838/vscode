#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

export PATH="$ROOT/.tools/node24/bin:$PATH"

node -v
npm install "$@"
npm run compile
npm run electron

# Electron's setuid sandbox helper must be owned by root with mode 4755,
# but npm/electron always extracts it owned by the current user.
if [[ "$OSTYPE" != "darwin"* && -f ".build/electron/chrome-sandbox" ]]; then
	sudo chown root:root ".build/electron/chrome-sandbox"
	sudo chmod 4755 ".build/electron/chrome-sandbox"
fi

# Sign the app with a stable local identity so macOS Keychain doesn't
# re-prompt for safe storage access on every rebuild.
if [[ "$OSTYPE" == "darwin"* ]]; then
	bash "$ROOT/scripts/codesign-local.sh"
fi
