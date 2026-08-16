#!/bin/sh

SRC="$HOME/.config/matugen/templates/fcitx5/assets"
DST="$HOME/.local/share/fcitx5/themes/Matugen"

mkdir -p "$DST"

cp -f "$SRC/bg.png" "$DST/"
cp -f "$SRC/bg_dark.png" "$DST/"
