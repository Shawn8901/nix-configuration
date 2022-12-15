{ self, lib, ... }@inputs: {
  pointalpha = lib.mkSystem "pointalpha" inputs.nixpkgs-x86_64-v2;
  # pointalpha = lib.mkSystem "pointalpha" inputs.nixpkgs;
  pointjig = lib.mkSystem "pointjig" inputs.nixpkgs-22_11;
  shelter = lib.mkSystem "shelter" inputs.nixpkgs-22_11;
  tank = lib.mkSystem "tank" inputs.nixpkgs;
  next = lib.mkSystem "next" inputs.nixpkgs-22_11;
}
