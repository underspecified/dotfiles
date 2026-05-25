#!/usr/bin/env bash
# Usage: bash ~/.config/lnk/installers/nosudo/install.sh
#
# Headless / no-sudo bootstrap. Sibling of installers/linux/install.sh,
# intended for dev hosts where:
#   - sudo is not available (shared servers, containers, CI runners)
#   - and/or there is no display (headless boxes, login shells over ssh)
#
# Dispatched from ../../bootstrap.sh when LNK_HOST=nosudo is set, or as
# an auto-fallback when `sudo -n true` fails on Linux. Also safe to run
# directly:  bash ~/.config/lnk/installers/nosudo/install.sh
#
# Scope (deliberately narrow vs. installers/linux/install.sh):
#   * No apt / no sudo: the baseline (git/curl/wget/jq/tmux/zsh) must
#     already be on the box. We only verify, never install.
#   * No display assumed: kitty still gets installed (it's a user-space
#     curl-pipe) because it's useful as a remote-side terminfo target
#     for `kitten ssh`, but we don't drive any GUI from here.
#   * User-space tools only, all under ~/.local: uv, claude, gh, btop,
#     nvtop, gpu-burn, kitty, shellcheck, shfmt, node, trash-cli. Then
#     runs ~/.claude/bootstrap.sh.
#   * Per-step delegation: each tool lives in its own installers/nosudo/
#     install_<tool>.sh -- so you can re-run a single piece for debug
#     (e.g. `bash installers/nosudo/install_node.sh`).
#
# Idempotent: every step either skips when the target is already in
# place or upgrades to the latest user-space build. Safe to re-run.
set -euo pipefail

# shellcheck source=SCRIPTDIR/../lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib.sh"

CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALL_DIR="${CUR_DIR}/../all"
LINUX_DIR="${CUR_DIR}/../linux"
LOCAL_PREFIX="${LOCAL_PREFIX:-${HOME}/.local}"

check_preconditions() {
  [[ "$(uname -s)" == "Linux" ]] || die "nosudo/install.sh is Linux-only"

  # The baseline tools are assumed to be provided by the host distro
  # (or the user/admin) since we cannot install via apt. Fail fast and
  # loud if any are missing -- partial bootstraps are worse than none.
  local missing=()
  local tool
  for tool in git curl wget jq tar; do
    command -v "${tool}" >/dev/null 2>&1 || missing+=("${tool}")
  done
  if (( ${#missing[@]} > 0 )); then
    die "missing required base tools (no sudo available to install them): ${missing[*]}"
  fi

  # Soft warnings -- nice to have but not required to make progress.
  for tool in zsh tmux make g++; do
    command -v "${tool}" >/dev/null 2>&1 \
      || warn "${tool} not found -- some downstream features will be unavailable"
  done

  command -v lnk >/dev/null 2>&1 \
    || warn "lnk not on PATH -- fine for initial bootstrap, but lnk pull / status will be unavailable"

  mkdir -p "${LOCAL_PREFIX}/bin"
  case ":${PATH}:" in
    *":${LOCAL_PREFIX}/bin:"*) ;;
    *) warn "${LOCAL_PREFIX}/bin is not on PATH -- newly installed tools won't be found until your next shell" ;;
  esac
}

run_step() {
  # Run an installer step. Failure warns but does not abort (each step
  # is independent; we want maximum coverage even if one fails).
  local script="$1"
  local label="${2:-$(basename "${script}")}"
  log "  ${label}"
  if [[ -f "${script}" ]]; then
    bash "${script}" || warn "failed: ${label}"
  else
    warn "skipping ${label}: ${script} not found"
  fi
}

run_user_installers() {
  log "Running user-space installers"
  # Order:
  #   1. uv first -- subsequent steps (trash-cli, btop_install_node helpers) use it.
  #   2. claude code -- needed before claude bootstrap runs.
  #   3. tooling tarballs (gh, shellcheck, shfmt) -- pure downloads, fast.
  #   4. node -- before claude bootstrap (statusline npm build needs npm).
  #   5. trash-cli -- needs uv on PATH.
  #   6. kitty -- terminfo + binary for kitten ssh, no display required.
  #   7. heavyweight builds (btop, nvtop, gpu-burn) -- last because they
  #      take the longest and self-skip when their preconds aren't met.
  run_step "${LINUX_DIR}/install_uv.sh"
  run_step "${ALL_DIR}/install_claude_code.sh"
  run_step "${CUR_DIR}/install_gh.sh"          "gh (prebuilt tarball)"
  run_step "${CUR_DIR}/install_shellcheck.sh"  "shellcheck (prebuilt tarball -- required by .claude shellcheck_lint hook)"
  run_step "${CUR_DIR}/install_shfmt.sh"       "shfmt (prebuilt binary -- required by .claude shellcheck_lint hook)"
  run_step "${CUR_DIR}/install_node.sh"        "node + npm (Node LTS tarball -- required by .claude statusline build)"
  run_step "${CUR_DIR}/install_trash.sh"       "trash-cli (uv tool -- required by .claude block-rm hook)"
  run_step "${CUR_DIR}/install_kitty.sh"       "kitty (upstream installer -- user-space)"
  run_step "${CUR_DIR}/install_btop.sh"        "btop (v1.3.2 pin -- C++20 + GPU support)"
  run_step "${CUR_DIR}/install_nvtop.sh"       "nvtop (NVIDIA-only build -- self-skips when no GPU)"
  run_step "${CUR_DIR}/install_gpu_burn.sh"    "gpu-burn (self-skips when no nvcc)"
}

run_claude_bootstrap() {
  # ~/.claude/bootstrap.sh chains the per-area scripts (statusline, skills,
  # MCP, patches). Safe to re-run -- each child handles missing-vs-existing
  # state on its own. Identical hook to installers/linux/install.sh.
  local script="${HOME}/.claude/bootstrap.sh"
  if [[ ! -e "${script}" ]]; then
    warn "skipping Claude bootstrap: ${script} not found (lnk symlinks restored?)"
    return
  fi
  log "Running Claude bootstrap (statusline, skills, MCP, patches)"
  bash "${script}" || warn "Claude bootstrap had failures (continuing)"
}

print_summary() {
  cat <<EOF

  ──────────────────────────────────────────────────────────────
  nosudo bootstrap complete on $(hostname).

  Verify:
    command -v uv claude gh btop nvtop kitty trash shellcheck shfmt node npm
    ls ~/git/gpu-burn/gpu_burn 2>/dev/null
    lnk status

  If ${LOCAL_PREFIX}/bin is not yet on PATH for this session,
  start a fresh shell or:
    export PATH="${LOCAL_PREFIX}/bin:\$PATH"

  Host-specific files (if any) live in ~/.config/lnk/.lnk.nosudo.
  Add more with:  lnk add --host nosudo <file>
  ──────────────────────────────────────────────────────────────
EOF
}

main() {
  check_preconditions
  run_user_installers
  run_claude_bootstrap
  print_summary
}

main "$@"
