# shellcheck shell=bash
# blitzart_apply_dots <home> [owner]
# Copies the BlitzArt dotfiles (fastfetch, kitty, starship.toml, .zshrc, oh-my-zsh)
# from /usr/share/blitzart into <home>. Everything comes from the ISO (no network).
BA_DOTS=/usr/share/blitzart/dots
BA_OMZ=/usr/share/blitzart/oh-my-zsh

blitzart_apply_dots() {
    local h=$1 owner=${2:-}
    [[ -d $h ]] || mkdir -p "$h"
    mkdir -p "$h/.config"
    [[ -d $BA_DOTS/fastfetch ]]    && { rm -rf "$h/.config/fastfetch"; cp -r "$BA_DOTS/fastfetch" "$h/.config/fastfetch"; }
    [[ -d $BA_DOTS/eza ]]          && { rm -rf "$h/.config/eza";       cp -r "$BA_DOTS/eza" "$h/.config/eza"; }
    [[ -d $BA_DOTS/kitty ]]        && { rm -rf "$h/.config/kitty";     cp -r "$BA_DOTS/kitty" "$h/.config/kitty"; }
    [[ -f $BA_DOTS/starship.toml ]] && cp "$BA_DOTS/starship.toml" "$h/.config/starship.toml"
    [[ -f $BA_DOTS/.zshrc ]]       && cp "$BA_DOTS/.zshrc" "$h/.zshrc"
    if [[ -d $BA_OMZ ]]; then
        rm -rf "$h/.oh-my-zsh"; cp -r "$BA_OMZ" "$h/.oh-my-zsh"
        mkdir -p "$h/.oh-my-zsh/custom/plugins"
        local p
        for p in zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search; do
            ln -sfn "/usr/share/zsh/plugins/$p" "$h/.oh-my-zsh/custom/plugins/$p"
        done
    fi
    mkdir -p "$h/.config/mcfly"
    [[ -n $owner ]] && chown -R "$owner" "$h/.config" "$h/.zshrc" "$h/.oh-my-zsh" 2>/dev/null
    return 0
}
