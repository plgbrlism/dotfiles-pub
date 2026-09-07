{ config, pkgs, ... }:

{
  nix.distributedBuilds = true;

  nix.buildMachines = [
    {
      hostName = "192.168.1.4";
      sshUser = "paul";
      sshKey = "/root/.ssh/id_ed25519";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 8;
      speedFactor = 4;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
    }
  ];

  nix.extraOptions = ''
    builders-use-substitutes = true
  '';
}
