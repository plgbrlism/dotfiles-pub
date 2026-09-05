{ pkgs, ... }:

{
  # --- BOOTLOADER (UEFI) ---
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10; # Prevents /boot from filling up with old generations
    };
    efi.canTouchEfiVariables = true;
  };

  # --- KERNEL PARAMETERS ---
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "mem_sleep_default=s2idle"
    "acpi_sleep=nonvs"
  ];

  # Stable LTS Kernel for Celeron N4000
  boot.kernelPackages = pkgs.linuxPackages;

  # Enable Plymouth boot splash if desired, or keep boot log clean
  boot.consoleLogLevel = 3;
}
