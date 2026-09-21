#!/usr/bin/env bash
# Run panache format (autoformat) then panache lint (report) after Write/Edit on .qmd files.
# Panache is Quarto-aware (fenced divs, grid tables, citations) where generic markdown linters mangle.
set -uo pipefail

# The edited path arrives in the hook's stdin JSON, NOT an environment variable.
# There is no CLAUDE_FILE_PATH — see shellcheck_lint.sh for the full note. This
# hook gated on that unset name and silently did nothing for months.
file="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)"

[[ "${file}" == *.qmd ]] || exit 0
[[ -f "${file}" ]] || exit 0

# NEVER format a file carrying git conflict markers. A markdown formatter reads
# `=======` as a setext heading underline and `|||||||` as text, rewrites them
# into headings, and the heading-increment rule then cascades DEMOTIONS through
# every heading below — silently destroying a conflict resolution in progress.
# Observed 2026-09-21 on dispatch CLAUDE.md: `||||||| a2d0347` became
# `## ||||||| a2d0347` and demoted six sections under it. Skipping is always
# safe; the file gets formatted on the next write once the merge is resolved.
grep -qE '^(<<<<<<<|=======|>>>>>>>|\|\|\|\|\|\|\|)' "${file}" 2>/dev/null && exit 0

panache format "${file}" >/dev/null 2>&1 || true

if ! output=$(panache lint --check --message-format short "${file}" 2>&1); then
  jq -n \
    --arg ctx "Panache lint issues in ${file}:"$'\n'"${output}" \
    --arg msg "Panache found issues in ${file##*/}" \
    '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx},"systemMessage":$msg}'
fi
