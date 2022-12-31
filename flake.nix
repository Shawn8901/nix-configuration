{
  description = "Flake from a random person on the internet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-22_11.url = "github:NixOS/nixpkgs/nixos-22.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };
    nur.url = "github:nix-community/NUR";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stfc-bot = {
      url = "github:shawn8901/stfc-bot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mimir = {
      url = "github:shawn8901/mimir";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mimir-client = {
      url = "github:shawn8901/mimir-client";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (nixpkgs.lib) filterAttrs;
      inherit (builtins) mapAttrs elem;
      notBroken = x: !(x.meta.broken or false);
      system = "x86_64-linux";
      lib = import ./lib inputs;
      pkgs = nixpkgs.legacyPackages.${system};
    in
    rec {
      nixosModules = import ./modules/nixos;
      nixosConfigurations = import ./machines (inputs // { inherit lib; });

      hydraJobs = {
        packages = mapAttrs (sys: filterAttrs (_: pkg: (elem sys pkg.meta.platforms && notBroken pkg))) packages;
        nixos = mapAttrs (_: cfg: cfg.config.system.build.toplevel) nixosConfigurations;
      };

      packages.${system} = import ./packages (inputs // { inherit pkgs; })
        // lib.nixosConfigurationsAsPackages.configs;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          python3.pkgs.invoke
          python3.pkgs.autopep8
          direnv
          nix-direnv
          nix-diff
        ];
      };
    };
}
