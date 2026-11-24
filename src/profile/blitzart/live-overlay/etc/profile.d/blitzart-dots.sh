# Apply the BlitzArt dots to the live user's home on first login. The skel already ships a .zshrc, so the
# test is for ~/.oh-my-zsh (which the .zshrc sources) and not for ~/.zshrc.
if [ -n "$HOME" ] && [ ! -d "$HOME/.oh-my-zsh" ] && [ -r /usr/lib/blitzart/dots.sh ]; then
    . /usr/lib/blitzart/dots.sh
    blitzart_apply_dots "$HOME" >/dev/null 2>&1
fi
