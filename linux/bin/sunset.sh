#!/bin/bash

CUR_DIR=$(dirname $0)
. "$CUR_DIR/util.sh"

/home/eric/.cargo/bin/heliocron wait --event sunset --run-missed-event "$@" &&
"$CUR_DIR/change_theme.sh" dark
