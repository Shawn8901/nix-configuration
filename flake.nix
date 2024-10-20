{
  description = "Flake from a random person on the internet";

  inputs = {
    nixpkgs.url = "github:Shawn8901/nixpkgs/nixos-unstable-custom";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-deezer.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    mimir = {
      url = "github:Shawn8901/mimir";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mimir-client = {
      url = "github:Shawn8901/mimir-client";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stfc-bot = {
      url = "github:Shawn8901/stfc-bot";
      inputs.nixpkgs.follows = "nixpkgs";
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
    fp-rndp-lib = {
      url = "github:Shawn8901/fp-rndp-lib";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
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

      fp-rndp-lib.root = ./.;
      fp-rndp-lib.modules.privateNamePrefix = "shawn8901";

      imports = [
        inputs.fp-rndp-lib.flakeModule

        ./parts/zrepl-helper.nix

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
