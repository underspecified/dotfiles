#!/usr/bin/env bash
# Usage: bash ~/.claude/statusline/bootstrap.sh
# Clones (or fast-forward-updates) and builds the claude-limitline status
# line. Safe to re-run -- rebuilds only when HEAD actually moves or when
# dist/index.js is missing.
set -euo pipefail

STATUSLINE_DIR="$HOME/.claude/statusline"
LIMITLINE_DIR="${STATUSLINE_DIR}/claude-limitline"
GITHUB_USER="underspecified"

mkdir -p "${STATUSLINE_DIR}"

needs_build=0

if [[ ! -d "${LIMITLINE_DIR}" ]]; then
    echo "Cloning claude-limitline..."
    gh repo clone "${GITHUB_USER}/claude-limitline" "${LIMITLINE_DIR}"
    git -C "${LIMITLINE_DIR}" remote add upstream https://github.com/tylergraydev/claude-limitline.git 2>/dev/null || true
    needs_build=1
else
    # Pull only if clean + on a branch; otherwise leave local WIP alone.
    if [[ -n "$(git -C "${LIMITLINE_DIR}" status --porcelain)" ]]; then
        echo "Skipping claude-limitline update: dirty working tree"
    elif ! git -C "${LIMITLINE_DIR}" symbolic-ref --quiet HEAD >/dev/null; then
        echo "Skipping claude-limitline update: detached HEAD"
    else
        before="$(git -C "${LIMITLINE_DIR}" rev-parse HEAD)"
        if git -C "${LIMITLINE_DIR}" pull --ff-only --quiet; then
            after="$(git -C "${LIMITLINE_DIR}" rev-parse HEAD)"
            if [[ "${before}" != "${after}" ]]; then
                echo "Updated claude-limitline: ${before:0:7} → ${after:0:7}"
                needs_build=1
            fi
        else
            echo "Pull failed: claude-limitline (likely diverged from origin)" >&2
        fi
    fi
fi

# Build if HEAD moved, on first clone, or if dist/ is missing.
if [[ ${needs_build} -eq 1 || ! -f "${LIMITLINE_DIR}/dist/index.js" ]]; then
    echo "Building claude-limitline..."
    (cd "${LIMITLINE_DIR}" && npm install && npm run build)
fi

echo "=== Statusline bootstrap complete ==="
