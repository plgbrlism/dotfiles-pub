{ pkgs, ... }:

{
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [
      { from = 1714; to = 1764; }
    ];
  };
}
