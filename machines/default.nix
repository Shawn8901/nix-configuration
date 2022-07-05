{ self, lib, ... }@inputs: {
  pointalpha = lib.mkSystem "pointalpha" inputs.nixpkgs-unstable;
  shelter = lib.mkSystem "shelter" inputs.nixpkgs-stable;
  tank = lib.mkSystem "tank" inputs.nixpkgs-stable;
}
