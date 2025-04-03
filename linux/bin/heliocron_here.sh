#!/bin/bash

CUR_DIR=$(dirname $0)
. "$CUR_DIR/util.sh"

lat=$(get_lat)
lng=$(get_lng)

echo_and_eval "$HOME/.cargo/bin/heliocron --latitude $lat --longitude $lng $@"
