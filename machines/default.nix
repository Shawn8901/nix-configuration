{ self, lib, ... }@inputs: {
  pointalpha = lib.mkSystem "pointalpha" inputs.nixpkgs;
  shelter = lib.mkSystem "shelter" inputs.nixpkgs;
  tank = lib.mkSystem "tank" inputs.nixpkgs;
}
