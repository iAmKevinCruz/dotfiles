#!/bin/bash
# Pop last hidden pane from stack and join it back
# Entry format: target|direction

PANES=$(tmux showw -v @hidden_panes 2>/dev/null)
if [ -z "$PANES" ]; then
  tmux display-message "No hidden panes"
  exit 0
fi

# Pop last comma-separated entry
LAST="${PANES##*,}"
REST="${PANES%,$LAST}"
[ "$REST" = "$LAST" ] && REST=""

TARGET=$(echo "$LAST" | cut -d'|' -f1)
DIR=$(echo "$LAST" | cut -d'|' -f2)

tmux join-pane -"${DIR}" -s "$TARGET"

if [ -z "$REST" ]; then
  tmux setw -u @hidden_panes
else
  tmux setw @hidden_panes "$REST"
fi
