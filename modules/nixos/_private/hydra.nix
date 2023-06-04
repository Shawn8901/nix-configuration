{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.shawn8901.hydra;
  inherit (lib) mkEnableOption mkOption mkDefault types literalExpression;
in {
  options = {
    shawn8901.hydra = {
      enable = mkEnableOption "Enables a preconfigured hydra instance";
      hostName = mkOption {
        type = types.str;
        description = "Hostname of the hydra instance";
      };
      mailAdress = mkOption {
        type = types.str;
        description = "Adress to send notifications to";
      };
      writeTokenFile = mkOption {
        type = types.path;
      };
      attic.package = mkOption {
        type = types.package;
      };
      builder = {
        sshKeyFile = mkOption {
          type = types.path;
        };
        userName = mkOption {
          type = types.str;
          default = "root";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedUDPPorts = [443];
      allowedTCPPorts = [80 443];
    };
    services = {
      nginx = {
        enable = mkDefault true;
        package = mkDefault pkgs.nginxQuic;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts."${cfg.hostName}" = {
          enableACME = true;
          forceSSL = true;
          http3 = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://${config.services.hydra.listenHost}:${toString config.services.hydra.port}";
            recommendedProxySettings = true;
          };
        };
      };
      postgresql = {
        enable = mkDefault true;
        ensureDatabases = ["hydra"];
        ensureUsers = [
          {
            name = "hydra";
            ensurePermissions = {"DATABASE hydra" = "ALL PRIVILEGES";};
          }
        ];
      };

      hydra = let
        advance_branch = pkgs.writeScriptBin "advance_branch" ''
          ${pkgs.curl}/bin/curl \
          -X POST \
          -H "Accept: application/vnd.github+json" \
          -H "Authorization: Bearer $(<${cfg.writeTokenFile})" \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          https://api.github.com/repos/shawn8901/nix-configuration/merges \
          -d '{"base":"main","head":"staging","commit_message":"Built flake update!"}'
        '';
      in {
        enable = true;
        listenHost = "127.0.0.1";
        port = 3000;
        package = pkgs.hydra_unstable;
        minimumDiskFree = 5;
        minimumDiskFreeEvaluator = 10;
        hydraURL = "https://${cfg.hostName}";
        notificationSender = cfg.mailAdress;
        useSubstitutes = true;
        extraConfig = ''
          evaluator_max_memory_size = 4096
          evaluator_initial_heap_size = ${toString (1 * 1024 * 1024 * 1024)}
          evaluator_workers = 4
          max_concurrent_evals = 2
          max_output_size = ${toString (5 * 1024 * 1024 * 1024)}
          max_db_connections = 150
          compress_build_logs = 1
          <github_authorization>
            shawn8901 = Bearer #github_token#
          </github_authorization>
          <runcommand>
            job = *:staging:flake-update
            command = ${advance_branch}/bin/advance_branch
          </runcommand>
        '';
      };
    };

    systemd.services = {
      hydra-init = {
        after = ["network-online.target"];
        preStart = lib.mkAfter ''
          sed -i -e "s|#github_token#|$(<${cfg.writeTokenFile})|" ${config.systemd.services.hydra-init.environment.HYDRA_DATA}/hydra.conf
        '';
      };
      attic-watch-store = {
        wantedBy = ["multi-user.target"];
        after = ["network-online.target"];
        description = "Upload all store content to binary catch";
        serviceConfig = {
          User = "attic";
          Restart = "always";
          ExecStart = " ${cfg.attic.package}/bin/attic watch-store nixos";
        };
      };
    };

    nix.buildMachines = let
      sshUser = cfg.builder.userName;
      sshKey = cfg.builder.sshKeyFile;
    in [
      {
        hostName = "localhost";
        systems = ["x86_64-linux" "i686-linux"];
        supportedFeatures = ["gccarch-x86-64-v3" "benchmark" "big-parallel" "kvm" "nixos-test"];
        maxJobs = 2;
        inherit sshUser sshKey;
      }
      {
        hostName = "cache.pointjig.de";
        systems = ["aarch64-linux"];
        supportedFeatures = ["benchmark" "big-parallel" "kvm" "nixos-test"];
        maxJobs = 2;
        inherit sshUser sshKey;
      }
    ];
    nix.settings.max-jobs = 3;
    nix.extraOptions = ''
      extra-allowed-uris = https://gitlab.com/api/v4/projects/rycee%2Fnmd https://git.sr.ht/~rycee/nmd https://github.com/zhaofengli/nix-base32.git https://github.com/zhaofengli/sea-orm
    '';
  };
}
