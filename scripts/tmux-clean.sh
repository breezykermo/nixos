#!/usr/bin/env bash
# Kill all tmux sessions that are named as numbers, i.e. "1", "2", "3"...
for session in $(tmux list-sessions | awk '{print $1}' | awk '{sub(/:$/, ""); print}'); do
    if [[ "$session" =~ ^[0-9]$ ]]; then
        tmux kill-session -t "$session"
    fi
done
