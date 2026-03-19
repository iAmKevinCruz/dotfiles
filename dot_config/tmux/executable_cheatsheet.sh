#!/bin/sh
w=$(tmux display -p "#{client_width}")
if [ "$w" -lt 100 ]; then
  less ~/.config/tmux/cheatsheet-narrow.txt
else
  less ~/.config/tmux/cheatsheet.txt
fi
