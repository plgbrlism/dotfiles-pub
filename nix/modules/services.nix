{ pkgs, ... }:

{
  #  BLUETOOTH & SYSTEM DAEMONS
  hardware.bluetooth = {
    enable = false;
    powerOnBoot = false; # Conserve battery on boot for Celeron laptop
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  services.blueman.enable = false;

  # Firmware updater service
  services.fwupd.enable = false;

  #  D-BUS & STORAGE AUTOMOUNTING
  services.dbus.enable = true;
  services.udisks2.enable = false;
  services.gvfs.enable = false; # Required for Nautilus trash/mount integration

  # User-space Polkit authentication agent
  security.polkit.enable = true;

  # secure shell
  services.openssh.enable = true;
}
