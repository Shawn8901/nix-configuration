{
  self,
  self',
  config,
  pkgs,
  lib,
  inputs',
  ...
}:
let
  inherit (config.sops) secrets;
  fPkgs = self'.packages;
in
{
  sops.secrets = {
    root.neededForUsers = true;
    stalwart-fallback-admin = { };
  };

  systemd.network = {
    enable = true;
    networks = {
      "20-wired" = {
        matchConfig.Name = "enp6s18";
        networkConfig = {
          Address = [
            "134.255.226.117/28"
            "2a05:bec0:1:16::117/64"
          ];
          DNS = "8.8.8.8";
          Gateway = "134.255.226.113";
        };
        routes = [
          {
            routeConfig = {
              Gateway = "2a05:bec0:1:16::1";
              GatewayOnLink = "yes";
            };
          }
        ];
      };
    };
    wait-online.anyInterface = true;
  };

  services = {
    fstrim.enable = true;
    stalwart-mail = {
      enable = true;
      package = fPkgs.stalwart-mail;
      environmentFile = secrets.stalwart-fallback-admin.path;
      hostname = "mail.trivia-gs.de";
      settings.acme."letsencrypt" = {
        challenge = "tls-alpn-01";
        contact = [ "barannikov.de@gmail.com" ];
        cache = "%{BASE_PATH}%/etc/acme";
        domains = [ "${config.services.stalwart-mail.hostname}" ];
        default = true;
      };
    };
  };

  users = {
    mutableUsers = false;
    users.root = {
      hashedPasswordFile = secrets.root.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM shawn"
      ];
    };
  };

  shawn8901 = {
    server.enable = true;
  };
}
