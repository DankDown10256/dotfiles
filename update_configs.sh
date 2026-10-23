
#!/bin/sh

set -eu

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DEST="./configs"

INFO() {
    printf '[INFO] %s\n' "$1"
}

ERROR() {
    printf '[ERROR] %s\n' "$1" >&2
}

copy_dir() {
    name="$1"
    source="$2"

    if [ ! -d "$source" ]; then
        ERROR "$name: directory not found ($source)"
        return 1
    fi

    mkdir -p "$DEST/$name"

    rsync -a --delete \
        --exclude='.git/' \
        "$source/" "$DEST/$name/"

    INFO "$name copied"
}

copy_file() {
    name="$1"
    source="$2"

    if [ ! -f "$source" ]; then
        ERROR "$name: file not found ($source)"
        return 1
    fi

    mkdir -p "$DEST/$name"
    cp "$source" "$DEST/$name/"

    INFO "$name copied"
}

INFO "Updating configurations..."

copy_dir "rofi"       "$CONFIG_HOME/rofi"
copy_dir "hypr"       "$CONFIG_HOME/hypr"
copy_dir "swaync"     "$CONFIG_HOME/swaync"
copy_dir "waybar"     "$CONFIG_HOME/waybar"
copy_dir "foot"       "$CONFIG_HOME/foot"
copy_dir "fish"       "$CONFIG_HOME/fish"
copy_dir "quickshell" "$CONFIG_HOME/quickshell"
copy_dir "i3"         "$CONFIG_HOME/i3"
copy_dir "picom"      "$CONFIG_HOME/picom"
copy_dir "nvim"       "$CONFIG_HOME/nvim"
copy_dir "dwm"        "$CONFIG_HOME/dwm"
copy_dir "suckless"   "$CONFIG_HOME/suckless"

copy_file "tmux"      "$HOME/.tmux.conf"
copy_file "xinitrc"   "$HOME/.xinitrc"
copy_file "zed"       "$CONFIG_HOME/zed/settings.json"

INFO "Update finished"
