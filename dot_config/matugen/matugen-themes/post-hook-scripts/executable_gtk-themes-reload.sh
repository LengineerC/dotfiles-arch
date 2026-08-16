#!/usr/bin/env bash

set -u

case "${1:-}" in
    dark)
        target="prefer-dark"
        temporary="prefer-light"
        ;;
    light)
        target="prefer-light"
        temporary="prefer-dark"
        ;;
    *)
        printf 'Usage: %s dark|light\n' "$0" >&2
        exit 2
        ;;
esac

# Changing away and back makes already running GTK applications notice the
# style update, while the final value follows the mode used by Matugen.
gsettings set org.gnome.desktop.interface color-scheme "$temporary"
gsettings set org.gnome.desktop.interface color-scheme "$target"
