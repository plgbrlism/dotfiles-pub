{ pkgs, ... }:

{
  #  X11 & DISPLAY SERVER
  services.xserver = {
    enable = true;
    xkb.layout = "us";
  };

  # Lightweight TUI Display Manager
  services.displayManager.ly = {
  	enable = true;
	settings = {
      animation = "none";
      animation_timeout_sec = 0;
      asterisk = "o";
      auth_fails = 10;
      blank_box = true;
      border_fg = "0x00FFFFFF";
      clear_password = false;
      default_input = "password";
      fg = "0x00FFFFFF";
      full_color = true;
      hide_borders = true;
      hide_key_hints = true;
      hide_keyboard_locks = true;
      hide_version_string = true;
      input_len = 38;
      lang = "en";
      margin_box_h = 6;
      margin_box_v = 4;
      min_refresh_delta = 5;
      numlock = false;
      save = true;
      text_in_center = false;
      vi_mode = false;
      vi_default_mode = "normal";
    };
   };

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
