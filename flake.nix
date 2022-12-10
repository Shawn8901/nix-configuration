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
    nix-vscode-marketplace = {
      url = "github:AmeerTaweel/nix-vscode-marketplace";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
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
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = import ./lib inputs;
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      apps.${system}."update-packages" = {
        type = "app";
        program = "${self.packages.x86_64-linux.update-packages}/bin/update-packages";
      };

      nixosModules = import ./modules/nixos;
      nixosConfigurations = import ./machines (inputs // { inherit lib; });

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
