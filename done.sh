#!/usr/bin/env bash
# done.sh - Suicide script to kill the active commandcode process and close the terminal window
kill -9 $PPID 2>/dev/null || pkill -9 -f "cmd --yolo" || pkill -9 -f "cmd" || true

