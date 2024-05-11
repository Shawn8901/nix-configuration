{
  self',
  inputs',
  pkgs,
  ...
}:
let
  fPkgs = self'.packages;
  attic-client = inputs'.attic.packages.attic-client;
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
    attic-client
  ];

  systemd.user.services.attic-watch-store = {
    Unit = {
      Description = "Upload all store content to binary catch";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${attic-client}/bin/attic watch-store nixos";
    };
  };
}
