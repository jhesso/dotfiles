# Dotfiles

GNU Stow repo shared between my MacBook (macOS) and my Arch Linux gaming tower.

## Layout
- One package per app at the top level; its contents mirror paths under `~`,
  e.g. `fish/.config/fish/config.fish`.
- The repo lives at `~/dotfiles`, so Stow targets `~`. Run stow from the repo root.
- Both machines: fish, tmux, yazi, ghostty, starship
- Mac only: aerospace
- Arch only: hypr (Hyprland 0.55+ Lua config, `hyprland.lua`), noctalia
- Neovim is NOT in this repo. It's my kickstart.nvim fork, a separate repo at `~/.config/nvim`.

## Rules
- Dry-run before stowing: `stow -n -v <pkg>`. Don't use `--adopt` without asking me;
  it overwrites files in the repo.
- Never commit `fish_variables`, tmux plugins, or anything with tokens or keys.
  Show me `git diff` before committing.
- OS-specific settings go inside the shared file behind `switch (uname)`
  (Darwin / Linux), not in separate copies.
- Don't move or delete configs outside this repo without asking.

## Checking changes
- fish: `fish --no-execute <file>`, format with `fish_indent -w <file>`
- Hyprland: `hyprctl reload`; config errors show as a bar at the top of the screen
- tmux: `tmux source-file ~/.config/tmux/tmux.conf`
