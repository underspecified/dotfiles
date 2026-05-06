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

# --- 1. `git commit` → allow with a doc-review nag ---
# Match plain commits, commits after cd-and-&&, commits with -C, etc.
if [[ "${CMD_LINE}" =~ (^|[[:space:]]|&|\;)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit ]]; then
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
