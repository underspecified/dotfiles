#!/bin/bash

CUR_DIR=$(dirname $0)
. "$CUR_DIR/util.sh"

bash "$CUR_DIR/heliocron_here.sh" wait --event sunset --run-missed-event &&
bash "$CUR_DIR/change_theme.sh" dark
