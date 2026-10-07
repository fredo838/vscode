#!/usr/bin/env bash
# Code-signs the locally built Electron app with a stable, self-signed
# identity kept in the user's login keychain (no sudo/admin required).
#
# Without this, every rebuild produces an unsigned binary with a different
# identity, so macOS Keychain treats it as a "new" app each time and
# re-prompts for access to the "code-oss-dev Safe Storage" item. Signing
# consistently with the same local certificate keeps that identity stable
# across rebuilds, so the "Always Allow" grant sticks.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CERT_CN="VSCodeOSS Local Dev"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
APP_PATH=".build/electron/Code - OSS.app"

# Persistent backup of the private key/cert, outside the repo and outside any
# temp dir. If the keychain item is ever deleted or the keychain is reset,
# re-importing from here keeps the exact same signing identity instead of
# generating a new one (which would reset the "Always Allow" grant again).
BACKUP_DIR="$HOME/.vscode-oss-codesign"
BACKUP_KEY="$BACKUP_DIR/key.pem"
BACKUP_CERT="$BACKUP_DIR/cert.pem"

if [[ ! -d "$APP_PATH" ]]; then
	echo "codesign-local: '$APP_PATH' not found, skipping." >&2
	exit 0
fi

if ! security find-identity -v -p codesigning "$KEYCHAIN" 2>/dev/null | grep -q "$CERT_CN"; then
	if [[ -f "$BACKUP_KEY" && -f "$BACKUP_CERT" ]]; then
		echo "codesign-local: identity missing from keychain, restoring from backup '$BACKUP_DIR'..."
	else
		echo "codesign-local: creating local self-signed code-signing certificate '$CERT_CN'..."
		mkdir -p "$BACKUP_DIR"
		chmod 700 "$BACKUP_DIR"
		openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
			-keyout "$BACKUP_KEY" -out "$BACKUP_CERT" \
			-subj "/CN=$CERT_CN" \
			-addext "keyUsage=critical,digitalSignature" \
			-addext "extendedKeyUsage=codeSigning" \
			-addext "basicConstraints=critical,CA:false"
		chmod 600 "$BACKUP_KEY" "$BACKUP_CERT"
	fi

	WORKDIR="$(mktemp -d)"
	trap 'rm -rf "$WORKDIR"' EXIT

	# Always rebuild the .p12 from the PEM backup so the key gets a known label.
	# -name sets the label Keychain gives the imported private key (otherwise it
	# gets a random one), which set-key-partition-list -l below matches on.
	# -legacy: OpenSSL 3.x defaults to a PKCS12 MAC/cipher that macOS's
	# SecKeychainItemImport can't parse, which fails as a bogus "wrong
	# password" error. -legacy forces the older RC2/SHA1 scheme Keychain
	# understands.
	openssl pkcs12 -export -legacy -name "$CERT_CN" \
		-inkey "$BACKUP_KEY" -in "$BACKUP_CERT" \
		-out "$WORKDIR/cert.p12" -passout pass:local

	# -A grants every app access to the key with no further prompts. This
	# only touches the user's own login keychain, so it doesn't require
	# sudo/admin.
	security import "$WORKDIR/cert.p12" -k "$KEYCHAIN" -P local -T /usr/bin/codesign -A

	# -T alone isn't enough on modern macOS to suppress the "codesign wants to
	# access key..." confirmation dialog. Explicitly whitelist codesign's tool
	# partition so it can use the key silently from now on. -l restricts this to
	# our key only; without it, every private key in the login keychain would
	# have its partition list overwritten. This prompts once for your login
	# (keychain) password, not sudo/admin.
	echo "codesign-local: authorizing codesign to use the key without prompting..."
	security set-key-partition-list -S apple-tool:,apple:,codesign: -l "$CERT_CN" -s "$KEYCHAIN" >/dev/null
fi

echo "codesign-local: signing '$APP_PATH' with '$CERT_CN'..."
codesign --force --deep --sign "$CERT_CN" "$APP_PATH"
