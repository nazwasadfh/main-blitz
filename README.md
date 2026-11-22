# BlitzArt Linux

Artix (dinit) based distro: btrfs + snapper + grub-btrfs, repos artix / arch / chaotic-aur / blackarch,
`blitz` system toolbox, `blitzinstall` installer (archinstall-like). Live ISO boots to tty.

## Build (on Artix)

    sudo pacman -S artools-iso        # build-iso offers to install the rest
    ./build-iso                       # one file, nothing else needed
    ./build-iso -q                    # dry run (buildiso -q)
    ./build-iso -n                    # no offline repo (smaller ISO, installer downloads everything)

build-iso: clones/updates `nazwasadfh/dots` into /tmp/blitzart-dots (and oh-my-zsh into /tmp/blitzart-omz),
stages the profile into `~/artools-workspace/iso-profiles`, writes `~/.config/artools/pacman.conf.d/iso-*.conf` (and the legacy `pacman-default.conf`)
(artix + arch repos, ILoveCandy), checks that every profile package exists in those repos, and runs `buildiso -p blitzart -i dinit`.

Dots copied from the repo: `fastfetch`, `eza`, `kitty` -> `~/.config/`, `starship.toml` -> `~/.config/starship.toml`, `.zshrc` -> `~/.zshrc`.

## Install layout

- GPT + UEFI only: ESP 1G (`/boot/efi`) + btrfs root; no /home partition.
- Subvolumes: `@` (/, includes /home, /var/log, kernels) · `@snapshots` (/.snapshots) · `@pkg` (/var/cache/pacman/pkg).
  A snapshot of `/` therefore rolls back the whole system, home included. `/` in fstab has no `subvol=`
  so grub-btrfs snapshot entries boot correctly.
- snapper config `root` (what `blitz` expects), baseline snapshot after install, `grub-btrfsd` as dinit service.
- Plain `pacman`/`paru` transactions (install/upgrade/remove) get a snapper pre/post pair via pacman hooks
  (`blitzart-snap`). Skipped when pacman is driven by `blitz` (blitz update makes its own pair) or when
  `BLITZART_NO_SNAP=1` is set. Number cleanup keeps the last 50 (10 important).
- os-release: NAME/PRETTY_NAME = "BlitzArt", ID=artix, ID_LIKE=arch (re-applied by a pacman hook), /etc/motd.

## Sources

`src/` is the real source; `tools/bundle.sh` regenerates the single-file `build-iso`.

## Live ISO login (hostname: blitz-live)

Users `blitzart` (sudo, passwordless) and `root`; password for both: `blitz`.
Shown on the tty login prompt (/etc/issue), in /etc/motd and in a welcome box at the start of blitzinstall.

## User services (dinit)

`dinit-user-spawn` is installed and enabled (live via profile.yaml services, installed system via boot.d), so `dinitctl list` works as a normal
user (user services in `~/.config/dinit.d`). turnstile is intentionally not used (it conflicts with elogind's
rundir handling; the Artix wiki says not to run both).

GRUB on the installed system: `GRUB_TIMEOUT=-1` (menu waits for a choice), `GRUB_TIMEOUT_STYLE=menu`.

## Audio (PipeWire, per-user dinit services)

`pipewire`, `pipewire-pulse`, `wireplumber` + their `-dinit` packages are installed. The three user services
(`pipewire`, `pipewire-pulse`, `wireplumber`) are enabled via `~/.config/dinit.d/boot.d/` for the created user
and for `/etc/skel` (new users); in the live session through the live skel. Requires `dinit-user-spawn`.

## Graphical stack (EXPERIMENTAL, off by default)

blitzinstall menu: "Install graphical stuff (EXPERIMENTAL)" - default **No**. With No nothing changes
(the live ISO and the default install stay console-only).

With **Yes**, additionally:
- `sddm` + `sddm-dinit` (service enabled; never started in the live ISO), theme **sddm-slice**
  (cloned at build time, copied from the ISO; `/etc/sddm.conf` -> `[Theme] Current=sddm-slice`);
  theme deps `qt6-5compat`, `qt6-virtualkeyboard`, `ttf-roboto`; `xorg-server` for sddm's X11 greeter.
- `hyprland`, `hyprpm` (+ `ninja`, for building plugins) (+ portal, hyprlock, hypridle, qt wayland, wl-clipboard, playerctl, brightnessctl, swaybg),
  and the dots' `hypr` directory -> `~/.config/hypr`.
- `kitty`, `dolphin` (pacman, network) and `brave-bin` (chaotic-aur, network).

All sddm/hyprland packages and the theme are cached in the ISO (offline repo), so the ISO grows by
roughly a gigabyte. Built with `-n` they are downloaded instead.
Note: the dots' hypr config launches tools not installed here (quickshell `qs`, rofi, hy3 plugin, ...)
and has some hard-coded `/home/imfl/...` paths.

sddm-slice fix: the theme ships Qt6 imports but no `QtVersion` in `metadata.desktop`, so SDDM started the
Qt5 greeter ("Library import requires a version") and fell back to the default theme. build-iso patches the
staged theme (`QtVersion=6`) and blitzinstall re-checks it when copying the theme to the target.

### Dark theme (GUI option only)

GTK 3/4: Adwaita-dark (`gnome-themes-extra`, `settings.ini`, `GTK_THEME=Adwaita:dark`, dconf default `prefer-dark`
+ `xdg-desktop-portal-gtk` settings portal). Qt6: `qt6ct` (Fusion + `darker` palette, `QT_QPA_PLATFORMTHEME=qt6ct`).
KDE apps (dolphin): `~/.config/kdeglobals` = BreezeDark + `breeze-dark` icons. Env vars live in `/etc/profile.d/blitzart-dark.sh`
and `/etc/environment`. Qt5-only apps follow the KDE/GTK settings where they can (no qt5ct).

### Cursor (GUI option only)

Bibata-Modern-Classic (regular, size 24) for Wayland, X11 and XWayland. It is AUR-only, so build-iso bundles the upstream
release tarball into the ISO (cached in /var/cache/blitzart-build/bibata) and blitzinstall unpacks it to
`/usr/share/icons`. Set via `XCURSOR_THEME`/`XCURSOR_SIZE` (`/etc/profile.d/blitzart-cursor.sh`, `/etc/environment`),
`/usr/share/icons/default/index.theme` (X11 fallback), GTK `settings.ini` and a dconf default.
