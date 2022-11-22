{ self, lib, ... }@inputs: {
  pointalpha = lib.mkSystem "pointalpha" inputs.nixpkgs;
  pointjig = lib.mkSystem "pointjig" inputs.nixpkgs;
  shelter = lib.mkSystem "shelter" inputs.nixpkgs;
  tank = lib.mkSystem "tank" inputs.nixpkgs;
  next = lib.mkSystem "next" inputs.nixpkgs;
  vmtest = lib.mkSystem "vmtest" inputs.nixpkgs;
}
