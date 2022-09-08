{
  description = "Flake from a random person on the internet";

  inputs = rec {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.utils.follows = "flake-utils";
    };
    nur.url = "github:nix-community/NUR";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    nix-vscode-marketplace = {
      url = "github:AmeerTaweel/nix-vscode-marketplace";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };
    mach-nix = {
      url = "github:DavHau/mach-nix/3.5.0";
      inputs.nixpkgs.follows = "nixpkgs-stable";
      inputs.pypi-deps-db.follows = "pypi-deps-db";
      inputs.flake-utils.follows = "flake-utils";
    };
    pypi-deps-db = {
      url = github:DavHau/pypi-deps-db;
      inputs.mach-nix.follows = "mach-nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, mach-nix, ... }@inputs:
    let
      system = "x86_64-linux";
      nPkgs = (import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [ inputs.nur.outputs.overlay ];
      });
      sPkgs = (import inputs.nixpkgs-stable { inherit system; });
      uPkgs = (import inputs.nixpkgs-unstable { inherit system; });
      lib = import ./lib (inputs // { inherit lib nPkgs sPkgs uPkgs system; });
      machNix = import mach-nix { inherit sPkgs; };
    in
    {
      nixosModules = import ./modules/nixos (inputs // { inherit lib system; });
      nixosConfigurations = import ./machines (inputs // { inherit lib nPkgs sPkgs uPkgs system; });

      packages.${system} = import ./packages (inputs // { inherit system sPkgs uPkgs machNix; })
        // lib.nixosConfigurationsAsPackages.configs;

      devShells.${system}.default = sPkgs.mkShell {
        packages = with sPkgs; [ python3.pkgs.invoke direnv nix-direnv nix-diff ];
      };
    };
}
