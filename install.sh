#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Use a repo-local Node matching .nvmrc, downloading it on first use.
NODE_VERSION="$(tr -d '[:space:]' < .nvmrc)"
NODE_DIR="$ROOT/.tools/node${NODE_VERSION%%.*}"
if [[ "$("$NODE_DIR/bin/node" -v 2>/dev/null)" != "v$NODE_VERSION" ]]; then
	case "$(uname -s)" in
		Darwin) NODE_OS=darwin ;;
		Linux) NODE_OS=linux ;;
		*) echo "error: unsupported OS $(uname -s)" >&2; exit 1 ;;
	esac
	case "$(uname -m)" in
		arm64|aarch64) NODE_ARCH=arm64 ;;
		x86_64) NODE_ARCH=x64 ;;
		*) echo "error: unsupported architecture $(uname -m)" >&2; exit 1 ;;
	esac
	NODE_DIST="node-v$NODE_VERSION-$NODE_OS-$NODE_ARCH"
	echo "Downloading Node.js v$NODE_VERSION into $NODE_DIR..."
	rm -rf "$NODE_DIR"
	mkdir -p "$NODE_DIR"
	curl -fsSL "https://nodejs.org/dist/v$NODE_VERSION/$NODE_DIST.tar.gz" | tar -xz -C "$NODE_DIR" --strip-components=1
fi
export PATH="$NODE_DIR/bin:$PATH"

# Node doesn't trust the macOS keychain, so TLS-intercepting proxies (e.g. Zscaler)
# break postinstall downloads. Hand Node the keychain's certificates explicitly.
if [[ "$OSTYPE" == "darwin"* && -z "${NODE_EXTRA_CA_CERTS:-}" ]]; then
	CA_BUNDLE="$ROOT/.build/macos-ca-bundle.pem"
	mkdir -p "$(dirname "$CA_BUNDLE")"
	security find-certificate -a -p \
		/Library/Keychains/System.keychain \
		"$HOME/Library/Keychains/login.keychain-db" > "$CA_BUNDLE" 2>/dev/null || true
	if [[ -s "$CA_BUNDLE" ]]; then
		export NODE_EXTRA_CA_CERTS="$CA_BUNDLE"
	fi
fi

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
