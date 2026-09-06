{ pkgs, inputs, ... }:

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
    
  #  SwayFX
  programs.sway = {
    enable = true;
	package = pkgs.swayfx.override {
      swayfx-unwrapped = inputs.swayfx.packages.${pkgs.system}.default;
    };
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
  environment.systemPackages = [
  	# ie-qol for autotiling daemon for i3/sway
    inputs.i3-qol.packages.${pkgs.system}.default
  ] ++ (with pkgs; [
    rofi
    flameshot
    brightnessctl
    dunst
    libnotify
  ]);
}

