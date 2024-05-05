{
  config,
  lib,
  perSystem,
  withSystem,
  inputs,
  ...
}:
let
  genPackageName = system: packageName: "${system}.${packageName}";
  inherit (builtins) elem;
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      packages = {
        pg-upgrade = pkgs.callPackage ./pg-upgrade { };
        generate-zrepl-ssl = pkgs.callPackage ./shellscripts/generate-zrepl-ssl.nix { };
        vm-grafana-datasource = pkgs.callPackage ./vm-grafana-datasource { };
        stalwart-webadmin = pkgs.callPackage ./stalwart-webadmin { };
        victoriametrics = pkgs.callPackage ./victoriametrics { };
      };
    in
    {
      inherit packages;
      hydraJobs = packages;
    };

  flake = withSystem "x86_64-linux" (
    { system, pkgs, ... }:
    let
      pkgsDeezer = import inputs.nixpkgs-deezer {
        inherit system;
        config.allowUnfreePredicate = pkg: elem (lib.getName pkg) [ "deezer" ];
        config.permittedInsecurePackages = [ "electron-13.6.9" ];
      };

      packages = {
        rtc-helper = pkgs.callPackage ./shellscripts/rtc-helper.nix { };
        nas = pkgs.callPackage ./shellscripts/nas.nix { };
        backup-usb = pkgs.callPackage ./shellscripts/backup-usb.nix { };

        # s25rttr = pkgs.callPackage ./s25rttr {
        #   SDL2 = pkgs.SDL2.override { withStatic = true; };
        # };

        pytr = pkgs.python3.pkgs.callPackage ./pytr { };
        asus-numberpad-driver = pkgs.python3.pkgs.callPackage ./asus-numberpad-driver { };

        jameica-fhs = pkgs.callPackage ./jameica/fhsenv.nix { };

        deezer = pkgsDeezer.callPackage ./deezer { };

        # remove with 24.11
        inherit (pkgs) vdhcoapp;

        linux_xanmod_x86_64_v3 = pkgs.callPackage ./linux-xanmod-x86-64-v3 { };

        stalwart-mail = pkgs.stalwart-mail.overrideAttrs (old: {
          postInstall = ''
            mkdir -p $out/etc/stalwart
            cp resources/config/spamfilter.toml $out/etc/stalwart/spamfilter.toml
            cp -r resources/config/spamfilter $out/etc/stalwart/
          '';
        });

        stalwart-mail_0_7 = pkgs.stalwart-mail.overrideAttrs (old: rec {
          pname = "stalwart-mail_0_7";
          version = "0.7.3";
          src = pkgs.fetchFromGitHub {
            owner = "stalwartlabs";
            repo = "mail-server";
            rev = "v${version}";
            hash = "sha256-Hpb7/GLrbZkruY3UTWdwIzwiwgcCT/JzFnUH5tCZaOQ=";
            fetchSubmodules = true;
          };

          postInstall = ''
            mkdir -p $out/etc/stalwart $out/share/web/
            cp resources/config/spamfilter.toml $out/etc/stalwart/spamfilter.toml
            cp -r resources/config/spamfilter $out/etc/stalwart/
            cp resources/webadmin.zip $out/share/web/
          '';

          cargoDeps = old.cargoDeps.overrideAttrs (_: {
            inherit src;
            name = "${pname}-${version}-vendor.tar.gz";
            outputHash = "sha256-k0CB1L8B6+bizBxcj1QM7CjFjC8spbRZ9ERU+9gqmgY=";
          });
        });
      };
    in
    {
      packages."${system}" = packages;
      hydraJobs."${system}" = packages;
    }
  );
}
