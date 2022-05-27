{
  description = "A very basic flake";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:gytis-ivaskevicius/flake-utils-plus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    statix = {
      url = "github:nerdypepper/statix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, ... }@inputs:

    inputs.flake-utils.lib.mkFlake rec {
      inherit self inputs;

      supportedSystems = [ "x86_64-linux" ];

      sharedOverlays =
        [ self.overlays.default inputs.nur.overlay inputs.agenix.overlay ];

      channelsConfig.allowUnfree = true;

      hostDefaults.extraArgs = {
        hosts = self.nixosConfigurations;
        helpers = import ./helpers { inherit (inputs.nixpkgs) lib; };
      };
      hostDefaults.modules = [
        inputs.agenix.nixosModule
        inputs.home-manager.nixosModule
        {
          home-manager = {
            extraSpecialArgs = { inherit inputs self; };
            useUserPackages = true;
            useGlobalPkgs = true;
            sharedModules = [ ./modules/home ];
          };
        }
        ./modules
      ];

      hosts = {
        pointalpha.modules = [ ./machines/pointalpha ];
        pointjig.modules = [ ./machines/pointjig ];
        tank.modules = [ ./machines/tank ];
        backup.modules = [ ./machines/backup ];
      };

      overlays.default = import ./overlays;

      outputsBuilder = channels: {
        devShell = channels.nixpkgs.mkShell {
          nativeBuildInputs = with channels.nixpkgs; [
            python3.pkgs.invoke
            direnv
            nix-direnv
            nixfmt
            statix

          ];
        };
        checks = { };
      };
    };
}
