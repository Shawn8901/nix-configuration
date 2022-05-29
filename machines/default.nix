{ self, ... }@inputs: {
  pointalpha = self.lib.mkSystem "pointalpha" inputs.nixpkgs;
  backup = self.lib.mkSystem "backup" inputs.nixpkgs;
  tank = self.lib.mkSystem "tank" inputs.nixpkgs;
}
