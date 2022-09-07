{
  description = "Flake from a random person on the internet";

  inputs = rec {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixinate = {
      url = "github:matthewcroughan/nixinate";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nur.url = "github:nix-community/NUR";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    nix-vscode-marketplace = {
      url = "github:AmeerTaweel/nix-vscode-marketplace";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, nixinate, ... }@inputs:
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
    in
    {
      apps = nixinate.nixinate.x86_64-linux self;
      nixosModules = import ./modules/nixos (inputs // { inherit lib system; });
      nixosConfigurations = import ./machines (inputs // { inherit lib nPkgs sPkgs uPkgs system; });

      packages.${system} = import ./packages (inputs // { inherit system sPkgs uPkgs; });

      devShells.${system}.default = sPkgs.mkShell {
        packages = with sPkgs; [
          python3.pkgs.invoke
          direnv
          nix-direnv
          nix-diff
        ];
      };
    };
}
