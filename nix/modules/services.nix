{ pkgs, ... }:

{
  #  BLUETOOTH & SYSTEM DAEMONS
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # Conserve battery on boot for Celeron laptop
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  services.blueman.enable = true;

  # Firmware updater service
  services.fwupd.enable = true;

  #  D-BUS & STORAGE AUTOMOUNTING
  services.dbus.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true; # Required for Nautilus trash/mount integration

  # User-space Polkit authentication agent
  security.polkit.enable = true;
}
