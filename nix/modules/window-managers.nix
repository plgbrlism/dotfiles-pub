{ pkgs, ... }:

{
  #  i3 Window Manager (X11 Session)
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      dmenu
      i3lock-color
      xss-lock
      feh
      xwallpaper
      polybar
    ];
  };

  #  SwayFX (Wayland Session)
  programs.sway = {
    enable = true;
    package = pkgs.swayfx; # Explicitly use SwayFX from nixpkgs
    wrapperFeatures = {
      base = true;
      gtk = true;
    };
    extraPackages = with pkgs; [
      waybar
      swaybg
      swaylock
      wbg
      grim
      wl-clipboard
    ];
  };

  #  Niri Window Manager (Wayland Session)
  programs.niri.enable = true;

  #  Shared Session Utilities
  environment.systemPackages = with pkgs; [
    rofi
    flameshot
    brightnessctl
    dunst
    libnotify
  ];
}
