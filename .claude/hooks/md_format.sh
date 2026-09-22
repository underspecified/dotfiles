#!/usr/bin/env bash
# Run `rumdl check --fix` after Write/Edit on .md files.
# Usage: md_format.sh   (PostToolUse hook; reads the hook JSON on stdin)
# Output: nothing on success.
#
# Was an inline one-liner in .claude/settings.json until 2026-09-22. It grew
# three guards, and a guard whose reason cannot be written down next to it is a
# guard the next person deletes.
set -uo pipefail

# The edited path arrives in the hook's stdin JSON, NOT an environment variable.
# There is no CLAUDE_FILE_PATH — see shellcheck_lint.sh for the full note.
file="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)"

[[ "${file}" == *.md ]] || exit 0
[[ -f "${file}" ]] || exit 0

# GUARD 1 — never format inside the Obsidian vault.
#
# Obsidian files are not plain markdown: plugins assign meaning to whitespace
# and to link syntax that a generic formatter is free to normalise away. On
# 2026-09-22 this hook broke the kanban board two ways at once — it collapsed
# the DOUBLE blank lines the Kanban plugin uses as lane delimiters down to one,
# so Obsidian stopped parsing lanes at all, and it rewrote a bare URL in a card
# to angle-bracket form. Both are legal markdown. Both are wrong here.
#
# This is NOT tunable by disabling rules the way MD018/MD019 were (see
# ../../.config/rumdl/rumdl.toml): the vault's contract is structural, so the
# whole path is out of scope rather than a rule subset.
#
# RESOLVE FIRST. The board is normally reached through a symlink —
# ~/projects/planning/TODO/TODO.md -> ~/Library/Mobile Documents/iCloud~md~obsidian/…
# so matching the literal argument would miss every real edit. Fall back to the
# raw path if readlink fails (it only fails when the file is gone, and the -f
# test above already covers that).
resolved="$(readlink -f "${file}" 2>/dev/null || printf '%s' "${file}")"
case "${resolved}" in
*"iCloud~md~obsidian"*) exit 0 ;;
esac

# GUARD 2 — never format a file carrying git conflict markers. A markdown
# formatter reads `=======` as a setext heading underline and `|||||||` as
# text, rewrites them into headings, and the heading-increment rule then
# cascades DEMOTIONS through every heading below — silently destroying a
# conflict resolution in progress. Observed 2026-09-21 on dispatch CLAUDE.md:
# `||||||| a2d0347` became `## ||||||| a2d0347` and demoted six sections under
# it. Skipping is always safe; the file gets formatted on the next write once
# the merge is resolved.
grep -qE '^(<<<<<<<|=======|>>>>>>>|\|\|\|\|\|\|\|)' "${file}" 2>/dev/null && exit 0

rumdl check --fix "${file}" >/dev/null 2>&1 || true
