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

# blitzart_apply_hypr <home> [owner]  - only used by the graphical option.
# MERGES the dots' hypr directory over ~/.config/hypr: the user's files win, files that only illogical-impulse
# ships (e.g. custom/scripts/__restore_video_wallpaper.sh, which the hypr config calls) are kept.
blitzart_apply_hypr() {
    local h=$1 owner=${2:-}
    [[ -d $BA_DOTS/hypr ]] || return 0
    mkdir -p "$h/.config/hypr"
    cp -a "$BA_DOTS/hypr/." "$h/.config/hypr/"
    [[ -n $owner ]] && chown -R "$owner" "$h/.config/hypr" 2>/dev/null
    return 0
}

# blitzart_apply_ii_config <home> [owner]  - only used by the graphical option.
# The dots' config.json is the illogical-impulse settings file: it goes to ~/.config/illogical-impulse/config.json.
# Applied AFTER ii's installer so that nothing overwrites it.
blitzart_apply_ii_config() {
    local h=$1 owner=${2:-}
    [[ -f $BA_DOTS/config.json ]] || return 0
    mkdir -p "$h/.config/illogical-impulse"
    cp "$BA_DOTS/config.json" "$h/.config/illogical-impulse/config.json"
    [[ -n $owner ]] && chown -R "$owner" "$h/.config/illogical-impulse" 2>/dev/null
    return 0
}
