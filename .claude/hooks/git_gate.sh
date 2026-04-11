#!/bin/bash
# PreToolUse hook: git safety gate
#
# Responsibilities:
#   1. Rewrite `cd <dir> && git <args>` → `git -C <dir> <args>`
#      (avoids compound-expression permission failures)
#   2. Enforce doc-review before `git commit` (deny raw commits,
#      direct user through ask_git_commit.sh wrapper)
#   3. Turn `ask_git_commit.sh` invocations into a friendly "ask"
#      permission prompt listing relevant docs
#
# Non-git Bash commands fall through (exit 0, no JSON output).

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "${INPUT}" | jq -r '.tool_input.command // empty')
ORIGINAL="${COMMAND}"

# Fast path: not a git-adjacent command at all.
if [[ ! "${COMMAND}" =~ (^|[[:space:]]|&|\;)git([[:space:]]|$) ]] \
   && [[ ! "${COMMAND}" =~ ask_git_commit\.sh ]]; then
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

# --- 1. ask_git_commit.sh wrapper → friendly ask prompt ---
if [[ "${ORIGINAL}" =~ ask_git_commit\.sh ]]; then
  DOCS=$(find_docs)
  jq -n --arg docs "${DOCS}" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: ("📝 Approve commit? Docs should be verified:" + $docs)
    }
  }'
  exit 0
fi

# --- 2. Raw `git commit` (anywhere in the command) → deny with doc-review ---
# Match plain commits, commits after cd-and-&&, commits with -C, etc.
if [[ "${CMD_LINE}" =~ (^|[[:space:]]|&|\;)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit ]]; then
  DOCS=$(find_docs)
  if [[ -n "${DOCS}" ]]; then
    MSG="⚠️ Doc review required!

1. Read:${DOCS}
2. Update docs if changes affect: structure, scripts, deps, interfaces
3. Tell user what you checked/updated
4. Stage doc changes
5. Use: ~/.claude/hooks/ask_git_commit.sh -m \"message\""
    jq -n --arg msg "${MSG}" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $msg
      }
    }'
    exit 0
  fi
fi

# --- 3. Compound rewrite: `cd <dir> && git <args>` → `git -C <dir> <args>` ---
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
