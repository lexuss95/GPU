#!/bin/bash
# Install the MiniTile toolchain in Claude Code cloud sessions so `make check` works.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"
tools/install.sh
