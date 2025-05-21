#!/bin/bash

case "$1" in
    dark)
        mode="dark"
        ;;
    light)
        mode="light"
        ;;
    *)
	;;
esac


[[ -n $mode ]] && darkman set $mode || darkman toggle
