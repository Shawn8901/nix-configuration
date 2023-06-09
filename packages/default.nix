{
  config,
  perSystem,
  withSystem,
  inputs,
  ...
}: {
  perSystem = {pkgs, ...}: let
    packages = {
      pg-upgrade = pkgs.callPackage ./pg-upgrade {};
      generate-zrepl-ssl = pkgs.callPackage ./shellscripts/generate-zrepl-ssl.nix {};
    };
  in {
    inherit packages;
    hydraJobs = packages;
  };

  flake = withSystem "x86_64-linux" (
    {system, ...}: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.nixpkgs.config.allowUnfreePredicate = pkg:
          builtins.elem (inputs.nixpkgs.lib.getName pkg) [
            "deezer"
          ];
        config.permittedInsecurePackages = [
          "electron-13.6.9"
        ];
      };

      packages = rec {
        rtc-helper = pkgs.callPackage ./shellscripts/rtc-helper.nix {};
        nas = pkgs.callPackage ./shellscripts/nas.nix {};
        backup-usb = pkgs.callPackage ./shellscripts/backup-usb.nix {};

        s25rttr = pkgs.callPackage ./s25rttr {
          SDL2 = pkgs.SDL2.override {withStatic = true;};
        };
        proton-ge-custom = pkgs.callPackage ./proton-ge-custom {};
        noisetorch = pkgs.callPackage ./noisetorch {};
        pytr = pkgs.python3.pkgs.callPackage ./pytr {};
        asus-touchpad-numpad-driver = pkgs.python3.pkgs.callPackage ./asus-touchpad-numpad-driver {};

        gh-poi = pkgs.callPackage ./gh-poi {};

        jameica-fhs = pkgs.callPackage ./jameica/fhsenv.nix {};

        libcapi = pkgs.callPackage ./libcapi {};
        librm = pkgs.callPackage ./librm {inherit (packages) libcapi;};
        rogerrouter = pkgs.callPackage ./rogerrouter {inherit (packages) librm;};

        deezer = pkgs.callPackage ./deezer {};
        vdhcoapp = pkgs.callPackage ./vdhcoapp {};

        dfipc = pkgs.libsForQt5.callPackage ./dfipc {};
        dflogin1 = pkgs.libsForQt5.callPackage ./dflogin1 {};
        dfutils = pkgs.libsForQt5.callPackage ./dfutils {};
        dfapplications = pkgs.libsForQt5.callPackage ./dfapplications {inherit dfipc;};
        qtgreet = pkgs.libsForQt5.callPackage ./qtgreet {inherit wayqt dfapplications dfutils dflogin1;};
        wayqt = pkgs.libsForQt5.callPackage ./wayqt {};
      };
    in {
      packages."${system}" = packages;
      hydraJobs."${system}" = packages;
    }
  );
}
