{lib, ...} @ inputs: {
  pointalpha-vm = lib.mkSystem "pointalpha-vm" inputs.nixpkgs-x86-64-v3;
  pointalpha = lib.mkSystem "pointalpha" inputs.nixpkgs-x86-64-v3;
  tank = lib.mkSystem "tank" inputs.nixpkgs-custom;
  pointjig = lib.mkSystem "pointjig" inputs.nixpkgs-22_11;
  shelter = lib.mkSystem "shelter" inputs.nixpkgs-22_11;
  next = lib.mkSystem "next" inputs.nixpkgs-22_11;
  cache = lib.mkSystem "cache" inputs.nixpkgs-custom;
  zenbook = lib.mkSystem "zenbook" inputs.nixpkgs-custom;
}
