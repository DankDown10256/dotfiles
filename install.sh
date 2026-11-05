#!/usr/bin/env bash

set -euo pipefail

BACKUP=/etc/old_configs.bak
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ $EUID -ne 0 || -z ${SUDO_USER:-} ]]; then
    echo "Run this script with sudo: administrator rights are required to write to $BACKUP." >&2
    exit 1
fi

if [[ -e $BACKUP || -L $BACKUP ]]; then
    echo "Backup already exists: $BACKUP. Remove or restore it before installing." >&2
    exit 1
fi

USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
if [[ -z $USER_HOME || ! -d $USER_HOME ]]; then
    echo "Cannot determine the home directory for $SUDO_USER." >&2
    exit 1
fi

CONFIG_HOME="$USER_HOME/.config"
USER_GROUP=$(id -gn "$SUDO_USER")
TEMP_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEMP_DIR"' EXIT

# Export tracked files from the working tree, including local edits.
sudo -u "$SUDO_USER" git -C "$REPO" ls-files -z |
    tar -C "$REPO" --null -T - -cf - |
    tar -C "$TEMP_DIR" -xf -

sources=()
destinations=()

add() {
    if [[ -e $TEMP_DIR/$1 || -L $TEMP_DIR/$1 ]]; then
        sources+=("$TEMP_DIR/$1")
        destinations+=("$2")
    fi
}

for name in alacritty cosmic dwm fish foot hypr i3 kitty nvim picom \
    quickshell rofi suckless swaync waybar xfce4; do
    add "$name" "$CONFIG_HOME/$name"
done

add emacs "$USER_HOME/.emacs.d"
add tmux/.tmux.conf "$USER_HOME/.tmux.conf"
add xinitrc/.xinitrc "$USER_HOME/.xinitrc"
add zsh/.zshrc "$USER_HOME/.zshrc"
add zed/settings.json "$CONFIG_HOME/zed/settings.json"

for source in "$TEMP_DIR"/kde/*; do
    [[ -e $source || -L $source ]] || continue
    add "kde/${source##*/}" "$CONFIG_HOME/${source##*/}"
done

mkdir -m 700 -- "$BACKUP"
mkdir -- "$BACKUP/files"
: > "$BACKUP/manifest"

# Save all existing destinations before replacing any of them.
for i in "${!destinations[@]}"; do
    destination=${destinations[$i]}
    if [[ -e $destination || -L $destination ]]; then
        cp -a -- "$destination" "$BACKUP/files/$i"
        printf 'existing\t%s\t%s\n' "$i" "$destination" >> "$BACKUP/manifest"
    else
        printf 'absent\t%s\t%s\n' "$i" "$destination" >> "$BACKUP/manifest"
    fi
done

touch "$BACKUP/ready"

for i in "${!destinations[@]}"; do
    destination=${destinations[$i]}
    mkdir -p -- "$(dirname -- "$destination")"
    rm -rf -- "$destination"
    cp -a -- "${sources[$i]}" "$destination"
    chown -hR "$SUDO_USER:$USER_GROUP" -- "$destination"
done

echo "Installation complete. Previous configurations are saved in $BACKUP."
