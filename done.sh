#!/usr/bin/env bash
# done.sh - Suicide script to find and kill the parent commandcode (cmd) process

CURR_PID=$$
TARGET_PID=""

while [ "$CURR_PID" -gt 1 2>/dev/null ]; do
    PARENT_PID=$(ps -o ppid= -p "$CURR_PID" 2>/dev/null | tr -d ' ')
    if [ -z "$PARENT_PID" ]; then
        break
    fi
    FULL_CMD=$(ps -o args= -p "$PARENT_PID" 2>/dev/null)
    
    if [[ "$FULL_CMD" == *"node"* && "$FULL_CMD" == *"cmd"* ]] || [[ "$FULL_CMD" == *"cmd --yolo"* ]] || [[ "$FULL_CMD" == *"bin/cmd"* ]]; then
        TARGET_PID=$PARENT_PID
        break
    fi
    CURR_PID=$PARENT_PID
done

if [ -n "$TARGET_PID" ]; then
    kill -9 "$TARGET_PID" 2>/dev/null
fi

# Fallback pattern kill
pkill -9 -f "bin/cmd" 2>/dev/null || pkill -9 -f "cmd --yolo" 2>/dev/null || true
