{
  description = "NixOS configuration for HP Notebook 14-ck0115tu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

	scenefx = {
      url = "github:wlrfx/scenefx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    swayfx = {
      url = "github:willpower3309/swayfx";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.scenefx.follows = "scenefx";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, swayfx, scenefx, ... } @ inputs: {
    nixosConfigurations.hp = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # Main host configuration
        ./hosts/hp/configuration.nix

        # Home Manager integration module
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users.paul = import ./home/default.nix;
          };
        }
      ];
    };
  };
}
