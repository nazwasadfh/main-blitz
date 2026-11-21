# BlitzArt live session: start the installer on tty1.
[[ -f ~/.bashrc ]] && . ~/.bashrc
if [[ $(tty) == /dev/tty1 && -z ${BLITZART_NO_INSTALLER:-} ]]; then
    sudo blitzinstall
    # installer finished/aborted: continue in zsh with the BlitzArt dots
    command -v zsh >/dev/null && exec zsh -l
fi
