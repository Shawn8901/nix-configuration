{ self, ... }@inputs: {
  pointalpha = self.lib.mkSystem "pointalpha" inputs.nixpkgs;
  shelter = self.lib.mkSystem "shelter" inputs.nixpkgs;
  tank = self.lib.mkSystem "tank" inputs.nixpkgs;
}
