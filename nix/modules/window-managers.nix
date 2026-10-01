{ pkgs, inputs, ... }:

let 
  i3=pkgs.i3.overrideAttrs (oldAttrs: rec {
	version = "4.25.1";
	src = pkgs.fetchurl {
	  url = "https://i3wm.org/downloads/i3-${version}.tar.xz";
	  hash = "sha256-SnQrvoG55e5gV/QqjjxpHYiJTpPxpdgf4jkShRKsBcA=";
	};
	postPatch = "patchShebangs .";
	doCheck = false;
  });
in
{
  #  i3 Window Manager (X11 Session)
  services.xserver.windowManager.i3 = {
    enable = true;
    package = i3;
    extraPackages = with pkgs; [
      dmenu
      i3lock-color
      i3lock-fancy-rapid
      xss-lock
      feh
      xwallpaper
      polybar
      xclip
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
      hyprlock
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
