{ config, pkgs, lib, inputs, ... }:
let
  secrets = config.age.secrets;
  inherit (inputs) attic;
in
{

  imports = [ attic.nixosModules.atticd ];

  age.secrets = {
    root_password_file = { file = ../../secrets/root_password.age; };
    attic_env = { file = ../../secrets/attic_env.age; };
  };

  networking.hostName = lib.mkForce "cache";
  networking = {
    firewall = {
      allowedUDPPorts = [ 443 ];
      allowedUDPPortRanges = [ ];
      allowedTCPPorts = [ 80 443 ];
      allowedTCPPortRanges = [ ];
    };
    domain = "";
    networkmanager.enable = false;
    dhcpcd.enable = false;
    useNetworkd = true;
    useDHCP = false;
  };
  systemd = {
    network = {
      enable = true;
      networks = {
        "20-wired" = {
          matchConfig.Name = "enp0s3";
          networkConfig.DHCP = "yes";
        };
      };
      wait-online.anyInterface = true;
    };
  };
  services = {
    resolved.enable = true;
    openssh = {
      enable = true;
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
    };
    nginx = {
      enable = true;
      package = pkgs.nginxQuic;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "cache.pointjig.de" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8080";
            recommendedProxySettings = true;
          };
        };
      };
    };
    atticd = {
      enable = true;
      credentialsFile = secrets.attic_env.path;
      settings = {
        allowed-hosts = [ "cache.pointjig.de" ];
        api-endpoint = "https://cache.pointjig.de/";
        database.url = "postgresql:///attic?host=/run/postgresql";
      };
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      ensureDatabases = [
        "attic"
      ];
      ensureUsers = [
        {
          name = "atticd";
          ensurePermissions = { "DATABASE attic" = "ALL PRIVILEGES"; };
        }
      ];
    };
  };


  users.mutableUsers = false;
  users.users.root = {
    passwordFile = secrets.root_password_file.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM"
    ];
  };

  env.auto-upgrade.enable = false;

  security = {
    rtkit.enable = true;
    acme = {
      acceptTerms = true;
      defaults.email = "shawn@pointjig.de";
    };
  };


}
