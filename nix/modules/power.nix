{ pkgs, ... }:

{
  #  POWER MANAGEMENT
  # Automatic power tuning via Powertop system service
  powerManagement.powertop.enable = true;

  #  MEMORY & SWAP COMPRESSION
  # Helps maintain system responsiveness on 4GB RAM
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
  };
}
