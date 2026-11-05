#!/usr/bin/env bash

set -euo pipefail

BACKUP=/etc/old_configs.bak

if [[ $EUID -ne 0 || -z ${SUDO_USER:-} ]]; then
    echo "Run this script with sudo: administrator rights are required to access $BACKUP." >&2
    exit 1
fi

if [[ ! -f $BACKUP/ready || ! -f $BACKUP/manifest ]]; then
    echo "No complete backup found in $BACKUP. Nothing was changed." >&2
    exit 1
fi

echo "WARNING: Changes made to the installed configurations will be lost."
echo "The configurations saved before installation will be restored."
read -r -p "Continue? [y/N] " answer
if [[ $answer != y && $answer != Y ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

while IFS=$'\t' read -r state index destination; do
    if [[ $state == existing && ! -e $BACKUP/files/$index && ! -L $BACKUP/files/$index ]]; then
        echo "Missing backup for $destination. Nothing was changed." >&2
        exit 1
    fi
done < "$BACKUP/manifest"

while IFS=$'\t' read -r state index destination; do
    rm -rf -- "$destination"
    if [[ $state == existing ]]; then
        mkdir -p -- "$(dirname -- "$destination")"
        cp -a -- "$BACKUP/files/$index" "$destination"
    fi
done < "$BACKUP/manifest"

rm -rf -- "$BACKUP"
echo "Uninstallation complete. Previous configurations have been restored."
