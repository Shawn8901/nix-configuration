{
  pkgs,
  self',
  lib,
  ...
}: let
  fPkgs = self'.packages;
in {
  xdg.enable = true;
  xdg.mime.enable = true;
  xdg.configFile."chromium-flags.conf".text = ''
    --ozone-platform-hint=auto
    --enable-features=WaylandWindowDecorations
  '';
  services = {
    nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
    gpg-agent = {
      enable = true;
      pinentryFlavor = "qt";
    };
  };

  home.packages = with pkgs;
    [
      samba
      nextcloud-client
      keepassxc
      (discord.override {nss = pkgs.nss_latest;})
      teamspeak_client
      signal-desktop
      wally-cli
      vlc
      plasma-integration
      libreoffice-qt
      krita
    ]
    ++ (with fPkgs; [
      deezer
      nas
      rogerrouter
      s25rttr
      vdhcoapp
    ]);
}
