# shellcheck shell=bash
# Package sets shared by build-iso (offline repo) and blitzinstall.

BA_TOOLS_PKGS=(
    eza ugrep tree fastfetch git starship
    zsh zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search
    fzf bat mcfly zoxide
    # used by aliases in the dots .zshrc
    expac hwinfo python-pygments pkgfile
)

BA_BASE_PKGS=(
    base base-devel dinit elogind-dinit dbus-dinit dinit-user-spawn
    linux-firmware intel-ucode amd-ucode
    mkinitcpio artix-keyring artix-archlinux-support archlinux-keyring
    btrfs-progs dosfstools efibootmgr grub snapper grub-btrfs inotify-tools
    networkmanager networkmanager-dinit acpid-dinit cronie-dinit
    sudo nano neovim curl wget rsync man-db man-pages
    pacman-contrib reflector
)

# kernel packages cached in the offline repo (others come from the network)
BA_OFFLINE_KERNELS=(linux)

ba_all_offline_pkgs() {
    printf '%s\n' "${BA_BASE_PKGS[@]}" "${BA_TOOLS_PKGS[@]}" "${BA_OFFLINE_KERNELS[@]}"
}
