#!/usr/bin/env bash
# Usage: bash ~/.claude/skills/bootstrap.sh [--doctor]
# Clones all skill repos (or fast-forward-updates existing clones) and
# creates sub-skill symlinks for composite skills. Safe to re-run.
#
# --doctor: check only. Asserts every deploy tree is on main, clean, and in
#           sync with origin. Writes nothing; exits 1 if any repo fails.
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
GITHUB_ORG="underspecified"

# Standalone skills (one repo = one skill)
STANDALONE=(computation-graph dispatch email-inbox figure gantt-chart meeting travel)

# Composite skills (one repo, multiple sub-skills at <repo>/skills/<name>/)
COMPOSITES=(
    research
    paper         # manuscript authoring: /paper-plan, /paper-prosify, /paper-sync, ...
    planning
    kaiseki       # /hansei, /nikki under here
    presentation  # /presentation + /presentation-plan (narrative interview)
)

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

# Composite skills get a top-level symlink ~/.claude/skills/<name> per
# sub-skill so /<name> works without harness changes.
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
        # Skip the eponymous sub-skill: when sub_name == name, the link
        # target ${SKILLS_DIR}/${sub_name} IS the repo directory, and
        # `ln -sfn` with a real-dir destination NESTS the link inside it
        # (creates ${SKILLS_DIR}/<name>/<name> as a broken symlink to
        # <name>/skills/<name>) instead of replacing. The eponymous skill
        # remains discoverable via ${name}/skills/${name}/SKILL.md, so we
        # don't need the top-level symlink for it.
        if [[ "${sub_name}" == "${name}" ]]; then
            continue
        fi
        ln -sfn "${name}/skills/${sub_name}" "${SKILLS_DIR}/${sub_name}"
    done
}

# ── doctor ───────────────────────────────────────────────────────────────────
#
# A deploy tree is what every session actually executes: SKILL.md is read from
# here, and ~/.local/bin entry points symlink into here. So "what is checked
# out" IS "what is running, everywhere, right now". Drift is silent by
# construction — a repo left on a feature branch keeps working until the branch
# is deleted. Found exactly that on dispatch during the #133 review, by accident.
#
# Checks the invariant that holds under any layout (plain clone or worktree):
# on main, clean, in sync. Read-only.
doctor_repo() {
    local dir="$1" name; name="$(basename "${dir}")"
    local -a problems=() notes=()

    if [[ ! -d "${dir}" ]]; then
        printf '  %-16s MISSING (run without --doctor to clone)\n' "${name}"
        return 1
    fi
    if ! git -C "${dir}" rev-parse --git-dir >/dev/null 2>&1; then
        printf '  %-16s NOT A GIT REPO\n' "${name}"
        return 1
    fi

    local branch
    if branch="$(git -C "${dir}" symbolic-ref --quiet --short HEAD 2>/dev/null)"; then
        [[ "${branch}" == "main" ]] || problems+=("on '${branch}', not main")
    else
        problems+=("detached HEAD")
    fi

    [[ -z "$(git -C "${dir}" status --porcelain)" ]] || problems+=("dirty working tree")

    # A repo with no remote (local-only, e.g. paper) can't be ahead or behind.
    if git -C "${dir}" remote | grep -q .; then
        local counts ahead behind
        if counts="$(git -C "${dir}" rev-list --left-right --count 'HEAD...@{upstream}' 2>/dev/null)"; then
            ahead="${counts%%[[:space:]]*}"
            behind="${counts##*[[:space:]]}"
            [[ "${behind}" -eq 0 ]] || problems+=("${behind} behind origin")
            [[ "${ahead}" -eq 0 ]] || notes+=("${ahead} unpushed")
        else
            notes+=("no upstream tracking branch")
        fi
    else
        notes+=("local-only, no remote")
    fi

    local suffix=""
    [[ ${#notes[@]} -eq 0 ]] || suffix=" (${notes[*]})"

    if [[ ${#problems[@]} -eq 0 ]]; then
        printf '  %-16s ok%s\n' "${name}" "${suffix}"
        return 0
    fi
    printf '  %-16s FAIL: %s%s\n' "${name}" "$(IFS='; '; echo "${problems[*]}")" "${suffix}"
    return 1
}

run_doctor() {
    local failed=0
    echo "=== Skill deploy trees (${SKILLS_DIR}) ==="
    for skill in "${STANDALONE[@]}" "${COMPOSITES[@]}"; do
        doctor_repo "${SKILLS_DIR}/${skill}" || failed=1
    done
    echo
    if [[ "${failed}" -eq 0 ]]; then
        echo "=== All deploy trees on main, clean, in sync ==="
    else
        echo "=== Drift found. A deploy tree off main is live code nobody reviewed. ===" >&2
    fi
    return "${failed}"
}

# ── main ─────────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--doctor" ]]; then
    run_doctor
    exit $?
fi

mkdir -p "${SKILLS_DIR}"

for skill in "${STANDALONE[@]}"; do
    if [[ ! -d "${SKILLS_DIR}/${skill}" ]]; then
        echo "Cloning skill: ${skill}"
        gh repo clone "${GITHUB_ORG}/${skill}" "${SKILLS_DIR}/${skill}"
    else
        echo "Updating skill: ${skill}"
        update_skill "${SKILLS_DIR}/${skill}"
    fi
done

for skill in "${COMPOSITES[@]}"; do
    install_composite "${skill}"
done

echo "=== Skills bootstrap complete ==="
echo
run_doctor || true
