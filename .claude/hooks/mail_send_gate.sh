#!/usr/bin/env bash
# Usage: PreToolUse hook (stdin: hook JSON), matcher
#   mcp__apple-mail-patrickfreyer__(compose_email|manage_drafts)
# Output: an "ask" permission decision when the call would send mail
# immediately; nothing (allow normal flow) for draft/open/list calls.
# Why: compose_email defaults to mode "send" and manage_drafts can send a
# draft, so a prompt-injected email could otherwise send mail with no human
# check. Fails closed: input it can't parse also asks.
set -uo pipefail

input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"${input}" 2>/dev/null || true)"
reason="Mail send gate couldn't read this call. Confirm it before it runs."

case "${tool}" in
*__compose_email)
  mode="$(jq -r '.tool_input.mode // "send"' <<<"${input}")"
  [[ "${mode}" == "open" || "${mode}" == "draft" ]] && exit 0
  reason="compose_email would send immediately (mode: ${mode}). Confirm this send, or use mode \"open\" for a draft."
  ;;
*__manage_drafts)
  action="$(jq -r '.tool_input.action // empty' <<<"${input}")"
  [[ "${action}" != "send" ]] && exit 0
  reason="manage_drafts would send a draft. Confirm this send, or use action \"open\" to review it first."
  ;;
esac

jq -n --arg r "${reason}" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
