{ self', pkgs, ... }:
let
  fPkgs = self'.packages;
in
{
  shawn8901.desktop.enable = true;

  home.packages = [
    pkgs.keymapp
    pkgs.teamspeak_client
    pkgs.signal-desktop
    pkgs.portfolio
    fPkgs.jameica-fhs
    fPkgs.pytr
  ];
}
