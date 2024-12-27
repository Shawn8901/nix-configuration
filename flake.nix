{
  description = "Flake from a random person on the internet";

  inputs = {
    nixpkgs.url = "github:Shawn8901/nixpkgs/nixos-unstable-custom";
    nixpkgs-stable.url = "github:Shawn8901/nixpkgs/nixos-24.11-custom";
    nixpkgs-deezer.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mimir = {
      url = "github:Shawn8901/mimir";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    mimir-client = {
      url = "github:Shawn8901/mimir-client";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    stfc-bot = {
      url = "github:Shawn8901/stfc-bot";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = false;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      fp-lib.modules.privateNamePrefix = "shawn8901";

      imports = [
        ./parts/type-defs/hydra-jobs.nix
        ./parts/type-defs/modules.nix
        ./parts/type-defs/system.nix

        ./parts/zrepl-helper.nix
        ./parts/modules.nix
        ./parts/system.nix

        ./modules
        ./packages
        ./machines
      ];

      flake.hydraJobs =
        let
          name = "merge-pr";
        in
        {
          ${name} = nixpkgs.legacyPackages.x86_64-linux.releaseTools.aggregate {
            inherit name;
            meta = {
              schedulingPriority = 10;
            };
            constituents = map (n: "nixos." + n) (nixpkgs.lib.attrNames self.nixosConfigurations);
          };
        };

      perSystem =
        { pkgs, ... }:
        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              direnv
              nix-direnv
              statix
            ];
          };
        };
    };
}
