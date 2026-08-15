{ pkgs, ... }:

{
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    displayManager.ly = {
      enable = true;
    };
  };

  services.displayManager = {
    ly = {
      enable = true;
    };
  };

  services.xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.systemPackages = with pkgs; [
    xdg-utils
    xdg-user-dirs
    mate-polkit
    accountsservice
    lxappearance
    nwg-look
  ];

  services.mate = {
    atril.enable = false;
    eom.enable = false;
  };
}
