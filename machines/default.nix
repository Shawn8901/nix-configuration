{ self, lib, ... }@inputs: {
  pointalpha = lib.mkSystem "pointalpha" inputs.nixpkgs-unstable;
  shelter = lib.mkSystem "shelter" inputs.nixpkgs-unstable;
  tank = lib.mkSystem "tank" inputs.nixpkgs-unstable;
}
