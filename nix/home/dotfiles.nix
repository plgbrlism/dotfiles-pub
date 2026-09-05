{ config, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles-pub";
  dotfilesPriv = "${config.home.homeDirectory}/dotfiles-priv";

  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  xdg.configFile = {
    # ── Window Managers ──
    "i3".source = link "${dotfiles}/apps/wm/i3/.config/i3";
    "sway".source = link "${dotfiles}/apps/wm/sway/.config/sway";
    "niri".source = link "${dotfiles}/apps/wm/niri/.config/niri";

    # ── Terminals ──
    "kitty".source = link "${dotfiles}/apps/terminal/kitty/.config/kitty";
    "alacritty".source = link "${dotfiles}/apps/terminal/alacritty/.config/alacritty";
    "foot".source = link "${dotfiles}/apps/terminal/foot/.config/foot";
    "ghostty".source = link "${dotfiles}/apps/terminal/ghostty/.config/ghostty";

    # ── Bar / Launcher / Notification ──
    "waybar".source = link "${dotfiles}/apps/bar/waybar/.config/waybar";
    "polybar".source = link "${dotfiles}/apps/bar/polybar/.config/polybar";
    "rofi".source = link "${dotfiles}/apps/launcher/rofi/.config/rofi";
    "dunst".source = link "${dotfiles}/apps/notifier/dunst/.config/dunst";

    # ── Compositor ──
    "picom".source = link "${dotfiles}/apps/compositor/picom/.config/picom";

    # ── CLI Tools ──
    "btop".source = link "${dotfiles}/apps/cli/btop/.config/btop";
    "cava".source = link "${dotfiles}/apps/cli/cava/.config/cava";
    "fastfetch".source = link "${dotfiles}/apps/cli/fastfetch/.config/fastfetch";
    "rizzoo".source = link "${dotfiles}/apps/cli/rizzoo/.config/rizzoo";

    # ── Private CLI ──
    "glow".source = link "${dotfilesPriv}/cli/glow/.config/glow";
    "yazi".source = link "${dotfilesPriv}/cli/yazi/.config/yazi";

    # ── Screenshots ──
    "flameshot".source = link "${dotfilesPriv}/capture/flameshot/.config/flameshot";

    # ── Services ──
    "systemd".source = link "${dotfilesPriv}/service/systemd/.config/systemd";
    "xdg-desktop-portal".source = link "${dotfilesPriv}/service/xdg-desktop-portal/.config/xdg-desktop-portal";

    # ── Dev ──
    "opencode".source = link "${dotfilesPriv}/dev/opencode/.config/opencode";
  };

  home.file = {
    ".zshrc".source = link "${dotfilesPriv}/zsh/.zshrc";
    ".zprofile".source = link "${dotfilesPriv}/env/.zprofile";
    ".xprofile".source = link "${dotfilesPriv}/env/.xprofile";
    ".xinitrc".source = link "${dotfilesPriv}/env/.xinitrc";
  };
}
