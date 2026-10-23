#!/bin/sh

ROFI_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
exec rofi -show drun -theme "$ROFI_DIR/themes/launcher.rasi"
