#!/bin/bash

case "$1" in
    dark)
        mode="dark"
        ;;
    light)
        mode="light"
        ;;
    *)
        mode="toggle"
    ;;
esac

darkman $mode
