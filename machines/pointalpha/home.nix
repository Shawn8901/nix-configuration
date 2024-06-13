{
  self',
  inputs',
  pkgs,
  lib,
  ...
}:
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
    pkgs.attic-client
    fPkgs.jameica-fhs
    fPkgs.pytr
  ];

  systemd.user.services.attic-watch-store = {
    Unit = {
      Description = "Upload all store content to binary catch";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.attic-client} watch-store nixos";
    };
  };
}
