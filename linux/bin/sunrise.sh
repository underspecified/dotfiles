#!/bin/bash

CUR_DIR=$(dirname $0)
. "$CUR_DIR/util.sh"

heliocron_here wait --event sunrise --run-missed-event "$@" &&
"$CUR_DIR/change_theme.sh" light
