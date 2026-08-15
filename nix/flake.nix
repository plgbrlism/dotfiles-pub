{
  description = "NixOS config for HPCK14 laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... } @ inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (final: prev: {
            swayfx = prev.swayfx.overrideAttrs (old: {
              version = "0.6";
              src = prev.fetchFromGitHub {
                owner = "wlrfx";
                repo = "swayfx";
                rev = "v0.6";
                hash = "sha256-1KzWBTmF2KwGpMz7Tt4pGq3QwK3p3q3q3q3q3q3q3q3=";
              };
              buildInputs = (old.buildInputs or []) ++ [ prev.scenefx ];
            });
          })
        ];
      };
    in {
      nixosConfigurations.hp = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/hp/configuration.nix
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
