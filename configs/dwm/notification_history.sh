#!/usr/bin/env bash

if ! command -v jq &>/dev/null; then
  dunstify "Erreur" "Le paquet 'jq' est nécessaire pour ce script."
  exit 1
fi

selection=$(dunstctl history | jq -r '.data[][] | "\(.appname.content) : \(.summary.content) — \(.body.content)"' | dmenu -i -l 15 -p "Historique :")

if [ -n "$selection" ]; then
  dunstctl history-pop
fi
