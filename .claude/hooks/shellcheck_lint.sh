#!/usr/bin/env bash
# Run shfmt (format) then shellcheck (lint) after Write/Edit on .sh files.
set -uo pipefail

# The edited path arrives in the hook's stdin JSON, NOT an environment variable.
# There is no CLAUDE_FILE_PATH — the harness exports only CLAUDE_PROJECT_DIR,
# CLAUDE_PLUGIN_ROOT, CLAUDE_PLUGIN_DATA, CLAUDE_EFFORT and CLAUDE_CODE_*. This
# hook gated on that unset name, so it exited at line 1 of its own logic on
# every invocation and silently formatted nothing for months.
file="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)"

[[ "${file}" == *.sh ]] || exit 0
[[ -f "${file}" ]] || exit 0

# -i 2: rules/bash.md mandates 2-space indentation, no tabs. shfmt defaults to
# tabs, so an unflagged run makes the formatter fight the documented convention
# on every shell file it touches.
shfmt -i 2 -w "${file}"

if ! output=$(shellcheck "${file}" 2>&1); then
  jq -n \
    --arg ctx "ShellCheck issues in ${file}:"$'\n'"${output}" \
    --arg msg "ShellCheck found issues in ${file##*/}" \
    '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx},"systemMessage":$msg}'
fi
