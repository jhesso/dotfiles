#!/bin/bash
# Launched once by AeroSpace (after-startup-command).
# Most apps are placed by [[on-window-detected]] rules in aerospace.toml.
# Ghostty is handled here instead: one terminal each on ws 3, 6 and 7 at login;
# terminals opened later go wherever you are.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

for app in "Visual Studio Code" "Zen" "Claude" "Microsoft Teams" "Microsoft Outlook"; do
  open -ga "$app"
done

# Open a new Ghostty window and move it to workspace $1
spawn_terminal() {
  local before id
  before="$(ghostty_ids)"
  open -gna Ghostty
  for _ in $(seq 1 30); do
    id="$(ghostty_ids | grep -vxF -e "$before" -e '' | head -n1)"
    [ -z "$before" ] && id="$(ghostty_ids | head -n1)"
    if [ -n "$id" ]; then
      aerospace move-node-to-workspace --window-id "$id" "$1"
      return
    fi
    sleep 1
  done
}

ghostty_ids() {
  aerospace list-windows --all --app-bundle-id com.mitchellh.ghostty --format '%{window-id}'
}

spawn_terminal 3   # commands
spawn_terminal 6   # dev server
spawn_terminal 7   # dev server
