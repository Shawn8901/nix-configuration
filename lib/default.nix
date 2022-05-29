inputs: {
  mkSystem = import ./mk-system.nix inputs;
  nixosConfigurationsAsPackages = import ./nixos-config-as-packages.nix inputs;
  zrepl = import ./zrepl.nix inputs;
}
