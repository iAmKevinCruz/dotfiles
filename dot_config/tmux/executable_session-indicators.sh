#!/usr/bin/env bash
# Generates session indicators for tmux status bar
# Shows first letter of each session, active one is bright

current="$1"
bg="#0B0E14"
dim="#475266"
bright="#BFBDB6"

output=""
while IFS= read -r session; do
  letter="${session:0:1}"
  letter="$(echo "$letter" | tr '[:lower:]' '[:upper:]')"
  if [ "$session" = "$current" ]; then
    output+="#[fg=$bright,bg=$bg,bold]$letter#[nobold]"
  else
    output+="#[fg=$dim,bg=$bg]$letter"
  fi
  output+=" "
done < <(tmux list-sessions -F '#S' 2>/dev/null)

echo "$output"
