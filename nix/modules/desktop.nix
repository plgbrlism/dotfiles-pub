{ pkgs, ... }:

{
  # --- X11 & DISPLAY SERVER ---
  services.xserver = {
    enable = true;
    xkb.layout = "us";
  };

  # Lightweight TUI Display Manager (from your Arch setup)
  services.displayManager.ly.enable = true;

  # Touchpad support for HP Laptop
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
    };
  };

  # --- PICOM COMPOSITOR (Tuned for Celeron UHD Graphics) ---
  services.picom = {
    enable = true;
    vSync = true;
    fade = true;
    fadeDelta = 4;
    shadow = false; # Disabled to conserve Celeron iGPU resources
  };

  # --- XDG PORTAL INTEGRATION ---
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # --- DESKTOP UTILITIES & THEME ENGINE ---
  environment.systemPackages = with pkgs; [
    xdg-utils
    xdg-user-dirs
    accountsservice
    lxappearance
    nwg-look
  ];
}
