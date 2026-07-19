#!/bin/bash

if ! niri msg windows | awk '
    /Title: "系统监视器"/ { has_title=1 }
    /App ID: "com.danklinux.dms"/ { has_appid=1 }
    /^$/ { if (has_title && has_appid) exit 0; has_title=0; has_appid=0 }
    END { if (has_title && has_appid) exit 0; exit 1 }
'; then
  dms ipc call processlist close 2>/dev/null
fi

dms ipc call processlist focusOrToggle
