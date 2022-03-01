{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = { url = "github:nix-community/home-manager"; inputs.nixpkgs.follows = "nixpkgs"; };
    flake-utils.url = "github:gytis-ivaskevicius/flake-utils-plus";
    nur = { url = "github:nix-community/NUR"; inputs.nixpkgs.follows = "nixpkgs"; };
    pre-commit-hooks = { url = "github:cachix/pre-commit-hooks.nix"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, pre-commit-hooks, ... }@inputs:

    flake-utils.lib.mkFlake {
      inherit self inputs;

      supportedSystems = [ "x86_64-linux" ];

      sharedOverlays = [
        self.overlay
        inputs.nur.overlay
      ];

      channelsConfig.allowUnfree = true;

      hostDefaults = {
        modules = [
          ./modules/nix.nix
          ./.secrets
        ];
      };

      hosts = {
        pointalpha.modules = [
          ./machines/pointalpha
          ./home
          ./modules
          home-manager.nixosModule
        ];
      };


      overlay = import ./overlays { inherit inputs; };

      outputsBuilder = channels: with channels.nixpkgs; {
        devShell = mkShell {
          packages = [ nixpkgs-fmt lefthook ];
          inherit (self.checks.${system}.pre-commit-check) shellHook;
        };

        checks.pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks.nixpkgs-fmt.enable = true;
          hooks.shellcheck.enable = true;
        };
      };
    };
}
