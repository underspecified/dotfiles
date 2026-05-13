#!/bin/bash
# PreToolUse hook: git safety gate
#
# Responsibilities:
#   1. Rewrite `cd <dir> && git <args>` → `git -C <dir> <args>`
#      (avoids compound-expression permission failures)
#   2. Nag the model to review docs before `git commit` (non-blocking
#      reminder via permissionDecisionReason; commit still proceeds)
#
# Non-git Bash commands fall through (exit 0, no JSON output).

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "${INPUT}" | jq -r '.tool_input.command // empty')
ORIGINAL="${COMMAND}"

# Fast path: not a git command.
if [[ ! "${COMMAND}" =~ (^|[[:space:]]|&|\;)git([[:space:]]|$) ]]; then
  exit 0
fi

# Pull the first line of the ORIGINAL, strip heredoc delimiter, for
# commit-intent detection (semantic check — must happen before rewrite).
CMD_LINE=$(echo "${ORIGINAL}" | head -1 | sed 's/<<.*//')

# --- Find doc files in the cwd (caller's repo root, typically) ---
find_docs() {
  local docs=""
  [[ -f "CLAUDE.md" ]]       && docs="${docs} CLAUDE.md"
  [[ -f "README.md" ]]       && docs="${docs} README.md"
  [[ -f "CONTRIBUTING.md" ]] && docs="${docs} CONTRIBUTING.md"
  [[ -f "CHANGELOG.md" ]]    && docs="${docs} CHANGELOG.md"
  echo "${docs}"
}

# --- 1. `git commit` → block if any staged file is over GitHub's 100MB limit ---
# GitHub hard-rejects pushes containing files >100MB (no LFS configured).
# Pushing then having to amend / rewrite history is painful, so catch at
# commit time. Tolerant of edge cases (non-repo dir, missing files).
if [[ "${CMD_LINE}" =~ (^|[[:space:]]|&|\;)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit ]]; then
  LARGE_FILES=$(git diff --cached --name-only --diff-filter=AM 2>/dev/null | \
    while IFS= read -r f; do
      [ -z "${f}" ] && continue
      [ -f "${f}" ] || continue
      sz=$(stat -c%s "${f}" 2>/dev/null || stat -f%z "${f}" 2>/dev/null || echo 0)
      if [ "${sz}" -gt 104857600 ]; then  # 100 * 1024 * 1024
        printf '  %s (%s bytes)\n' "${f}" "${sz}"
      fi
    done)
  if [ -n "${LARGE_FILES}" ]; then
    MSG="🛑 Commit blocked: staged file(s) exceed GitHub's 100MB limit.\n${LARGE_FILES}\nUnstage them (git restore --staged <path>), move to a gitignored location, or set up git-lfs before re-attempting."
    jq -n --arg msg "${MSG}" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $msg
      }
    }'
    exit 0
  fi

  DOCS=$(find_docs)
  if [[ -n "${DOCS}" ]]; then
    MSG="📝 Before committing: review${DOCS} and update if changes affect structure, scripts, deps, or interfaces. Stage any doc changes alongside the commit."
    jq -n --arg msg "${MSG}" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        permissionDecisionReason: $msg
      }
    }'
    exit 0
  fi
fi

# --- 2. Compound rewrite: `cd <dir> && git <args>` → `git -C <dir> <args>` ---
# Only rewrites the exact single-cd-then-single-git shape. Anything more
# complex (multiple &&, pipes, subshells) falls through untouched.
if [[ "${ORIGINAL}" =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]&\;|]+)[[:space:]]*\&\&[[:space:]]*git[[:space:]]+(.*)$ ]]; then
  DIR="${BASH_REMATCH[1]}"
  REST="${BASH_REMATCH[2]}"
  DIR="${DIR%\"}"; DIR="${DIR#\"}"
  DIR="${DIR%\'}"; DIR="${DIR#\'}"
  REWRITTEN="git -C ${DIR} ${REST}"
  jq -n --arg cmd "${REWRITTEN}" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecisionReason: "Rewrote `cd && git ...` to `git -C ...` to avoid compound-expression permission check"
    },
    updatedInput: { command: $cmd }
  }'
  exit 0
fi

# Fall through: let the normal permission system decide.
exit 0
