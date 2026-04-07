#!/bin/bash
# PreToolUse hook: Block pip/pipx, enforce uv
# Denies pip and pipx commands, directing agents to use uv instead.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Strip heredoc bodies and quoted strings
CMD_LINE=$(echo "$COMMAND" | head -1 | sed 's/<<.*//')

# Allow uv-prefixed commands (uv pip, uv run python, etc.)
if [[ "$CMD_LINE" =~ (^|[[:space:]]|&&|;)uv[[:space:]] ]] || \
   [[ "$CMD_LINE" =~ (^|[[:space:]]|&&|;)uvx[[:space:]] ]]; then
    exit 0
fi

# Check for pip or pipx commands (standalone or chained)
if [[ "$CMD_LINE" =~ (^|[[:space:]]|&&|;)pip[[:space:]] ]] || \
   [[ "$CMD_LINE" =~ (^|[[:space:]]|&&|;)pip3[[:space:]] ]] || \
   [[ "$CMD_LINE" =~ (^|[[:space:]]|&&|;)pipx[[:space:]] ]]; then
    MSG="🚫 pip/pipx is not allowed. Use uv instead:
- Install packages: uv pip install <pkg>
- Add to script: uv add --script <script.py> <pkg>
- Run with deps: uv run --with <pkg> <script.py>
- Install CLI tools: uv tool install <pkg>
- Run CLI tools once: uvx <pkg>
- Create venv: uv venv"

    jq -n --arg msg "$MSG" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $msg
        }
    }'
    exit 0
fi

# Check for python/python3 direct invocation (should use uv run)
if [[ "$CMD_LINE" =~ (^|[[:space:]]|&&|;)python3?[[:space:]] ]]; then
    MSG="🚫 Direct python/python3 is not allowed. Use uv instead:
- Run script: uv run script.py
- Run with deps: uv run --with <pkg> script.py
- Run module: uv run -m <module>"

    jq -n --arg msg "$MSG" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $msg
        }
    }'
    exit 0
fi

# Allow all other commands
exit 0
