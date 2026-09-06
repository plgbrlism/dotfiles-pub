{ pkgs, ... }:

{
  #  DOCKER CONTAINER VIRTUALISATION
  virtualisation.docker = {
    enable = false;
    storageDriver = "overlay2";
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  #  VIRTUALISATION PACKAGES
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
