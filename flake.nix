{
  description = "Flake from a random person on the internet";

  inputs = rec {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    nix-vscode-marketplace = {
      url = "github:AmeerTaweel/nix-vscode-marketplace";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    flake-utils.url = "github:numtide/flake-utils";
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
      system = "x86_64-linux";
      nPkgs = (import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ inputs.nur.outputs.overlay ];
      });
      pkgs = (import inputs.nixpkgs { inherit system; });
      lib = import ./lib (inputs // { inherit lib nPkgs pkgs system; });
    in
    {
      nixosModules = import ./modules/nixos (inputs // { inherit lib system; });
      nixosConfigurations = import ./machines (inputs // { inherit lib nPkgs pkgs system; });

      packages.${system} = import ./packages (inputs // { inherit system pkgs; })
        // lib.nixosConfigurationsAsPackages.configs;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ python3.pkgs.invoke direnv nix-direnv nix-diff ];
      };
    };
}
