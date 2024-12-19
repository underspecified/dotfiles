#!/bin/bash

CUR_DIR=$(dirname $0)

get_os () {
    case $(uname) in
        "Darwin") echo "macos" ;;
        "Linux") echo "linux" ;;
        *) echo "unknown" ;;
    esac
}

os=$(get_os)
if [[ "$os" == "macos" ]]; then
    bash $CUR_DIR/toggle_macos.sh
elif [[ "$os" == "linux" ]]; then
    bash $CUR_DIR/toggle_linux.sh
fi
