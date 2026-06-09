#!/usr/bin/env bash
# Run panache format (autoformat) then panache lint (report) after Write/Edit on .qmd files.
# Panache is Quarto-aware (fenced divs, grid tables, citations) where generic markdown linters mangle.
set -uo pipefail

[[ "${CLAUDE_FILE_PATH:-}" == *.qmd ]] || exit 0
[[ -f "${CLAUDE_FILE_PATH}" ]] || exit 0

panache format "${CLAUDE_FILE_PATH}" >/dev/null 2>&1 || true

if ! output=$(panache lint --check --message-format short "${CLAUDE_FILE_PATH}" 2>&1); then
  jq -n \
    --arg ctx "Panache lint issues in ${CLAUDE_FILE_PATH}:"$'\n'"${output}" \
    --arg msg "Panache found issues in ${CLAUDE_FILE_PATH##*/}" \
    '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx},"systemMessage":$msg}'
fi
