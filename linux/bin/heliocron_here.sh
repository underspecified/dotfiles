#!/bin/bash

PATH="/home/eric/.cargo/bin:$PATH"

CUR_DIR=$(dirname $0)
. "$CUR_DIR/util.sh"

lat=$(get_lat)
lng=$(get_lng)

heliocron --latitude $lat --longitude $lng "$@"
