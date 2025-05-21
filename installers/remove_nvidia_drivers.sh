#!/bash/bin

echo_and_eval () {
    echo "$@"
    eval "$@"
}

remove_cuda () {
    dpkg -l |
    grep -i cuda |
    cut -d' ' -f3 |
    xargs sudo apt-get purge -y
}

remove_nvidia_driver () {
    dpkg -l |
    grep -i nvidia |
    cut -d' ' -f3 |
    xargs sudo apt-get purge -y
}

remove_cuda
remove_nvidia_driver
