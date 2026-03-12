#!/usr/bin/env bash
# Usage: bash ~/.config/lnk/.claude/bootstrap.sh
# Run after `lnk pull` on a new machine to set up Claude Code runtime deps.
set -euo pipefail

echo "=== Claude Code bootstrap ==="

# Status line fork
if [[ ! -d ~/.claude/claude-limitline-fork ]]; then
    echo "Cloning claude-limitline fork..."
    git clone https://github.com/tylergraydev/claude-limitline.git \
        ~/.claude/claude-limitline-fork
    cd ~/.claude/claude-limitline-fork && npm install && npm run build
fi

# Skills directory
mkdir -p ~/.claude/skills ~/claude/skills

# Standalone skills
STANDALONE_SKILLS=(computation-graph gantt-chart hansei presentation sync-latex travel)
for skill in "${STANDALONE_SKILLS[@]}"; do
    if [[ ! -d ~/claude/skills/$skill ]]; then
        echo "Cloning skill: $skill"
        gh repo clone "underspecified/$skill" ~/claude/skills/$skill
    fi
    ln -sfn ~/claude/skills/$skill ~/.claude/skills/$skill
done

# Research skill + sub-skills
if [[ ! -d ~/claude/skills/research ]]; then
    echo "Cloning skill: research"
    gh repo clone "underspecified/research" ~/claude/skills/research
fi
ln -sfn ~/claude/skills/research/skills/research ~/.claude/skills/research
for skill in ~/claude/skills/research/skills/*/; do
    name=$(basename "$skill")
    ln -sfn "$skill" ~/.claude/skills/$name
done

# MCP servers (optional)
mkdir -p ~/claude/mcp
if [[ ! -d ~/claude/mcp/google_workspace_mcp ]]; then
    gh repo clone taylorwilsdon/google_workspace_mcp ~/claude/mcp/google_workspace_mcp || true
fi
if [[ ! -d ~/claude/mcp/paper-search-mcp ]]; then
    gh repo clone openags/paper-search-mcp ~/claude/mcp/paper-search-mcp || true
fi

echo "=== Done ==="
