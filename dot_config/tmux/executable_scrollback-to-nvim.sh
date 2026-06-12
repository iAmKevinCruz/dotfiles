#!/usr/bin/env bash
# Capture pane scrollback and open in nvim.
# Usage: scrollback-to-nvim.sh [cursor]
#   no arg  -> open at bottom (most recent)
#   cursor  -> open at line matching copy-mode cursor

set -euo pipefail

MODE="${1:-bottom}"
TMP=/tmp/tmux-scrollback.txt

tmux capture-pane -p -S - -E - > "$TMP"

if [[ "$MODE" == "cursor" ]]; then
    TOTAL=$(wc -l < "$TMP")
    HEIGHT=$(tmux display -p '#{pane_height}')
    SCROLL=$(tmux display -p '#{scroll_position}')
    CY=$(tmux display -p '#{copy_cursor_y}')
    LINE=$(( TOTAL - SCROLL - HEIGHT + 1 + CY ))
    (( LINE < 1 )) && LINE=1
    tmux send-keys -X cancel
    tmux split-window -hZ "nvim -c 'setlocal buftype=nofile' +${LINE} '$TMP'"
else
    tmux split-window -hZ "nvim -c 'setlocal buftype=nofile' + '$TMP'"
fi
