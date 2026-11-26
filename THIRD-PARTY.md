# Third-party components

The MIT license in `LICENSE` covers only the BlitzArt scripts in this repository (`build-iso`, `blitzinstall`,
`blitz`, hooks, profile files). Everything below is fetched at build time or install time, is **not** part of this
repository, and keeps its own license. A built ISO redistributes these components, so whoever distributes an ISO is
responsible for complying with them (source offers, notices). Licenses are listed as declared upstream at the time of
writing - **verify them yourself** before redistributing.

| Component | Source | Used for | License (upstream) |
|---|---|---|---|
| Artix / Arch Linux packages | Artix and Arch repositories | base system, kernels, tools | per package (mostly GPL/MIT/BSD; see `pacman -Qi`, `/usr/share/licenses`) |
| BlackArch packages | blackarch.org | optional repository | per package |
| Chaotic-AUR packages | chaotic.cx | prebuilt AUR packages (paru/yay, ii dependencies) | per package |
| oh-my-zsh | github.com/ohmyzsh/ohmyzsh | zsh framework | MIT |
| sddm-slice | github.com/EricKotato/sddm-slice | SDDM theme (graphical option) | check its repository (GPL family) |
| illogical-impulse (dots-hyprland) | github.com/end-4/dots-hyprland | Hyprland setup (graphical option) | GPL-3.0 |
| end4-pC | github.com/pctrade/end4-pC | default quickshell config (graphical option) | check its LICENSE file |
| Bibata Modern Classic | github.com/ful1e5/Bibata_Cursor | cursor theme | GPL-3.0 |
| hyprflow | github.com/sandwichfarm/hyprflow | Hyprland plugin (built on the target by hyprpm) | check its repository |
| hypr-dynamic-cursors | github.com/VirtCode/hypr-dynamic-cursors | Hyprland plugin (hyprpm) | check its repository (BSD family) |
| hy3 | github.com/outfoxxed/hy3 | Hyprland plugin (hyprpm) | check its repository (BSD family) |
| hyprland-plugins (hyprfocus) | github.com/hyprwm/hyprland-plugins | Hyprland plugins (hyprpm) | BSD-3-Clause (check its LICENSE) |
| HyprWindowShade | github.com/ManofJELLO/HyprWindowShade | Hyprland plugin (hyprpm) | check its LICENSE |
| nazwasadfh/dots | github.com/nazwasadfh/dots | user dotfiles (fastfetch, eza, kitty, starship, zsh, hypr) | set by its author |

Pinned versions are in the `PINS` block of `tools/build-iso.in`; the exact commits used by a build are printed
while it runs.
