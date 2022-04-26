{
  description = "A very basic flake";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:Shawn8901/nixpkgs/prometheus";
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    flake-utils = { url = "github:gytis-ivaskevicius/flake-utils-plus"; inputs.nixpkgs.follows = "nixpkgs"; };
    nur = { url = "github:nix-community/NUR"; inputs.nixpkgs.follows = "nixpkgs"; };
    pre-commit-hooks = { url = "github:cachix/pre-commit-hooks.nix"; inputs.nixpkgs.follows = "nixpkgs"; };
    agenix = { url = "github:ryantm/agenix"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { self, nixpkgs, flake-utils, nur, home-manager, agenix, pre-commit-hooks, ... }@inputs:

    flake-utils.lib.mkFlake rec {
      inherit self inputs;

      supportedSystems = [ "x86_64-linux" ];

      sharedOverlays = [
        self.overlays.default
        nur.overlay
        agenix.overlay
      ];

      channelsConfig.allowUnfree = true;

      hostDefaults.extraArgs = { hosts = self.nixosConfigurations; helpers = import ./helpers { lib = nixpkgs.lib; }; };
      hostDefaults.modules = [
        agenix.nixosModule
        home-manager.nixosModule
        {
          home-manager = {
            extraSpecialArgs = {
              inherit inputs self;
            };
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
          ];
        };
        checks = {
          pre-commit-hooks = inputs.pre-commit-hooks.lib."${channels.nixpkgs.system}".run {
            src = self;
            hooks.nixpkgs-fmt.enable = true;
            hooks.shellcheck.enable = true;
          };
        };
      };
    };
}
