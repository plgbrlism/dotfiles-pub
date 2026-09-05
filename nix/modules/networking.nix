{ pkgs, ... }:

{
  # --- NETWORKING BACKEND ---
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd"; # Fast, lightweight wireless backend
  };

  # Use the standard wireless daemon
  networking.wireless.iwd.enable = true;

  # --- FIREWALL CONFIGURATION ---
  networking.firewall = {
    enable = true;
    # Allow KDE Connect / GSConnect local device sync
    allowedTCPPortRanges = [
      { from = 1714; to = 1764; }
    ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; }
    ];
  };
}
