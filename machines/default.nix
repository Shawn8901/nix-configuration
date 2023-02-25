{
  self,
  lib,
  ...
} @ inputs: {
  pointalpha = lib.mkSystem "pointalpha" inputs.nixpkgs-custom;
  tank = lib.mkSystem "tank" inputs.nixpkgs-custom;
  pointjig = lib.mkSystem "pointjig" inputs.nixpkgs-22_11;
  shelter = lib.mkSystem "shelter" inputs.nixpkgs-22_11;
  next = lib.mkSystem "next" inputs.nixpkgs-22_11;
  cache = lib.mkSystem "cache" inputs.nixpkgs-custom;
  zenbook = lib.mkSystem "zenbook" inputs.nixpkgs;
}
