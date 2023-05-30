{
  self,
  config,
  lib,
  moduleWithSystem,
  ...
}: {
  config.shawn8901.profiles = {
    home-manager = {
      base.modules = ["base.nix"];
      development.modules = ["development.nix"];
      browser.modules = ["browser.nix"];
      finance.modules = ["finance.nix"];
    };
    nixos = {
      base.modules = [
        "base.nix"
        "nix.nix"
      ];
      server = {
        modules = ["server.nix"];
        profiles = ["base"];
      };
      desktop = {
        modules = ["desktop.nix"];
        profiles = ["base" "managed-user"];
      };
      managed-user.modules = ["user-config.nix"];
      gaming.modules = ["gaming.nix"];
      optimized.modules = ["optimized.nix"];
    };
  };
}
