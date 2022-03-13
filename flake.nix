{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    flake-utils.url = "github:gytis-ivaskevicius/flake-utils-plus";
    nur = { url = "github:nix-community/NUR"; inputs.nixpkgs.follows = "nixpkgs"; };
    pre-commit-hooks = { url = "github:cachix/pre-commit-hooks.nix"; inputs.nixpkgs.follows = "nixpkgs"; };
    deploy-rs = { url = "github:serokell/deploy-rs"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { self, nixpkgs, flake-utils, nur, home-manager, pre-commit-hooks, deploy-rs, ... }@inputs:

    flake-utils.lib.mkFlake {
      inherit self inputs;

      supportedSystems = [ "x86_64-linux" ];

      sharedOverlays = [
        self.overlay
        nur.overlay
      ];

      channelsConfig.allowUnfree = true;

      hostDefaults.modules = [
        home-manager.nixosModule
        ./modules
        ./.secrets
      ];

      hosts = {
        pointalpha.modules = [ ./machines/pointalpha ];
        pointjig.modules = [ ./machines/pointjig ];
      };

      overlay = import ./overlays;

      deploy.nodes = {
        pointjig = {
          hostname = "pointjig";
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.pointjig;
          };
        };
      };
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      outputsBuilder = channels: with channels.nixpkgs; {
        devShell = mkShell {
          packages = [ nixpkgs-fmt lefthook ];
          inherit (self.checks.${system}.pre-commit-check) shellHook;
        };

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks.nixpkgs-fmt.enable = true;
            hooks.shellcheck.enable = true;
          };
        };
      };
    };
}
