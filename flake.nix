{
  description = "A very basic flake";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-22.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    statix = {
      url = "github:nerdypepper/statix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs = { self, ... }@inputs: {
    nixosModules = import ./modules/nixos inputs;
    nixosConfigurations = import ./machines inputs;

    lib = import ./lib inputs;

    packages.x86_64-linux = (import ./packages inputs)
      // self.lib.nixosConfigurationsAsPackages.x86_64-linux;

    devShells.x86_64-linux.default =
      let pkgs = inputs.nixpkgs-stable.legacyPackages.x86_64-linux;
      in pkgs.mkShell {
        packages = [
          self.packages.x86_64-linux.statix
          pkgs.python3.pkgs.invoke
          pkgs.direnv
          pkgs.nix-direnv
          pkgs.nixfmt
        ];
      };
  };
}
