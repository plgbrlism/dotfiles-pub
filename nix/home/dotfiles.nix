{ config, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles-pub";
  dotfilesPriv = "${config.home.homeDirectory}/dotfiles-priv";

  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  xdg.configFile = {
	# Shell Desktop
	"noctalia".source = link "${dotfiles}/noctalia-hp/.config/noctalia";
	
    #  Window Managers
    "sway".source = link "${dotfiles}/apps/wm/sway/.config/sway";
    "niri".source = link "${dotfiles}/apps/wm/niri/.config/niri";

    #  Terminals
    "kitty".source = link "${dotfiles}/apps/terminal/kitty/.config/kitty";
    "alacritty".source = link "${dotfiles}/apps/terminal/alacritty/.config/alacritty";
    "foot".source = link "${dotfiles}/apps/terminal/foot/.config/foot";
    "ghostty".source = link "${dotfiles}/apps/terminal/ghostty/.config/ghostty";

    #  CLI Tools
    "btop".source = link "${dotfiles}/apps/cli/btop/.config/btop";
    "cava".source = link "${dotfiles}/apps/cli/cava/.config/cava";
    "fastfetch".source = link "${dotfiles}/apps/cli/fastfetch/.config/fastfetch";
    "rizzoo".source = link "${dotfiles}/apps/cli/rizzoo/.config/rizzoo";

    #  Private CLI
    "glow".source = link "${dotfilesPriv}/cli/glow/.config/glow";
    "yazi".source = link "${dotfilesPriv}/cli/yazi/.config/yazi";
    "micro".source = link "${dotfilesPriv}/editor/micro/.config/micro"; 

    #  Screenshots
    "flameshot".source = link "${dotfilesPriv}/capture/flameshot/.config/flameshot";

    #  Services
    # "systemd".source = link "${dotfilesPriv}/service/systemd/.config/systemd";
    "xdg-desktop-portal".source = link "${dotfilesPriv}/service/xdg-desktop-portal/.config/xdg-desktop-portal";

    #  Dev
    "opencode".source = link "${dotfilesPriv}/dev/opencode/.config/opencode";
  };

  home.file = {
    # ".zshrc".source = link "${dotfilesPriv}/zsh/.zshrc";
    ".xinitrc".source = link "${dotfilesPriv}/env/.xinitrc";
  };
}
