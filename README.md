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
- chrony + chrony-dinit installed, service `chronyd` enabled (time sync) - on the installed system and in the live ISO.
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
  (the dots' `hypr` directory is NOT copied).
- `kitty`, `dolphin` (pacman, network) and `brave-bin` (chaotic-aur, network).

All sddm/hyprland packages and the theme are cached in the ISO (offline repo), so the ISO grows by
roughly a gigabyte. Built with `-n` they are downloaded instead.

sddm-slice fix: the theme ships Qt6 imports but no `QtVersion` in `metadata.desktop`, so SDDM started the
Qt5 greeter ("Library import requires a version") and fell back to the default theme. build-iso patches the
staged theme (`QtVersion=6`) and blitzinstall re-checks it when copying the theme to the target.

### Dark theme (GUI option only)

GTK 3/4: Adwaita-dark (`gnome-themes-extra`, `settings.ini`, `GTK_THEME=Adwaita:dark`, dconf default `prefer-dark`
+ `xdg-desktop-portal-gtk` settings portal). Qt6 and KDE apps (dolphin): platform theme `kde`
(`plasma-integration`, `QT_QPA_PLATFORMTHEME=kde`) reading `~/.config/kdeglobals` = BreezeDark + Breeze style + `breeze-dark` icons.
The dots' hypr `env.lua` also sets `QT_QPA_PLATFORMTHEME=kde`, which only works when `plasma-integration` is installed
(without it Qt silently falls back to the light default). `/usr/local/bin/dolphin` is a tiny wrapper that guarantees the env.
Image formats for thumbnails: `libheif`, `libavif`, `kimageformats`.

### Cursor (GUI option only)

Bibata-Modern-Classic (regular, size 24) for Wayland, X11 and XWayland. It is AUR-only, so build-iso bundles the upstream
release tarball into the ISO (cached in /var/cache/blitzart-build/bibata) and blitzinstall unpacks it to
`/usr/share/icons`. Set via `XCURSOR_THEME`/`XCURSOR_SIZE` (`/etc/profile.d/blitzart-cursor.sh`, `/etc/environment`),
`/usr/share/icons/default/index.theme` (X11 fallback), GTK `settings.ini` and a dconf default.


## illogical-impulse + end4-pC (GUI option only)

With the graphical option the installer sets up end-4's **illogical-impulse** the way its own installer does
(`curl -s https://ii.clsty.link/get` clones `end-4/dots-hyprland` into `~/.cache/dots-hyprland` and runs `./setup install`),
except that everything it can is already inside the ISO:

- **In the ISO:** `end-4/dots-hyprland` (with submodules), `pctrade/end4-pC`, your dots (incl. `hypr/`), and an offline repo with
  every ii dependency that exists in the Artix/Arch repos, plus the prebuilt AUR ones that chaotic-aur has (cached at build time
  with an isolated keyring, signatures verified). The package lists are read from ii's own `sdata/dist-arch/*/PKGBUILD`.
- **At install time:** `./setup install --force --skip-sysupdate --skip-plasmaintg --skip-fish --skip-allsetups`
  runs as your user in the target. It still needs the network for what cannot be cached: `quickshell` and `microtex`
  (built from git by ii's PKGBUILDs), AUR leftovers (e.g. fonts), Google Sans Flex, the python venv (`uv`).
  `ii`'s setups step needs a running init, so its dinit equivalents are applied directly (i2c group + module, ydotool and
  bluetooth services, user services).
- **Priority:** your dots are applied LAST, over ii's: `kitty`, `fastfetch`, `eza`, `starship.toml`, `.zshrc` replace ii's,
  and your `hypr/` is MERGED over ii's (your files win; files only ii ships, such as
  `custom/scripts/__restore_video_wallpaper.sh`, stay).
- **end4-pC:** extracted to `~/.config/quickshell/end4-pC` AFTER ii (ii's file step does `rsync --delete` on all of
  `~/.config/quickshell`). Your `hypr` starts it with `qs -c ~/.config/quickshell/end4-pC/`.
- If ii's installer fails, the install continues with a warning; re-run `cd ~/.cache/dots-hyprland && ./setup install`.

## Install order and why

Everything that comes from the ISO's offline repo is installed first (older, but consistent with each other):
base system, then (graphical option) SDDM/Hyprland and illogical-impulse dependencies. Only then does
`phase_upgrade` run a full `pacman -Syu`, and only after that are network-only packages installed
(`paru`, kitty, dolphin, brave) and ii's own installer run. This avoids partial upgrades (old base + fresh Qt/KF6).

- Snapshots: the "BlitzArt fresh install" baseline has no cleanup algorithm and `important=yes`, so snapper's
  number cleanup never removes it; `blitz snapshot prune` skips it too (delete it explicitly if you really want to).
- Dual-boot: `os-prober` is installed and enabled in GRUB (GRUB_DISABLE_OS_PROBER=false). It adds a few seconds
  to every `grub-mkconfig`, including the ones grub-btrfsd triggers after each snapshot.
- Disk picker: lists real disks by TYPE (virtio disks are no longer hidden) and warns if you pick the live medium.
- `linux-headers` for every selected kernel are installed (DKMS).
- [blackarch] uses the default SigLevel; `blackarch-keyring` is installed after the upgrade.

## Pinned sources, BlackArch, ii, GRUB (notes)

- **Pins.** oh-my-zsh, sddm-slice, dots-hyprland, end4-pC are fetched at an exact commit and the Bibata cursor at a tag
  verified by sha256 (`PINS` block in `tools/build-iso.in`). `./build-iso --latest` ignores the pins. `tools/update-pins.sh`
  shows newer upstream versions (`--write` applies them; then run `tools/bundle.sh`). Your own dots follow the branch head
  unless `BLITZART_DOTS_REF=<full sha>` is set.
- **Security.** `build-iso` runs as root but never sources third-party PKGBUILDs; dependency lists are read with a text parser.
- **BlackArch.** Added the way the official `strap.sh` does it: keyring package + signature verified against the
  published signer fingerprints, `pacman-key --populate blackarch`, then the repo with the default SigLevel.
  If it fails the repo is skipped with a warning.
- **illogical-impulse is interactive.** The installer is not auto-answered. If a command fails, ii's own prompt
  (`R` repeat / `i` ignore / `e` exit) waits for you. Log: `/var/log/blitzart-ii.log`; a failure summary is printed
  afterwards. To finish later: `cd ~/.cache/dots-hyprland && ./setup install`.
- **GRUB_TIMEOUT=-1.** The boot menu waits for a keypress, so `blitz update --reboot` asks before rebooting (and refuses with `-y`).
- **dinit services are best effort.** Service names (`chronyd`, `bluetoothd`, `NetworkManager`, ...) depend on the
  `*-dinit` packages; verify on a real system.
- **License.** `LICENSE` (MIT) covers BlitzArt's own scripts; see `THIRD-PARTY.md` for everything else.
- **CI.** `.github/workflows/ci.yml` regenerates `build-iso` and fails if it differs from the committed one, then runs syntax checks and shellcheck.

## Hyprland plugins (hyprpm)

With "Install graphical stuff", blitzinstall installs and enables the plugins that the dots' `hypr/` config actually
uses (`usr/share/blitzart/hyprpm-plugins.list`): **hyprflow**, **dynamic-cursors**, **hy3**, **hyprfocus** (from `hyprwm/hyprland-plugins`; hyprpm builds all plugins
of that repo but only hyprfocus is enabled) and **HyprWindowShade**
(`hyprexpo` / `hyprglass` are only commented-out experiments there, so they are not installed - add a line to the list to get them).

hyprpm is built for a *running* Hyprland: in a chroot `add`/`enable`/`update` fail ("Are you running hyprland?",
"Headers outdated"), and it refuses to run as root. `blitzart-hyprpm-setup` therefore runs the real hyprpm **as the new user**
(temporary passwordless sudo, only during the install) against a tiny stand-in socket that answers the three things hyprpm
asks the compositor (version of the *installed* binary, loaded plugins, `/plugin load`). hyprpm itself clones Hyprland's headers,
builds the plugins and keeps its state in `~/.local/share/hyprpm`; Hyprland loads them at login (the config runs `hyprpm reload -n`).

- A failure never fails the installation; re-run `blitzart-hyprpm-setup` after the first boot (safe to repeat). Log: `/var/log/blitzart-hyprpm.log`.
- After a Hyprland upgrade the plugins must be rebuilt for the new ABI: `blitz update` does it (`blitzart-hyprpm-setup --update`).
- It compiles on the target machine, so the install takes a few minutes longer and needs the network (GitHub).
- Not verified on a real Artix install - check `hyprpm list` after the first boot.

## illogical-impulse settings and fonts

- `config.json` from the root of the dots repo is copied to `~/.config/illogical-impulse/config.json` (graphical option only,
  applied after ii's installer so nothing overwrites it).
- Fonts it names: **JetBrains Mono NF**, **Space Grotesk**, **Readex Pro** come with ii's dependency list
  (`ttf-jetbrains-mono-nerd`, `otf-space-grotesk`, `ttf-readex-pro`); **Google Sans Flex** (variable font, the config sets its
  `wght`/`wdth`/`ROND` axes) and **Patrick Hand** have no stable Arch package, so `build-iso` takes them from `google/fonts`
  at a pinned commit (sha256-checked, OFL licences included) and the installer puts them in `/usr/share/fonts/blitzart`.
- After the install, every font family found in `config.json` is checked with fontconfig; missing ones are reported as warnings.

## UEFI boot entries (end of the installation)

After a successful install, blitzinstall lists the firmware boot entries (`efibootmgr -v`) and lets you delete several, one or none
(checklist, SPACE selects, Cancel/empty = delete nothing, then a confirmation). Suggested - and pre-ticked - are only:
entries whose GPT partition exists on no disk of this machine (`stale`, e.g. a wiped old install) and older `BlitzArt` entries
(`duplicate`). Windows, other distros, UEFI shell, PXE, USB are listed but never pre-ticked. The entry created by this
installation (first in BootOrder, label `BlitzArt`) is not offered at all.
