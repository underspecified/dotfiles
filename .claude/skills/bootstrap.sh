#!/usr/bin/env bash
# Usage: bash ~/.claude/skills/bootstrap.sh
# Clones all skill repos and creates sub-skill symlinks for composite skills.
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
GITHUB_ORG="underspecified"

mkdir -p "${SKILLS_DIR}"

# Standalone skills (one repo = one skill)
STANDALONE=(computation-graph dispatch figure gantt-chart meeting presentation sync-latex travel)
for skill in "${STANDALONE[@]}"; do
    if [[ ! -d "${SKILLS_DIR}/${skill}" ]]; then
        echo "Cloning skill: ${skill}"
        gh repo clone "${GITHUB_ORG}/${skill}" "${SKILLS_DIR}/${skill}"
    fi
done

# Composite skills (one repo, multiple sub-skills at <repo>/skills/<name>/)
# Each sub-skill gets a top-level symlink ~/.claude/skills/<name> so /<name>
# works without harness changes.
install_composite() {
    local name="$1"
    if [[ ! -d "${SKILLS_DIR}/${name}" ]]; then
        echo "Cloning composite skill: ${name}"
        gh repo clone "${GITHUB_ORG}/${name}" "${SKILLS_DIR}/${name}"
    fi
    for sub in "${SKILLS_DIR}/${name}/skills"/*/; do
        [[ -f "${sub}SKILL.md" ]] || continue
        local sub_name
        sub_name=$(basename "${sub}")
        ln -sfn "${name}/skills/${sub_name}" "${SKILLS_DIR}/${sub_name}"
    done
}

install_composite research
install_composite planning
install_composite kaiseki   # /hansei, /nikki under here

echo "=== Skills bootstrap complete ==="
