#!/usr/bin/env bash
# Run shfmt (format) then shellcheck (lint) after Write/Edit on .sh files.
set -uo pipefail

[[ "${CLAUDE_FILE_PATH:-}" == *.sh ]] || exit 0
[[ -f "${CLAUDE_FILE_PATH}" ]] || exit 0

shfmt -w "${CLAUDE_FILE_PATH}"

if ! output=$(shellcheck "${CLAUDE_FILE_PATH}" 2>&1); then
  jq -n \
    --arg ctx "ShellCheck issues in ${CLAUDE_FILE_PATH}:"$'\n'"${output}" \
    --arg msg "ShellCheck found issues in ${CLAUDE_FILE_PATH##*/}" \
    '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx},"systemMessage":$msg}'
fi
