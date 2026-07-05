#!/bin/bash

plugins=(
  "systemMonitorPlus"
  "Calculator"
  "emojiLauncher"
  "fullscreenPowerMenu"
)

echo "Installing dms plugins..."

for p in "${plugins[@]}"; do
  dms plugins install "$p"
done

echo "Done."
