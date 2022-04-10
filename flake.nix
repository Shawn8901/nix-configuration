{
  description = "A very basic flake";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:Shawn8901/nixpkgs/pycurl";
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    flake-utils.url = "github:gytis-ivaskevicius/flake-utils-plus";
    nur = { url = "github:nix-community/NUR"; inputs.nixpkgs.follows = "nixpkgs"; };
    pre-commit-hooks = { url = "github:cachix/pre-commit-hooks.nix"; inputs.nixpkgs.follows = "nixpkgs"; };
    deploy-rs = { url = "github:serokell/deploy-rs"; inputs.nixpkgs.follows = "nixpkgs"; };
    agenix = {url = "github:ryantm/agenix"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { self, nixpkgs, flake-utils, nur, home-manager, agenix, deploy-rs, pre-commit-hooks, ... }@inputs:

    flake-utils.lib.mkFlake {
      inherit self inputs;

      supportedSystems = [ "x86_64-linux" ];

      sharedOverlays = [
        self.overlays.default
        nur.overlay
        deploy-rs.overlay
        agenix.overlay
      ];

      channelsConfig.allowUnfree = true;

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
          };
        }
        ./modules
      ];

      hosts = {
        pointalpha.modules = [ ./machines/pointalpha ];
        pointjig.modules = [ ./machines/pointjig ];
        tank.modules = [ ./machines/tank ];
      };

      overlays.default = import ./overlays;

      deploy.nodes = {
        pointjig = {
          hostname = "pointjig";
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.pointjig;
          };
        };
        tank = {
          hostname = "tank";
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.tank;
          };
        };
      };
    };
}
