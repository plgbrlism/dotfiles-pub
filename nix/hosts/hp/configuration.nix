{ config, pkgs, inputs, ... }:

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

  system.stateVersion = "25.05";

  users.users.paul = {
    isNormalUser = true;
    description = "paul";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "paul" ];
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Asia/Manila";
  i18n.defaultLocale = "en_US.UTF-8";
}
