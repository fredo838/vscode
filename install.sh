#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

export PATH="$ROOT/.tools/node24/bin:$PATH"

node -v
npm install "$@"
npm run compile
