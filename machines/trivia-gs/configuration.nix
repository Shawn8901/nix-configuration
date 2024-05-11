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

  systemd.services.stalwart-mail.serviceConfig = {
    # Hack to read acme certificate from nginx
    Group = "nginx";
  };

  services = {
    fstrim.enable = true;
    stalwart-mail = rec {
      enable = true;
      package = fPkgs.stalwart-mail;
      environmentFile = secrets.stalwart-fallback-admin.path;
      hostname = "mail.trivia-gs.de";
      # http = {
      #   listenAddress = "127.0.0.1";
      #   port = 8080;
      #   openFirewall = false;
      #   tls = false;
      # };
      # settings = {
      #   certificate.default = {
      #     private-key = "%{file:/var/lib/acme/${hostname}/key.pem}%";
      #     cert = "%{file:/var/lib/acme/${hostname}/cert.pem}%";
      #     default = true;
      #   };
      #   server.http.use-x-forwarded = true;
      # };
    };
    nginx = {
      enable = false;
      package = pkgs.nginxQuic;
      virtualHosts."${config.services.stalwart-mail.hostname}" = {
        serverName = config.services.stalwart-mail.hostname;
        forceSSL = true;
        enableACME = true;
        http3 = true;
        kTLS = true;
        locations = {
          "/" = {
            proxyPass = "http://localhost:8080";
            recommendedProxySettings = true;
          };
        };
      };
    };
  };

  security = {
    acme = {
      acceptTerms = true;
      defaults.email = "barannikov.de@gmail.com";
      # certs."${config.services.stalwart-mail.hostname}".reloadServices = [ "stalwart-mail" ];
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