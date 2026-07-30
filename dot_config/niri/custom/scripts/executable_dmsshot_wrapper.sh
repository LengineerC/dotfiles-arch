#!/usr/bin/env bash

set -u

DMSSHOT="/home/lengineerc/.local/bin/dmsshot"
SOUND_PROCESS_PATTERN="screenshot-sound.sh"

pkill -USR1 -f "$SOUND_PROCESS_PATTERN" 2>/dev/null || true

exec "$DMSSHOT" "$@"
