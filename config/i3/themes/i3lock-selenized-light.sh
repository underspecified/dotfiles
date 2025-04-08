#!/bin/sh
# i3lock-solarized is licensed under the MIT License Copyright (c) 2020 Parsiad Azimzadeh

CURDIR=$(dirname $0)

alpha="dd"
bg_0="fbf3db"
bg_1="ece3cc"
bg_2="d5cdb6"
dim_0="909995"
fg_0="53676d"
fg_1="3a4d53"

red="d2212d"
green="489100"
yellow="ad8900"
blue="0072d4"
magenta="ca4898"
cyan="009c8f"
orange="c25d1e"
violet="8762c6"

br_red="cc1729d"
br_green="428b00"
br_yellow="a78300"
br_blue="006dce"
br_magenta="c44392"
br_cyan="00978a"
br_orange="bc5819"
br_violet="825dc0"

font="Meslo LG S Regular Nerd Font Complete"

LC_ALL="en_US.UTF-8" i3lock \
  --insidever-color=${bg_0}${alpha} \
  --insidewrong-color=${bg_0}${alpha} \
  --inside-color=${bg_0}${alpha} \
  --ringver-color=${green}${alpha} \
  --ringwrong-color=${red}${alpha} \
  --ringver-color=${green}${alpha} \
  --ringwrong-color=${red}${alpha} \
  --ring-color=${blue}${alpha} \
  --line-uses-ring \
  --keyhl-color=${magenta}${alpha} \
  --bshl-color=${orange}${alpha} \
  --separator-color=${bg_1}${alpha} \
  --verif-color=${green} \
  --wrong-color=${red} \
  --layout-color=${blue} \
  --date-color=${blue} \
  --time-color=${blue} \
  --screen 1 \
  --blur 1 \
  --clock \
  --indicator \
  --time-str="%H:%M:%S" \
  --date-str="%a %b %e %Y" \
  --verif-text="Verifying..." \
  --wrong-text="Auth Failed" \
  --noinput="No Input" \
  --lock-text="Locking..." \
  --lockfailed="Lock Failed" \
  --time-font="$font" \
  --date-font="$font" \
  --layout-font="$font" \
  --verif-font="$font" \
  --wrong-font="$font" \
  --radius=100 \
  --ring-width=20 \
  --pass-media-keys \
  --pass-screen-keys \
  --pass-volume-keys \
  --image=$CURDIR/selenized-light-wallpaper.png

  # Turn the screen off after a delay.
  sleep 60; pgrep i3lock && xset dpms force off
