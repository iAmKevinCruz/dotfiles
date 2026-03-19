#!/usr/bin/env bash
# Generates session indicators for tmux status bar
# Format: "sessionname | co is pr *wo*"
# Active session is bright/bold, others are dim
# Supports numbered sessions: "1: prism" -> sorted by number, displays "pr"

current="$1"
bg="#0B0E14"
dim="#475266"
bright="#BFBDB6"

indicators=""
first=true
while IFS= read -r session; do
  # Strip "N: " prefix if present
  name="$session"
  if [[ "$session" =~ ^[0-9]+:\ (.+)$ ]]; then
    name="${BASH_REMATCH[1]}"
  fi

  label="${name:0:2}"
  label="$(echo "$label" | tr '[:upper:]' '[:lower:]')"

  $first || indicators+=" "
  first=false

  if [ "$session" = "$current" ]; then
    indicators+="#[fg=$bright,bg=$bg,bold]$label#[fg=$dim,bg=$bg,nobold]"
  else
    indicators+="#[fg=$dim,bg=$bg]$label"
  fi
done < <(tmux list-sessions -F '#S' 2>/dev/null | sort)

echo "$indicators"
