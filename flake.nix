{
  description = "A very basic flake";

  inputs = rec {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs = { self, ... }@inputs:
    let
      system = "x86_64-linux";
      nPkgs = (import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [ inputs.nur.outputs.overlay ];
      });
      sPkgs = (import inputs.nixpkgs-stable { inherit system; });
      lib = import ./lib (inputs // { inherit lib nPkgs sPkgs system; });
    in
    {
      nixosModules = import ./modules/nixos (inputs // { inherit lib system; });
      nixosConfigurations = import ./machines (inputs // { inherit lib nPkgs sPkgs system; });

      packages.${system} = (import ./packages (inputs // { inherit system; pkgs = sPkgs; }))
        // lib.nixosConfigurationsAsPackages.configs;

      devShells.${system}.default = sPkgs.mkShell {
        packages = with sPkgs; [ python3.pkgs.invoke direnv nix-direnv nix-diff ];
      };
    };
}
