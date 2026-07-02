#!/bin/bash

if ! niri msg windows | grep -q 'App ID: "org.quickshell"'; then
  dms ipc call processlist close 2>/dev/null
fi

dms ipc call processlist focusOrToggle
