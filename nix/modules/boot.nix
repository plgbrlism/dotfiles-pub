{ pkgs, ... }:

{
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = true;
    useOSProber = false;
  };

  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "loglevel=3"
    "quiet"
    "mem_sleep_default=s2idle"
    "acpi_sleep=nonvs"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };
}
