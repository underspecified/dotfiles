#!/usr/bin/python3

import json
import sys

def main():
    theme_file, light_palette_file, dark_palette_file = sys.argv[1:]

    with (open(theme_file, "r") as tf,
          open(light_palette_file, "r") as lf,
          open(dark_palette_file, "r") as df):
        theme = json.load(tf)
        light = json.load(lf)
        dark = json.load(df)
    #flipped = {v:k for k,v in palette.items()}
    applied = {f"{k}@@{m}": mode.get(v, v)
               for k,v in theme.items()
               for m, mode in (("light", light), ("dark", dark))}
    json.dump(applied, sys.stdout, indent=2)

if __name__ == '__main__':
    main()
