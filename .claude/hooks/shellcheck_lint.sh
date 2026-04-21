#!/usr/bin/env bash
# Run shellcheck after Write/Edit on .sh files and inject findings into Claude context.
set -uo pipefail

[[ "${CLAUDE_FILE_PATH:-}" == *.sh ]] || exit 0
[[ -f "${CLAUDE_FILE_PATH}" ]] || exit 0

if ! output=$(shellcheck "${CLAUDE_FILE_PATH}" 2>&1); then
  jq -n \
    --arg ctx "ShellCheck issues in ${CLAUDE_FILE_PATH}:"$'\n'"${output}" \
    --arg msg "ShellCheck found issues in ${CLAUDE_FILE_PATH##*/}" \
    '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx},"systemMessage":$msg}'
fi
