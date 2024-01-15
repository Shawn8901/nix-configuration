{
  description = "Flake from a random person on the internet";

  inputs = {
    nixpkgs-unstable.url = "github:Shawn8901/nixpkgs/nixos-unstable-custom";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs-stable";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
      inputs.crane.follows = "crane";
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager-stable = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-23.11";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-23_11.follows = "nixpkgs-stable";
      inputs.flake-compat.follows = "flake-compat";
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
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    flake-parts = { url = "github:hercules-ci/flake-parts"; };
    fp-rndp-lib = {
      url = "github:Shawn8901/fp-rndp-lib";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-parts.follows = "flake-parts";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = false;

      systems = [ "x86_64-linux" "aarch64-linux" ];

      fp-rndp-lib.root = ./.;
      fp-rndp-lib.modules.privateNamePrefix = "shawn8901";

      imports = [
        inputs.fp-rndp-lib.flakeModule

        ./parts/zrepl-helper.nix

        ./modules
        ./packages
        ./machines
      ];

      flake.hydraJobs = let
        lib = nixpkgs.lib;
        name = "merge-pr";
        hosts = map (n: "nixos." + n) (lib.attrNames self.nixosConfigurations);
        packages = lib.flatten (lib.attrValues (lib.mapAttrs
          (system: attr: map (p: "${system}.${p}") (lib.attrNames attr))
          self.packages));
      in {
        ${name} = nixpkgs.legacyPackages.x86_64-linux.releaseTools.aggregate {
          inherit name;
          meta = { schedulingPriority = 10; };
          constituents = hosts;
        };
      };

      perSystem = { pkgs, ... }: {
        devShells.default =
          pkgs.mkShell { packages = with pkgs; [ direnv nix-direnv statix ]; };
      };
    };
}
