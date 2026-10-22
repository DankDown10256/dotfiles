#!/bin/sh

INFO() {
  echo "[INFO] $1"
}

rofi=/home/$USER/.config/rofi/
hypr=/home/$USER/.config/hypr/
swaync=/home/$USER/.config/swaync/
waybar=/home/$USER/.config/waybar/
foot=/home/$USER/.config/foot/
fish=/home/$USER/.config/fish/
quickshell=/home/$USER/.config/quickshell/ 
tmux=/home/$USER/.tmux.conf

echo "Update configurations"

cp -r "$rofi" ./configs/rofi/
INFO "Rofi copied"

cp -r "$hypr" ./configs/hypr/
INFO "Hypr copied"

cp -r "$swaync" ./configs/swaync/
INFO "swaync copied"

cp -r "$waybar" ./configs/waybar/
INFO "Waybar copied"

cp -r "$foot" ./configs/foot/
INFO "Foot copied"

cp -r "$fish" ./configs/fish/
INFO "Fish copied"

cp -r "$quickshell" ./configs/quickshell/
INFO "Quickshell copied"

cp "$tmux" ./configs/tmux/
INFO "Tmux copied"

echo "Update finished"
