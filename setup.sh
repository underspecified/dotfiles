#!/usr/bin/env bash
# Legacy symlink installer. Prefer `lnk` (the Git-native dotfiles manager)
# instead -- this script remains only for reference / older machines.
set -euo pipefail

# Print the command being run, then run it.
run() {
    if [[ -z "${DEBUG:-}" ]]; then
        printf '# %s\n' "$*"
        "$@"
    else
        printf '%s\n' "$*"
    fi
}

for f in dot.*; do
    run ln -sf "${PWD}/${f}" "${HOME}/${f/dot./.}"
done

mkdir -p "${HOME}/.config"
(
    cd config/ || exit 1
    for f in *; do
        run ln -sf "${PWD}/${f}" "${HOME}/.config/${f}"
    done
)

mkdir -p "${HOME}/.local/share"
(
    cd local/share/ || exit 1
    for f in *; do
        run ln -sf "${PWD}/${f}" "${HOME}/.config/${f}"
    done
)

(
    cd dot.ssh || exit 1
    chmod go-rwX github github hri_jp
)
run ln -sf "${HOME}/.zsh/dot.zshenv" "${HOME}/.zshenv"
run ln -sf "${HOME}/.zsh/dot.zshrc" "${HOME}/.zshrc"
