{ pkgs, ... }:

{
  # --- DOCKER CONTAINER VIRTUALISATION ---
  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay2";
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # User permission note: Ensure "docker" is added to extraGroups in configuration.nix
  # users.users.paul.extraGroups = [ "docker" ];

  # --- VIRTUALISATION PACKAGES ---
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
