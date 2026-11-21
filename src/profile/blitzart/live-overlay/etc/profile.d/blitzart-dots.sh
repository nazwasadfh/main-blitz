# Apply the BlitzArt dots to the live user's home on first login.
if [ -n "$HOME" ] && [ ! -e "$HOME/.zshrc" ] && [ -r /usr/lib/blitzart/dots.sh ]; then
    . /usr/lib/blitzart/dots.sh
    blitzart_apply_dots "$HOME" >/dev/null 2>&1
fi
