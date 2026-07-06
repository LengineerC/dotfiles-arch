#!/bin/bash

BASE_DIR="$HOME"

sources=(
  ".zshrc"
  ".config/DankMaterialShell"
  ".config/niri"
  ".local/share/fcitx5/pinyin/dictionaries"
  "Applications/DankMaterialShell/quickshell"
  "Documents/easyeffects"
  "Scripts"
  ".config/kitty"
  ".config/nvim"
)

for src in "${sources[@]}"; do
  chezmoi add "$BASE_DIR/$src"
done

echo "Add finished."
