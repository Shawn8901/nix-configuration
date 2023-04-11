{
  self,
  config,
  pkgs,
  ...
}: let
  inherit (pkgs.hostPlatform) system;

  fPkgs = self.packages.${system};
in {
  home-manager.users.shawn = {
    home.packages = with pkgs; [
      plasma-integration
    ];
    programs.ssh = {
      enable = true;
      matchBlocks = {
        tank = {
          hostname = "tank";
          user = "root";
        };
        shelter = {
          hostname = "shelter.pointjig.de";
          user = "root";
        };
        cache = {
          hostname = "cache.pointjig.de";
          user = "root";
        };
        sap = {
          hostname = "clansap.org";
          user = "root";
        };
        next = {
          hostname = "next.clansap.org";
          user = "root";
        };

        pointjig = {
          hostname = "pointjig.de";
          user = "root";
        };
        sapsrv01 = {
          hostname = "sapsrv01.clansap.org";
          user = "root";
        };
        sapsrv02 = {
          hostname = "sapsrv02.clansap.org";
          user = "root";
        };
      };
    };

    xdg.enable = true;
    xdg.mime.enable = true;
    xdg.configFile."chromium-flags.conf".text = ''
      --ozone-platform-hint=auto
      --enable-features=WaylandWindowDecorations
    '';
  };
}
