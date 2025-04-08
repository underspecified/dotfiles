#!/bin/sh
# i3lock-solarized is licensed under the MIT License Copyright (c) 2020 Parsiad Azimzadeh

CURDIR=$(dirname $0)

alpha="dd"
bg_0="103c48"
bg_1="184956"
bg_2="2d5b69"
dim_0="72898f"
fg_0="adbcbc"
fg_1="cad8d9"

red="fa5750"
green="75b938"
yellow="dbb32d"
blue="4695f7"
magenta="f275be"
cyan="41c7b9"
orange="ed8649"
violet="af88eb"

br_red="ff665c"
br_green="84c747"
br_yellow="ebc13d"
br_blue="58a3ff"
br_magenta="ff84cd"
br_cyan="53d6c7"
br_orange="fd9456"
br_violet="bd96fa"

font="Meslo LG S Regular Nerd Font Complete"

LC_ALL="en_US.UTF-8" i3lock \
i3lock \
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
  --image=$CURDIR/selenized-dark-wallpaper.png

  # Turn the screen off after a delay.
  sleep 60; pgrep i3lock && xset dpms force off
