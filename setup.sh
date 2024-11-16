#!/bin/bash

function echo_and_eval {
    if [ "x$DEBUG" == "x" ]; then
        echo "#$@"
        eval $@
    else
        echo $@
    fi
}

for f in dot.*; do
    echo_and_eval "ln -sf \"$PWD/$f\" \"$HOME/${f/dot./.}\""
done

mkdir -p $HOME/.config
(cd config/;
for f in *; do
    echo_and_eval "ln -sf \"$PWD/$f\" \"$HOME/.config/$f\""
done)

echo_and_eval "(cd dot.ssh && chmod go-rwX github github hri_jp)"
echo_and_eval "ln -sf $HOME/.zsh/dot.zshrc $HOME/.zshrc"
