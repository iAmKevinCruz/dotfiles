#!/bin/bash
# Hide current pane (break it out) and push onto stack
# Stores: target|direction

PANE_WIDTH=$(tmux display-message -p '#{pane_width}')
WIN_WIDTH=$(tmux display-message -p '#{window_width}')

# If pane width < window width → horizontal split (side by side)
# Otherwise → vertical split (stacked)
if [ "$PANE_WIDTH" -lt "$WIN_WIDTH" ]; then
  DIR="h"
else
  DIR="v"
fi

HIDDEN=$(tmux break-pane -dP)
ENTRY="${HIDDEN}|${DIR}"

CURRENT=$(tmux showw -v @hidden_panes 2>/dev/null || echo "")
if [ -z "$CURRENT" ]; then
  tmux setw @hidden_panes "$ENTRY"
else
  tmux setw @hidden_panes "$CURRENT,$ENTRY"
fi
