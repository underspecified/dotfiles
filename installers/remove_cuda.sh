#!/bash/bin

echo_and_eval () {
    echo "$@"
    eval "$@"
}

remove_cuda () {
    dpkg -l |
    grep -i cuda |
    cut -d' ' -f3 |
    xargs echo sudo apt-get purge
}

remove_cuda
