#!/bin/bash

# Récupérer l'état actuel des animations (0 ou 1)
STATUS=$(hyprctl getoption animations:enabled | awk 'NR==1 {print $2}')

if [ "$STATUS" = "1" ]; then
    # Si activé, on désactive tout pour la performance
    hyprctl keyword animations:enabled 0
    hyprctl keyword decoration:drop_shadow 0
    hyprctl keyword decoration:blur:enabled 0
    notify-send "Mode Performance Activé avec succés" "Animations et effets désactivés"
else
    # Si désactivé, on réactive
    hyprctl keyword animations:enabled 1
    hyprctl keyword decoration:drop_shadow 1
    hyprctl keyword decoration:blur:enabled 1
    notify-send "Mode Performance bien desactivé" "Animations et effets réactivés"
fi
