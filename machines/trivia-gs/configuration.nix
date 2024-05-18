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

  networking.firewall = {
    allowedUDPPorts = [ 443 ];
    allowedTCPPorts = [
      80
      443
    ];
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
      http = {
        listenAddress = "127.0.0.1";
        port = 8080;
        openFirewall = false;
        tls = false;
      };
      environmentFile = secrets.stalwart-fallback-admin.path;
      hostname = "mail.trivia-gs.de";
      settings = {
        certificate.default = {
          private-key = "%{file:/var/lib/acme/mail.pointjig.de/key.pem}%";
          cert = "%{file:/var/lib/acme/mail.pointjig.de/cert.pem}%";
          default = true;
        };
        server.http.use-x-forwarded = true;
      };
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      virtualHosts."${config.services.stalwart-mail.hostname}" = {
        serverName = "${config.services.stalwart-mail.hostname}";
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
  systemd.services.stalwart-mail.serviceConfig = {
    # Hack to read acme certificate from nginx
    Group = "nginx";
  };

  security = {
    acme = {
      acceptTerms = true;
      defaults.email = "barannikov.de@gmail.com";
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
