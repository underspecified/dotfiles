#!/usr/bin/env bash
# Usage: bash ~/.claude/patches/bootstrap.sh [--quiet]
# Apply all local plugin patches idempotently. Safe to re-run.
#
# Claude Code runs a plugin from its INSTALLED copy
# (plugins/cache/<marketplace>/<plugin>/<version>, listed in
# installed_plugins.json), not from the marketplace checkout, and a plugin
# update installs a fresh, unpatched copy. So every installed copy is patched,
# and settings.json runs this at SessionStart with --quiet to re-patch after
# an update. --quiet prints only failures and always exits 0.
set -uo pipefail

PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS="${HOME}/.claude/plugins"
QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

# Patch registry: "<patch-filename>|<plugin@marketplace>". Each patch uses -p1
# paths rooted at the plugin directory.
PATCHES=(
  "hookify-global-rules.patch|hookify@claude-plugins-official"
  "hookify-model-messages.patch|hookify@claude-plugins-official"
)

say() { [[ "${QUIET}" -eq 1 ]] || echo "$*"; }

# Print every directory holding a copy of the plugin: the installed copies,
# then the marketplace checkout if present.
plugin_dirs() {
  local key="$1" name="${1%@*}" market="${1#*@}"
  if command -v jq >/dev/null 2>&1 && [[ -f "${PLUGINS}/installed_plugins.json" ]]; then
    jq -r --arg k "${key}" '[.plugins[$k][]?.installPath] | unique[]' "${PLUGINS}/installed_plugins.json"
  fi
  echo "${PLUGINS}/marketplaces/${market}/plugins/${name}"
}

apply_one() {
  local patch_path="$1" dir="$2"
  [[ -d "${dir}" ]] || return 0
  if patch -d "${dir}" -p1 -R --dry-run -s -f <"${patch_path}" >/dev/null 2>&1; then
    say "ok (already applied): ${dir}"
    return 0
  fi
  if ! patch -d "${dir}" -p1 --dry-run -s -f <"${patch_path}" >/dev/null 2>&1; then
    echo "plugin patch $(basename "${patch_path}") does not apply to ${dir} (plugin updated? refresh the patch)"
    return 1
  fi
  if ! patch -d "${dir}" -p1 -s -f <"${patch_path}" >/dev/null 2>&1; then
    echo "plugin patch $(basename "${patch_path}") failed to apply to ${dir}"
    return 1
  fi
  say "applied: ${dir}"
}

main() {
  say "=== Applying plugin patches from ${PATCH_DIR} ==="
  local failed=0 entry patch_file key dir
  for entry in "${PATCHES[@]}"; do
    patch_file="${entry%%|*}"
    key="${entry##*|}"
    while IFS= read -r dir; do
      [[ -n "${dir}" ]] || continue
      apply_one "${PATCH_DIR}/${patch_file}" "${dir}" || failed=1
    done < <(plugin_dirs "${key}")
  done
  if [[ "${failed}" -ne 0 ]]; then
    [[ "${QUIET}" -eq 1 ]] && exit 0
    echo "=== Some patches failed ===" >&2
    exit 1
  fi
  say "=== All patches applied ==="
}

main "$@"
