# Hardware configuration for HPCK14 (Celeron N4000, 4GB RAM)
# This file will be overwritten by nixos-generate-config on install.
# After first boot, run: sudo nixos-generate-config --show-hardware-config > /path/to/nix/hosts/hp/hardware-configuration.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Kernel modules (will be filled by nixos-generate-config)
  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Filesystems — UPDATE THESE UUIDs for your HPCK14
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/XXXX-XXXX";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
    fsType = "ext4";
  };

  swapDevices = [ ];

  # Intel Celeron N4000 (Gemini Lake)
  hardware.cpu.intel.updateMicrocode = true;

  # Gives applications access to GPU
  hardware.graphics.enable = true;

  # High-DPI scaling
  hardware.graphics.enable32 = true;
}
