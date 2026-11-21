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
