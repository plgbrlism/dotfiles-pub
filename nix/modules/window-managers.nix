{ pkgs, ... }:

{
  # ── i3 (X11) ──
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      dmenu
      i3blocks
      i3lock-color
      i3status
    ];
  };

  # ── SwayFX (Wayland) ──
  programs.sway = {
    enable = true;
    wrapperFeatures = {
      base = true;
      gtk = true;
    };
    extraPackages = with pkgs; [
      waybar
      wofi
      swaybg
      swaylock
      swayidle
      grim
      wl-clipboard
      dunst
      libnotify
      xdg-utils
      matugen
      nwg-look
    ];
  };

  # ── Niri (Wayland) ──
  programs.niri.enable = true;

  # ── Shared ──
  environment.systemPackages = with pkgs; [
    rofi
    picom
    wbg
    flameshot
  ];
}
