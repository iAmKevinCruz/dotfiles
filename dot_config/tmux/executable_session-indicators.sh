#!/usr/bin/env bash
# Generates session indicators for tmux status bar
# Shows first 2 letters of each session name, active one is bright
# Supports numbered sessions: "1: prism" -> sorted by number, displays "pr"

current="$1"
bg="#0B0E14"
dim="#475266"
bright="#BFBDB6"

output=""
while IFS= read -r session; do
  # Strip "N: " prefix if present, keep original for matching
  name="$session"
  if [[ "$session" =~ ^[0-9]+:\ (.+)$ ]]; then
    name="${BASH_REMATCH[1]}"
  fi

  label="${name:0:2}"
  label="$(echo "$label" | tr '[:upper:]' '[:lower:]')"

  if [ "$session" = "$current" ]; then
    output+="#[fg=$bright,bg=$bg,bold]$label#[nobold]"
  else
    output+="#[fg=$dim,bg=$bg]$label"
  fi
  output+=" "
done < <(tmux list-sessions -F '#S' 2>/dev/null | sort)

echo "$output"
