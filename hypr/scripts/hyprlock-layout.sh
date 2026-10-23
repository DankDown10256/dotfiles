#!/usr/bin/env bash

LAYOUT=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n 1)

# Shorten the layout name (e.g., "English (US)" -> "US")
if [[ "$LAYOUT" == *"French (FR)"* ]]; then
    echo "FR"
elif [[ "$LAYOUT" == *"Russian"* ]]; then
    echo "RU"
else
    echo "${LAYOUT:0:3}"
fi
