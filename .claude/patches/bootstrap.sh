#!/usr/bin/env bash
# Usage: bash ~/.claude/patches/bootstrap.sh
# Apply all local plugin patches idempotently. Safe to re-run.
set -euo pipefail

PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_ROOT="${HOME}/.claude/plugins/marketplaces"

# Patch registry: "<patch-filename>|<target-dir-relative-to-PLUGINS_ROOT>"
# Each target dir is passed to `patch -d`; the patch itself uses -p1 paths
# rooted at that directory.
PATCHES=(
  "hookify-global-rules.patch|claude-plugins-official/plugins/hookify"
)

apply_one() {
  local patch_file="$1"
  local target_dir="$2"
  local patch_path="${PATCH_DIR}/${patch_file}"
  local abs_target="${PLUGINS_ROOT}/${target_dir}"

  if [[ ! -f "${patch_path}" ]]; then
    echo "error: patch file not found: ${patch_path}" >&2
    return 1
  fi

  if [[ ! -d "${abs_target}" ]]; then
    echo "skip: target plugin not installed: ${target_dir}" >&2
    return 0
  fi

  # Already applied? Reverse dry-run succeeds if patch is in place.
  if patch -d "${abs_target}" -p1 -R --dry-run -s -f <"${patch_path}" >/dev/null 2>&1; then
    echo "ok (already applied): ${patch_file}"
    return 0
  fi

  # Not applied yet — verify a forward apply would succeed before doing it.
  if ! patch -d "${abs_target}" -p1 --dry-run -s -f <"${patch_path}" >/dev/null 2>&1; then
    echo "error: ${patch_file} does not apply cleanly to ${target_dir}" >&2
    echo "       (plugin may have been updated; patch needs a refresh)" >&2
    return 1
  fi

  patch -d "${abs_target}" -p1 -s <"${patch_path}"
  echo "applied: ${patch_file}"
}

main() {
  echo "=== Applying plugin patches from ${PATCH_DIR} ==="
  local failed=0
  local entry patch_file target_dir
  for entry in "${PATCHES[@]}"; do
    patch_file="${entry%%|*}"
    target_dir="${entry##*|}"
    if ! apply_one "${patch_file}" "${target_dir}"; then
      failed=1
    fi
  done

  if [[ "${failed}" -ne 0 ]]; then
    echo "=== Some patches failed ===" >&2
    exit 1
  fi
  echo "=== All patches applied ==="
}

main "$@"
