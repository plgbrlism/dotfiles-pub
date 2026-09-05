{ pkgs, ... }:

{
  #  X11 & DISPLAY SERVER
  services.xserver = {
    enable = true;
    xkb.layout = "us";
  };

  # Lightweight TUI Display Manager
  services.displayManager.ly.enable = true;

  # Touchpad support for HP Laptop
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = false;
      tapping = true;
    };
  };

  #  PICOM COMPOSITOR (tuned for Celeron)
  services.picom = {
    enable = true;
    vSync = true;
    fade = true;
    fadeDelta = 4;
    shadow = false; # Disabled to conserve Celeron resources
  };

  #  XDG PORTAL INTEGRATION
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  #  DESKTOP UTILITIES & THEME ENGINE
  environment.systemPackages = with pkgs; [
    xdg-utils
    xdg-user-dirs
    accountsservice
    lxappearance
    nwg-look
  ];
}
