# BlitzArt Linux

An [Artix](https://artixlinux.org) (dinit) based distribution with a rollback-friendly btrfs layout.

- **Base:** Artix + dinit, repositories artix / arch / chaotic-aur / blackarch
- **Filesystem:** btrfs + snapper + grub-btrfs. Every pacman transaction gets a snapshot, and you can boot any snapshot from GRUB
- **`blitzinstall`:** an archinstall-style menu installer that works offline from the ISO
- **`blitz`:** a system toolbox for safe updates, snapshots, health checks and maintenance
- **Live ISO:** boots to a console. An optional, **experimental** graphical install adds Hyprland, SDDM and end-4's illogical-impulse

The whole ISO builder is a single file: `./build-iso`.

---

## Contents

- [Quick start](#quick-start)
- [Building the ISO](#building-the-iso)
- [Live ISO](#live-iso)
- [Installing](#installing)
- [The installed system](#the-installed-system)
- [`blitz` toolbox](#blitz-toolbox)
- [Graphical option (experimental)](#graphical-option-experimental)
- [Repository layout and development](#repository-layout-and-development)
- [Known limitations](#known-limitations)
- [License](#license)

---

## Quick start

On an Artix machine:

```sh
sudo pacman -S artools-iso
git clone https://github.com/nazwasadfh/main-blitz && cd main-blitz
./build-iso
```

Write the resulting ISO to a USB stick and boot it (UEFI only). Log in on tty1, and `blitzinstall` starts automatically.

## Building the ISO

```sh
./build-iso            # build the BlitzArt live ISO
./build-iso -q         # dry run: show what buildiso would do (buildiso -q)
./build-iso -n         # no offline repo: smaller ISO, the installer downloads everything
./build-iso -y         # answer yes to prompts (e.g. move aside a foreign iso-profiles dir)
./build-iso --latest   # ignore the pins and use the newest third-party sources
./build-iso -h         # help
```

`build-iso` offers to install any build dependencies it is missing. It needs only `artools-iso`.

| Environment variable | Meaning | Default |
|---|---|---|
| `BLITZART_DOTS_URL` | dotfiles repository | `https://github.com/nazwasadfh/dots` |
| `BLITZART_DOTS_REF` | pin the dots to a full commit sha | branch head |
| `BLITZART_DOTS_DIR` | local checkout of the dots | `/tmp/blitzart-dots` |
| `WORKSPACE_DIR` | artools workspace | `~/artools-workspace` |

### What a build does

1. Clones or updates the dots (`nazwasadfh/dots`) and oh-my-zsh into `/tmp`.
2. Stages the `blitzart` profile into `~/artools-workspace/iso-profiles`.
3. Writes `~/.config/artools/pacman.conf.d/iso-*.conf` and the legacy `pacman-default.conf` (artix + arch repos, `ILoveCandy`).
4. Checks that every package in the profile exists in those repos.
5. Builds an **offline repo** inside the ISO, unless you pass `-n`, so the installer does not have to download the base system and tools.
6. Runs `buildiso -p blitzart -i dinit`.

Third-party sources (oh-my-zsh, sddm-slice, dots-hyprland, end4-pC, the Bibata cursor and two Google fonts) are fetched at **pinned commits or tags**, and the tarballs and fonts are checked with sha256. The commits used are printed during the build. `build-iso` runs as root, but it never sources third-party PKGBUILDs: it reads their dependency lists with a text parser.

## Live ISO

| | |
|---|---|
| Hostname | `blitz-live` |
| Users | `blitzart` (passwordless sudo) and `root` |
| Password (both) | `blitz` |

The credentials are also shown on the tty login prompt, in `/etc/motd` and in a welcome box when `blitzinstall` starts. The live session runs NetworkManager, chronyd (time sync), PipeWire and `dinit-user-spawn`. It ships the same basic tool set as an installed system: zsh, starship, eza, bat, fzf, zoxide, mcfly, fastfetch, neovim and others.

## Installing

`blitzinstall` is a `dialog` menu. You configure the items in any order and then choose **Install**:

1. Hostname
2. Disk configuration: automatic or manual partitions
3. Kernels: any of `linux` (default), `linux-lts` and `linux-zen`. The matching `linux-headers` are installed for DKMS
4. Root password
5. User account
6. Timezone
7. Locale / keymap
8. Additional packages from any enabled repo
9. Install graphical stuff (**EXPERIMENTAL**, default **No**)

The disk picker lists real disks, virtio disks included, and warns you if you select the live medium. The installer needs a network connection. If none is available, it offers to set one up with `nmtui`.

### Install order

Everything that comes from the ISO's offline repo is installed first, so those packages are older than the repos but consistent with each other. That covers the base system and, with the graphical option, SDDM, Hyprland and the illogical-impulse dependencies. Next, a full `pacman -Syu` runs. Only after that are the network-only packages installed (`paru`, kitty, dolphin, brave) and ii's installer run. This order avoids partial upgrades, such as an old base mixed with a fresh Qt/KF6.

### UEFI boot-entry cleanup

At the end of a successful install, `blitzinstall` lists the firmware boot entries (`efibootmgr -v`) in a checklist, and you can delete any number of them, or none. Only two kinds of entry are pre-ticked:

- **stale** entries, whose GPT partition no longer exists on any disk in the machine
- **duplicate** entries, which are older `BlitzArt` entries

Windows, other distros, the UEFI shell, PXE and USB entries are listed but never pre-ticked. The entry this installation just created is not offered. A confirmation step follows before anything is deleted.

## The installed system

### Disk layout

- GPT + UEFI only: a 1 GiB ESP at `/boot/efi` plus a btrfs root. There is no separate `/home` partition.
- Subvolumes:

  | Subvolume | Mount | Notes |
  |---|---|---|
  | `@` | `/` | includes `/home`, `/var/log` and the kernels |
  | `@snapshots` | `/.snapshots` | |
  | `@pkg` | `/var/cache/pacman/pkg` | excluded from snapshots |

  A snapshot of `/` therefore rolls back the **whole system, home included**. The fstab entry for `/` has no `subvol=`, so the grub-btrfs snapshot entries boot correctly.

### Snapshots

- snapper config `root`, which is what `blitz` expects.
- A baseline snapshot, **"BlitzArt fresh install"**, is created after the install. It is marked `important=yes` and has no cleanup algorithm, so neither snapper nor `blitz snapshot prune` ever removes it. You have to delete it explicitly.
- Plain `pacman`/`paru` transactions get a snapper pre/post pair through pacman hooks (`blitzart-snap`). The hooks are skipped when `blitz` drives pacman, because `blitz update` takes its own pair, or when `BLITZART_NO_SNAP=1` is set.
- Number cleanup keeps the last 50 snapshots (10 important).
- `grub-btrfsd` runs as a dinit service and adds every snapshot to the GRUB menu.

### Boot

- GRUB runs with `GRUB_TIMEOUT=-1` and `GRUB_TIMEOUT_STYLE=menu`, so the menu waits for your choice.
- `os-prober` is enabled (`GRUB_DISABLE_OS_PROBER=false`) for dual-boot. This adds a few seconds to every `grub-mkconfig`, including the runs that grub-btrfsd triggers.

### Services (dinit)

- **System:** chronyd (time sync), NetworkManager, elogind, dbus, cronie, openssh and others.
- **User services:** `dinit-user-spawn` is enabled, so `dinitctl list` works as a normal user, with services in `~/.config/dinit.d`. turnstile is intentionally not used, because it conflicts with elogind's rundir handling and the Artix wiki says not to run both.
- **Audio:** `pipewire`, `pipewire-pulse` and `wireplumber` run as per-user services, enabled via `~/.config/dinit.d/boot.d/` for the created user and through `/etc/skel` for new users.

### Branding, repos and shell

- `os-release` has `NAME`/`PRETTY_NAME` set to `BlitzArt`, `ID=artix` and `ID_LIKE=arch`. A pacman hook re-applies these values after updates.
- `[blackarch]` is added the way the official `strap.sh` does it: the keyring package's signature is verified against the published signer fingerprints, then `pacman-key --populate blackarch` runs and the repo is added with the default SigLevel. If any step fails, the repo is skipped with a warning.
- Dots copied from `nazwasadfh/dots`: `fastfetch`, `eza` and `kitty` go to `~/.config/`, `starship.toml` goes to `~/.config/starship.toml` and `.zshrc` goes to `~/.zshrc`, with oh-my-zsh.

## `blitz` toolbox

```
blitz <command> [options]          blitz <command> --help for details

update,   upd, u     safe system update (snapshot, keyrings, repos, AUR, Flatpak)
snapshot, snap, s    list | create | delete | restore | diff | prune
restore              shortcut for 'snapshot restore'
health,   check      check that the system is healthy
clean                package cache, orphans, old @.broken-* subvolumes
mirrors              refresh / rank mirror lists
pacnew               list, diff and merge .pacnew/.pacsave files
btrfs                status, usage, errors, scrub, balance
boot                 bootloader status, GRUB / initramfs regeneration
kernel               list, install and remove kernels
info                 system overview
```

Some examples:

```sh
blitz update -a -m                 # refresh mirrors, update repos + AUR, with pre/post snapshots
blitz update --rollback-on-fail    # restore the pre-update snapshot if the upgrade fails
blitz update -d                    # list pending updates only
blitz snapshot list
blitz restore                      # pick a snapshot to roll back to
blitz snapshot diff 12             # what changed since snapshot 12
```

`blitz update` also rebuilds the Hyprland plugins after a Hyprland upgrade. Because GRUB waits for input, `blitz update --reboot` asks before it reboots, and it refuses to reboot when combined with `-y`. Logs go to `/var/log/blitz.log`.

## Graphical option (experimental)

The default is **No**: the live ISO and the default install stay console-only. With **Yes**, the installer adds the following.

### Desktop stack

- **SDDM** (`sddm-dinit`, enabled on the target and never started in the live ISO) with the **sddm-slice** theme, plus `qt6-5compat`, `qt6-virtualkeyboard`, `ttf-roboto` and `xorg-server` for the X11 greeter.
  - Fix: sddm-slice ships Qt6 imports without a `QtVersion` in `metadata.desktop`, so SDDM started the Qt5 greeter and fell back to the default theme. `build-iso` patches the theme to `QtVersion=6`, and `blitzinstall` checks the patch again when it copies the theme.
- **Hyprland** with hyprpm (+ `ninja`), the portal, hyprlock, hypridle, Qt Wayland, wl-clipboard, playerctl, brightnessctl and swaybg.
- **Apps:** `kitty` and `dolphin` from pacman, and `brave-bin` from chaotic-aur. All three are downloaded during the install.
- **Dark theme:** Adwaita-dark for GTK 3/4 (`settings.ini`, `GTK_THEME`, a dconf `prefer-dark` default and the portal setting). For Qt6/KDE apps, `plasma-integration` with `QT_QPA_PLATFORMTHEME=kde` reads a BreezeDark `kdeglobals`. `/usr/local/bin/dolphin` is a small wrapper that guarantees the environment. Thumbnail support comes from `libheif`, `libavif` and `kimageformats`.
- **Cursor:** Bibata-Modern-Classic at size 24 for Wayland, X11 and XWayland. It is AUR-only, so the release tarball is bundled into the ISO and unpacked to `/usr/share/icons`.

The SDDM and Hyprland packages and the theme are cached in the ISO, which adds roughly **1 GB**. If you build with `-n`, they are downloaded during the install instead.

### illogical-impulse + end4-pC

The installer sets up end-4's **illogical-impulse** (`end-4/dots-hyprland`) the way its own installer does, but it takes everything it can from the ISO:

- **In the ISO:** `dots-hyprland` with its submodules, `pctrade/end4-pC`, your dots (including `hypr/`), and an offline repo with every ii dependency available in the Artix/Arch repos or prebuilt on chaotic-aur. Those packages are cached with an isolated keyring and their signatures are verified. The package lists come from ii's own `sdata/dist-arch/*/PKGBUILD`.
- **At install time:** `./setup install --force --skip-sysupdate --skip-plasmaintg --skip-fish --skip-allsetups` runs as your user inside the target. It still needs the network for what cannot be cached: `quickshell`, `microtex`, AUR leftovers and the Python venv (`uv`). ii's setup step needs a running init, so the installer applies dinit equivalents directly: the i2c group and module, the ydotool and bluetooth services and the user services.
- **Order of precedence:** your dots are applied **last**. `kitty`, `fastfetch`, `eza`, `starship.toml` and `.zshrc` replace ii's files, and your `hypr/` is **merged** over ii's: your files win, and files that only ii ships stay.
- **end4-pC** is extracted to `~/.config/quickshell/end4-pC` *after* ii runs, because ii's file step does an `rsync --delete` over `~/.config/quickshell`. Your `hypr` config starts it with `qs -c ~/.config/quickshell/end4-pC/`.
- `config.json` from the root of your dots is copied to `~/.config/illogical-impulse/config.json` after ii finishes.
- **Fonts:** JetBrains Mono NF, Space Grotesk and Readex Pro come with ii's dependencies. Google Sans Flex and Patrick Hand have no stable Arch package, so they come from `google/fonts` at a pinned commit (sha256-checked, OFL licences included) and are installed to `/usr/share/fonts/blitzart`. After the install, every font family named in `config.json` is checked with fontconfig.
- **The ii installer is interactive and not auto-answered.** If a command fails, ii's own `R`/`i`/`e` prompt waits for you. If it fails completely, the BlitzArt install continues with a warning. The log is in `/var/log/blitzart-ii.log`. To finish later, run `cd ~/.cache/dots-hyprland && ./setup install`.

### Hyprland plugins (hyprpm)

The installer sets up the plugins that the dots' `hypr/` config actually uses, as listed in `usr/share/blitzart/hyprpm-plugins.list`: **hyprflow**, **dynamic-cursors**, **hy3**, **hyprfocus** (from `hyprwm/hyprland-plugins`) and **HyprWindowShade**. To add more, such as `hyprexpo`, add a line to that list.

hyprpm expects a *running* Hyprland and refuses to run as root, so it fails in a chroot. `blitzart-hyprpm-setup` works around this by running the real hyprpm **as the new user**, with temporary passwordless sudo during the install only, against a small stand-in socket that answers hyprpm's three compositor queries. Hyprland loads the plugins at login (`hyprpm reload -n`).

- A plugin failure never fails the installation. You can re-run `blitzart-hyprpm-setup` after the first boot; it is safe to repeat. The log is in `/var/log/blitzart-hyprpm.log`.
- The plugins compile on the target, so the install takes a few minutes longer and needs network access to GitHub.

## Repository layout and development

```
build-iso                 generated single-file builder (do not edit by hand)
tools/build-iso.in        builder source, including the PINS block
tools/bundle.sh           regenerates build-iso from tools/build-iso.in + src/
tools/update-pins.sh      checks upstream for newer pinned versions
src/data/blitz            the blitz toolbox
src/profile/common/       common package set (artools iso-profiles schema)
src/profile/blitzart/     the ISO profile
  profile.yaml            live session, rootfs and livefs packages
  root-overlay/           files on the installed system (os-release, motd)
  live-overlay/           live ISO files: blitzinstall, hooks, helper scripts, skel
```

`src/` holds the actual sources, and `build-iso` is `tools/build-iso.in` followed by a base64 tarball of `src/`. After you change anything:

```sh
tools/bundle.sh                    # deterministic, so CI can diff it
```

Refreshing the pins:

```sh
tools/update-pins.sh               # dry run: show newer upstream versions
tools/update-pins.sh --write       # update the PINS block
tools/bundle.sh                    # then rebuild build-iso and review the diff
```

**CI** (`.github/workflows/ci.yml`) regenerates `build-iso` and fails if it differs from the committed file. It then runs `bash -n` and `shellcheck -S warning` on all scripts.

## Known limitations

- UEFI + GPT only; no BIOS/MBR support.
- dinit service names (`chronyd`, `bluetoothd`, `NetworkManager`, …) depend on the `*-dinit` packages and are applied on a best-effort basis. Verify them on real hardware.
- The graphical option, the hyprpm setup and the ii integration have **not been verified on a real Artix install**. After the first boot, check `hyprpm list` and the logs in `/var/log/blitzart-*.log`.
- The installer needs a network connection even with the offline repo, for the full upgrade and the network-only packages.

## License

BlitzArt's own scripts (`build-iso`, `blitzinstall`, `blitz`, the hooks and the profile files) are under the [MIT license](LICENSE).

Everything fetched at build or install time keeps its own license. That includes the Artix/Arch/BlackArch/Chaotic-AUR packages, oh-my-zsh, sddm-slice, illogical-impulse, end4-pC, Bibata, the Hyprland plugins, the Google fonts and the dots. A built ISO redistributes these components, so whoever distributes an ISO is responsible for complying with their licenses. See [THIRD-PARTY.md](THIRD-PARTY.md).
