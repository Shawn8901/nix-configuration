inputs:
let
  mkSystem = import ./mk-system.nix (inputs // { inherit zrepl; });
  zrepl = import ./zrepl.nix inputs;
in
{
  inherit mkSystem zrepl;
}
