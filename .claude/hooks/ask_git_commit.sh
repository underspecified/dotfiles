#!/bin/bash
# Wrapper for git commit that requires user approval via Claude hook
# Usage: ask_git_commit.sh [-C <dir>] -m "commit message"
#
# This script is a passthrough to git commit. The actual permission
# check happens in the Claude hook (git_gate.sh) which detects this
# script and triggers an "ask" permission flow.
#
# -C <dir>  Optional: pass a working directory to git (same as git -C).

DIR_ARGS=()
if [[ "${1:-}" == "-C" && -n "${2:-}" ]]; then
  DIR_ARGS=("-C" "$2")
  shift 2
fi

exec git "${DIR_ARGS[@]}" commit "$@"
