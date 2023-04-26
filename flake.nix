{
  description = "Flake from a random person on the internet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-custom.url = "github:Shawn8901/nixpkgs/nixos-unstable-custom";
    nixpkgs-x86-64-v3.url = "github:Shawn8901/nixpkgs/x86-64-v3";
    nixpkgs-22_11.url = "github:NixOS/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-22_11";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
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
    stfc-bot = {
      url = "github:shawn8901/stfc-bot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs.lib) filterAttrs;
    inherit (builtins) mapAttrs elem;
    system = "x86_64-linux";
    lib = import ./lib inputs;
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
        "electron-13.6.9"
      ];
    };
  in rec {
    nixosModules = import ./modules/nixos/flake;
    flakeModules.homeManager = import ./modules/home-manager/flake;
    nixosConfigurations = import ./machines (inputs // {inherit lib;});

    hydraJobs = {
      nixos = mapAttrs (_: cfg: cfg.config.system.build.toplevel) (filterAttrs (name: _: !builtins.elem name ["pointalpha-vm"]) nixosConfigurations);
      "flake-update" = pkgs.releaseTools.aggregate {
        name = "flake-update";
        constituents = map (n: "nixos." + n) (builtins.attrNames hydraJobs.nixos);
      };
      inherit packages;
    };

    packages = let
      flakePkgs = pkgInstance: (import ./packages (inputs // {pkgs = pkgInstance;}));
    in {
      x86_64-linux = flakePkgs pkgs;
      aarch64-linux = filterAttrs (k: v: k == "wg-reresolve-dns") (flakePkgs nixpkgs.legacyPackages."aarch64-linux");
    };

    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        direnv
        nix-direnv
        statix
      ];
    };
  };
}
