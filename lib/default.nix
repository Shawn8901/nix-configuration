inputs:
let
  mkSystem = import ./mk-system.nix (inputs // { inherit zrepl; });
  nixosConfigurationsAsPackages = import ./nixos-config-as-packages.nix inputs;
  zrepl = import ./zrepl.nix inputs;
in
{
  inherit mkSystem nixosConfigurationsAsPackages zrepl;
}
