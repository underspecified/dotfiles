#!/usr/bin/env bash
# Usage: bash ~/.claude/skills/bootstrap.sh
# Clones all skill repos and creates sub-skill symlinks.
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
GITHUB_ORG="underspecified"

mkdir -p "${SKILLS_DIR}"

# Standalone skills
STANDALONE=(computation-graph figure gantt-chart hansei meeting presentation sync-latex travel)
for skill in "${STANDALONE[@]}"; do
    if [[ ! -d "${SKILLS_DIR}/${skill}" ]]; then
        echo "Cloning skill: ${skill}"
        gh repo clone "${GITHUB_ORG}/${skill}" "${SKILLS_DIR}/${skill}"
    fi
done

# Research (composite: clone + symlink sub-skills)
if [[ ! -d "${SKILLS_DIR}/research" ]]; then
    echo "Cloning skill: research"
    gh repo clone "${GITHUB_ORG}/research" "${SKILLS_DIR}/research"
fi
for sub in "${SKILLS_DIR}/research/skills"/*/; do
    name=$(basename "${sub}")
    [[ -f "${sub}/SKILL.md" ]] || continue
    ln -sfn "research/skills/${name}" "${SKILLS_DIR}/${name}"
done

# Planning (composite: clone + symlink sub-skills)
if [[ ! -d "${SKILLS_DIR}/planning" ]]; then
    echo "Cloning skill: planning"
    gh repo clone "${GITHUB_ORG}/planning" "${SKILLS_DIR}/planning"
fi
for sub in "${SKILLS_DIR}/planning/skills"/*/; do
    name=$(basename "${sub}")
    [[ -f "${sub}/SKILL.md" ]] || continue
    ln -sfn "planning/skills/${name}" "${SKILLS_DIR}/${name}"
done

echo "=== Skills bootstrap complete ==="
