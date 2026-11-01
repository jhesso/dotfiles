# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/jhesso/.docker/bin"
# End of Docker Desktop section.

# Homebrew (puts /opt/homebrew/bin first in PATH, e.g. so tmux plugins get Bash 5)
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source
end


# Default editor (git commits, crontab, yazi "open with", etc.)
set -gx EDITOR nvim
set -gx VISUAL nvim

if status is-interactive
    # Commands to run in interactive sessions can go here
    alias vim nvim
    alias vi nvim
end

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	command yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
		builtin cd -- "$cwd"
	end
	command rm -f -- "$tmp"
end

# Random wallpaper from ~/Pictures/wallpapers (symlinks allowed) on every screen
function wallpaper
    # resolve symlinks: macOS can ignore a wallpaper given as a link
    set -l imgs (path resolve ~/Pictures/wallpapers/*)
    set -l current (osascript -e 'tell application "System Events" to get picture of desktop 1')
    # don't pick the one that's already showing
    if test (count $imgs) -gt 1
        set imgs (string match -v -- "$current" $imgs)
    end
    set -l img (random choice $imgs)
    echo "wallpaper: $img"
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$img\""
end

starship init fish | source
