#!/usr/bin/env bash
# Usage: bash ~/.claude/statusline/bootstrap.sh
# Clones and builds the claude-limitline status line.
set -euo pipefail

STATUSLINE_DIR="$HOME/.claude/statusline"
GITHUB_USER="underspecified"

mkdir -p "${STATUSLINE_DIR}"

if [[ ! -d "${STATUSLINE_DIR}/claude-limitline" ]]; then
    echo "Cloning claude-limitline..."
    gh repo clone "${GITHUB_USER}/claude-limitline" "${STATUSLINE_DIR}/claude-limitline"
    cd "${STATUSLINE_DIR}/claude-limitline"
    git remote add upstream https://github.com/tylergraydev/claude-limitline.git 2>/dev/null || true
fi

# Build if dist/ doesn't exist or is stale
if [[ ! -f "${STATUSLINE_DIR}/claude-limitline/dist/index.js" ]]; then
    echo "Building claude-limitline..."
    cd "${STATUSLINE_DIR}/claude-limitline"
    npm install && npm run build
fi

echo "=== Statusline bootstrap complete ==="
