{ pkgs, inputs, ... }:

{
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
      swaybg
      grim
      wl-clipboard
    ];
  };

  #  Niri Window Manager (Wayland Session)
  programs.niri.enable = true;

  #  Shared Session Utilities
  environment.systemPackages = [
    inputs.i3-qol.packages.${pkgs.system}.default
  ] ++ (with pkgs; [
    brightnessctl
    libnotify
  ]);
}
