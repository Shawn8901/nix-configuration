{ self, ... }@inputs: {
  pointalpha = self.lib.mkSystem "pointalpha" inputs.nixpkgs-unstable;
  shelter = self.lib.mkSystem "shelter" inputs.nixpkgs-stable;
  tank = self.lib.mkSystem "tank" inputs.nixpkgs-stable;
}
