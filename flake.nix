{
  description = "Flake from a random person on the internet";

  inputs = {
    nixpkgs.url = "github:Shawn8901/nixpkgs/nixos-unstable-custom";
    nixpkgs-x86-64-v3.url = "github:Shawn8901/nixpkgs/x86-64-v3";
    nixpkgs-23_05.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-23_05";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-23_05.follows = "nixpkgs-23_05";
      inputs.flake-compat.follows = "flake-compat";
    };
    mimir = {
      url = "github:shawn8901/mimir";
      inputs.nixpkgs.follows = "nixpkgs-23_05";
    };
    mimir-client = {
      url = "github:shawn8901/mimir-client";
      inputs.nixpkgs.follows = "nixpkgs-23_05";
    };
    stfc-bot = {
      url = "github:shawn8901/stfc-bot";
      inputs.nixpkgs.follows = "nixpkgs-23_05";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    flake-parts = {url = "github:hercules-ci/flake-parts";};
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      debug = true;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./parts/hydra-jobs.nix
        ./parts/flake-modules.nix
        ./parts/module-generator.nix
        ./parts/system.nix
        ./parts/zrepl-helper.nix
        ./parts/profiles.nix

        ./modules/nixos
        ./modules/home-manager

        ./profiles
        ./packages
        ./machines
      ];

      perSystem = {pkgs, ...}: {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            direnv
            nix-direnv
            statix
          ];
        };
      };
    };

  #   hydraJobs = {
  #     nixos = mapAttrs (_: cfg: cfg.config.system.build.toplevel) (filterAttrs (name: _: !builtins.elem name ["pointalpha-vm"]) nixosConfigurations);
  #     "flake-update" = pkgs.releaseTools.aggregate {
  #       name = "flake-update";
  #       meta = {schedulingPriority = 50;};
  #       constituents = map (n: "nixos." + n) (builtins.attrNames hydraJobs.nixos);
  #     };
}
