{ config, pkgs, ... }:

let
  term-fallback = pkgs.writeShellScriptBin "launch-terminal" ''
    if [ -n "$WAYLAND_DISPLAY" ]; then
      exec ${pkgs.foot}/bin/foot "$@"
    else
      # Under X11 / i3: fallback to suckless terminal (st) or alacritty
      exec ${pkgs.st}/bin/st "$@"
    fi
  '';
in
{
  imports = [
    ./shell.nix
    ./git.nix
    ./dotfiles.nix
  ];

  home = {
    username = "paul";
    homeDirectory = "/home/paul";
    stateVersion = "26.05";

    sessionVariables = {
      TERMINAL = "launch-terminal";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
    ];

    packages = with pkgs; [
      term-fallback
      st
      foot
      kitty
      alacritty
    ];
  };

  programs.home-manager.enable = true;

  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
