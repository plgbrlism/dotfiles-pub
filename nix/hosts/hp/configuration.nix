{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/boot.nix
    ../../modules/hardware.nix
    ../../modules/networking.nix
    ../../modules/audio.nix
    ../../modules/desktop.nix
    ../../modules/window-managers.nix
    ../../modules/fonts.nix
    ../../modules/virtualisation.nix
    ../../modules/power.nix
    ../../modules/programmes.nix
    ../../modules/packages.nix
    ../../modules/services.nix
  ];

  # Hostname & State Version
  networking.hostName = "hp";
  system.stateVersion = "26.05";

  # User Configuration
  users.users.paul = {
    isNormalUser = true;
    description = "paul";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "docker" ];
    shell = pkgs.zsh;
  };

  # Enable system-wide interactive shell hooks
  programs.zsh.enable = true;

  # Nix Package Manager & Flakes configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "paul" ];
    auto-optimise-store = true;
  };

  # Allow Unfree Packages Globally
  nixpkgs.config.allowUnfree = true;

  # Time Zone & Locale Settings
  time.timeZone = "Asia/Manila";
  i18n.defaultLocale = "en_US.UTF-8";
}
