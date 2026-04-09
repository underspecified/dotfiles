#!/bin/bash
# Pre-commit hook: Enforce doc check workflow
# - git commit → ASK with doc review instructions (user rejects if not followed)
# - ask_git_commit.sh → ASK for final user approval

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Strip heredoc bodies and quoted strings so embedded text like
# "Analyze git commit history" inside a heredoc doesn't false-positive.
# Keep only the shell command portion (first line, up to any << delimiter).
CMD_LINE=$(echo "$COMMAND" | head -1 | sed 's/<<.*//')

# Find documentation files in the current repo
find_docs() {
    DOCS=""
    [[ -f "CLAUDE.md" ]] && DOCS="$DOCS CLAUDE.md"
    [[ -f "README.md" ]] && DOCS="$DOCS README.md"
    [[ -f "CONTRIBUTING.md" ]] && DOCS="$DOCS CONTRIBUTING.md"
    [[ -f "CHANGELOG.md" ]] && DOCS="$DOCS CHANGELOG.md"
    echo "$DOCS"
}

# Check if this is the approved commit wrapper script
if [[ "$COMMAND" =~ ask_git_commit\.sh ]]; then
    DOCS=$(find_docs)
    jq -n --arg docs "$DOCS" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "ask",
            permissionDecisionReason: ("📝 Approve commit? Docs should be verified:" + $docs)
        }
    }'
    exit 0
fi

# Check if this is a direct git commit command (requires doc review first)
if [[ "$CMD_LINE" =~ ^git[[:space:]]+commit ]] || [[ "$CMD_LINE" =~ [[:space:]]git[[:space:]]+commit ]] || [[ "$CMD_LINE" =~ \&\&[[:space:]]*git[[:space:]]+commit ]] || [[ "$CMD_LINE" =~ \;[[:space:]]*git[[:space:]]+commit ]]; then
    DOCS=$(find_docs)
    if [[ -n "$DOCS" ]]; then
        # Build the instruction message
        MSG="⚠️ Doc review required!

1. Read:$DOCS
2. Update docs if changes affect: structure, scripts, deps, interfaces
3. Tell user what you checked/updated
4. Stage doc changes
5. Use: ~/.claude/hooks/ask_git_commit.sh -m \"message\""

        # Return deny with reason
        jq -n --arg msg "$MSG" '{
            hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: $msg
            }
        }'
        exit 0
    fi
fi

# Allow all other commands
exit 0
