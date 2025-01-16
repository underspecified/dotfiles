#!/bin/bash

CUR_DIR=$(dirname $0)
PATH="$CUR_DIR:$PATH"

heliocron_here.sh wait --event sunset --run-missed-event "$@" &&
change_theme.sh dark
