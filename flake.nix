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

  outputs = { self, ... }@inputs: let
    nPkgs = (import inputs.nixpkgs-stable {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [ inputs.nur.outputs.overlay ];
    });
    sPkgs = (import inputs.nixpkgs-stable { system = "x86_64-linux"; });
  in {
    inherit nPkgs sPkgs;

    nixosModules = import ./modules/nixos inputs;
    nixosConfigurations = import ./machines inputs;

    lib = import ./lib inputs;

    packages.x86_64-linux = (import ./packages inputs)
      // self.lib.nixosConfigurationsAsPackages.x86_64-linux;

    devShells.x86_64-linux.default = sPkgs.mkShell {
        packages = with sPkgs; [ python3.pkgs.invoke direnv nix-direnv nix-diff nixfmt ];
      };
  };
}
