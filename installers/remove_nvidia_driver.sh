#!/bash/bin

echo_and_eval () {
    echo "$@"
    eval "$@"
}

remove_nvidia_driver () {
    dpkg -l |
    grep -i nvidia |
    cut -d' ' -f3 |
    xargs echo sudo apt-get purge
}

remove_nvidia_driver
