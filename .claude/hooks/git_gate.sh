#!/bin/bash
# PreToolUse hook: git safety gate
#
# Responsibilities:
#   1. Rewrite `cd <dir> && git <args>` → `git -C <dir> <args>`
#      (avoids compound-expression permission failures)
#   2. Block `git commit` when a staged file exceeds GitHub's 100MB limit
#   3. Nag the model to review docs before `git commit` (non-blocking
#      reminder via additionalContext; commit still proceeds)
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

# --- Which repo is this commit actually touching? ---
# Both checks below inspect a working tree. Using the hook's own cwd is wrong
# whenever the command carries `git -C <dir>` — which CLAUDE.md actively
# prefers — so the size guard silently examined an unrelated index and passed
# vacuously. Honor `-C` first, then the payload's cwd, then $PWD.
strip_quotes() {
  local s="$1"
  s="${s%\"}"
  s="${s#\"}"
  s="${s%\'}"
  s="${s#\'}"
  echo "${s}"
}

REPO_DIR="$(echo "${INPUT}" | jq -r '.cwd // empty')"
if [[ "${CMD_LINE}" =~ git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
  REPO_DIR="$(strip_quotes "${BASH_REMATCH[1]}")"
fi
REPO_DIR="${REPO_DIR:-${PWD}}"
# Expand a leading ~ (the payload and command may both carry one).
[[ "${REPO_DIR}" == "~"* ]] && REPO_DIR="${HOME}${REPO_DIR#\~}"

# --- Find doc files in the target repo ---
find_docs() {
  local docs=""
  [[ -f "${REPO_DIR}/CLAUDE.md" ]] && docs="${docs} CLAUDE.md"
  [[ -f "${REPO_DIR}/README.md" ]] && docs="${docs} README.md"
  [[ -f "${REPO_DIR}/CONTRIBUTING.md" ]] && docs="${docs} CONTRIBUTING.md"
  [[ -f "${REPO_DIR}/CHANGELOG.md" ]] && docs="${docs} CHANGELOG.md"
  echo "${docs}"
}

# --- 1. `git commit` → block if any staged file is over GitHub's 100MB limit ---
# GitHub hard-rejects pushes containing files >100MB (no LFS configured).
# Pushing then having to amend / rewrite history is painful, so catch at
# commit time. Tolerant of edge cases (non-repo dir, missing files).
if [[ "${CMD_LINE}" =~ (^|[[:space:]]|&|\;)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit ]]; then
  # `git diff --cached` exits 129 (usage error) when REPO_DIR is not a work
  # tree, and `set -e` + pipefail turn that into an abort — killing the size
  # guard AND the nag below. Gate on rev-parse so a mis-resolved or non-repo
  # REPO_DIR degrades to "skip the guard" instead of "kill the hook".
  if git -C "${REPO_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    LARGE_FILES=$(git -C "${REPO_DIR}" diff --cached --name-only --diff-filter=AM 2>/dev/null |
      while IFS= read -r f; do
        [ -z "${f}" ] && continue
        [ -f "${REPO_DIR}/${f}" ] || continue
        sz=$(stat -c%s "${REPO_DIR}/${f}" 2>/dev/null || stat -f%z "${REPO_DIR}/${f}" 2>/dev/null || echo 0)
        if [ "${sz}" -gt 104857600 ]; then # 100 * 1024 * 1024
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
  fi

  DOCS=$(find_docs)
  if [[ -n "${DOCS}" ]]; then
    MSG="📝 Before committing: review${DOCS} in ${REPO_DIR} and update if changes affect structure, scripts, deps, or interfaces. Stage any doc changes alongside the commit."
    # additionalContext, NOT permissionDecisionReason. A reason is rendered only
    # when the decision is "deny"/"block" — on "allow" it is never displayed, so
    # under skipAutoPermissionPrompt + auto mode this nag reached nobody at all.
    # Dropping the "allow" also restores normal permission checking: carrying the
    # message that way was auto-approving every git commit as a side effect.
    #
    # additionalContext reaches the MODEL only — it is never rendered in the
    # user's terminal. systemMessage is the user-visible channel, so the nag
    # carries both: the full instruction for the model, one terse line for the
    # human who wants evidence the gate is alive.
    jq -n --arg ctx "${MSG}" --arg msg "📝 Doc-update check: ${DOCS# } in ${REPO_DIR##*/}" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: $ctx
      },
      systemMessage: $msg
    }'
    exit 0
  fi
fi

# --- 2. Compound rewrite: `cd <dir> && git <args>` → `git -C <dir> <args>` ---
# Only rewrites the exact single-cd-then-single-git shape. Anything more
# complex (multiple &&, pipes, subshells) falls through untouched.
if [[ "${ORIGINAL}" =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]&\;|]+)[[:space:]]*\&\&[[:space:]]*git[[:space:]]+(.*)$ ]]; then
  DIR="$(strip_quotes "${BASH_REMATCH[1]}")"
  REST="${BASH_REMATCH[2]}"
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
