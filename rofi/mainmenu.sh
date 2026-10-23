#!/bin/sh

ROFI_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
THEME="$ROFI_DIR/themes/menu.rasi"

choice=$(printf '%s\n' \
  '󰀻  Applications' \
  'Wi-Fi' \
  '  Configuration' |
  rofi -dmenu -i -no-custom -p "Outils" -theme "$THEME") || exit 0

case "$choice" in
'󰀻  Applications') exec "$ROFI_DIR/launcher.sh" ;;
'Wi-Fi') exec foot nmtui ;;
'  Configuration') exec nautilus "${XDG_CONFIG_HOME:-$HOME/.config}" ;;
esac
