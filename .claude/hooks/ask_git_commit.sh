#!/bin/bash
# Wrapper for git commit that requires user approval via Claude hook
# Usage: ask_git_commit.sh -m "commit message"
#
# This script is a passthrough to git commit. The actual permission
# check happens in the Claude hook (nag_docs.sh) which detects this
# script and triggers an "ask" permission flow.

exec git commit "$@"
