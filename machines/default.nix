{lib, ...} @ inputs: {
  pointalpha = lib.mkSystem "pointalpha" inputs.nixpkgs-x86-64-v3;
  tank = lib.mkSystem "tank" inputs.nixpkgs-custom;
  pointjig = lib.mkSystem "pointjig" inputs.nixpkgs-23_05;
  shelter = lib.mkSystem "shelter" inputs.nixpkgs-23_05;
  next = lib.mkSystem "next" inputs.nixpkgs-22_11;
  cache = lib.mkSystem "cache" inputs.nixpkgs-custom;
  zenbook = lib.mkSystem "zenbook" inputs.nixpkgs-custom;
}
