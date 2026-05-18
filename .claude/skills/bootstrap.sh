#!/usr/bin/env bash
# Usage: bash ~/.claude/skills/bootstrap.sh
# Clones all skill repos (or fast-forward-updates existing clones) and
# creates sub-skill symlinks for composite skills. Safe to re-run.
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
GITHUB_ORG="underspecified"

mkdir -p "${SKILLS_DIR}"

# Pull an existing skill repo, but only if the working tree is clean and
# we're on a branch (not detached). Skips loudly otherwise so local WIP
# is never trampled. --ff-only refuses to auto-merge divergent histories.
update_skill() {
    local dir="$1" name; name="$(basename "${dir}")"
    if [[ -n "$(git -C "${dir}" status --porcelain)" ]]; then
        echo "  skip ${name}: dirty working tree"
        return 0
    fi
    if ! git -C "${dir}" symbolic-ref --quiet HEAD >/dev/null; then
        echo "  skip ${name}: detached HEAD"
        return 0
    fi
    if ! git -C "${dir}" pull --ff-only --quiet; then
        echo "  pull failed: ${name} (likely diverged from origin)" >&2
    fi
}

# Standalone skills (one repo = one skill)
STANDALONE=(computation-graph dispatch figure gantt-chart meeting presentation sync-latex travel)
for skill in "${STANDALONE[@]}"; do
    if [[ ! -d "${SKILLS_DIR}/${skill}" ]]; then
        echo "Cloning skill: ${skill}"
        gh repo clone "${GITHUB_ORG}/${skill}" "${SKILLS_DIR}/${skill}"
    else
        echo "Updating skill: ${skill}"
        update_skill "${SKILLS_DIR}/${skill}"
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
    else
        echo "Updating composite skill: ${name}"
        update_skill "${SKILLS_DIR}/${name}"
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
