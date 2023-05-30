{
  pkgs,
  self',
  ...
}: let
  fPkgs = self'.packages;
in {
  home.packages = [
    pkgs.portfolio
    fPkgs.jameica-fhs
    fPkgs.pytr
  ];
}
