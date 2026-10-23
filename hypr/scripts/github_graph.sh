#!/bin/bash

# Remplace 'ton_pseudo' par ton vrai nom d'utilisateur GitHub
USERNAME="DankDown10256"
OUTPUT_PATH="$HOME/.config/hypr/github_contributions.png"

# Télécharge le graphe en mode sombre (mieux pour hyprlock)
# On ajoute un paramètre de temps pour éviter que le cache ne nous montre une vieille image
curl -s "https://ghchart.rshah.org/40c463/${USERNAME}?$(date +%s)" -o "$OUTPUT_PATH"
