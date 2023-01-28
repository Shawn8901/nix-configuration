{ self, pkgs, ... }@inputs:
rec {
  deezer = pkgs.callPackage ./deezer { };

  s25rttr = pkgs.callPackage ./s25rttr {
    SDL2 = pkgs.SDL2.override { withStatic = true; };
  };
  proton-ge-custom = pkgs.callPackage ./proton-ge-custom { };
  rtc-helper = pkgs.callPackage ./shellscripts/rtc-helper.nix { };
  nas = pkgs.callPackage ./shellscripts/nas.nix { };
  usb-backup = pkgs.callPackage ./shellscripts/usb-backup.nix { };
  generate-zrepl-ssl = pkgs.callPackage ./shellscripts/generate-zrepl-ssl.nix { };
  noisetorch = pkgs.callPackage ./noisetorch { };
  pytr = pkgs.python3.pkgs.callPackage ./pytr { };
  notify_push = pkgs.callPackage ./notify_push { };

  gh-poi = pkgs.callPackage ./gh-poi { };
  vdhcoapp = pkgs.callPackage ./vdhcoapp { };

  jameica-fhs = pkgs.callPackage ./jameica/fhsenv.nix { };

  libcapi = pkgs.callPackage ./libcapi { };
  librm = pkgs.callPackage ./librm { inherit libcapi; };
  rogerrouter = pkgs.callPackage ./rogerrouter { inherit librm; };

  sddm-git = pkgs.sddm.overrideAttrs (oldAttrs: {
    name = "sddm-git";
    version = "unstable-2022-11-23";

    src = pkgs.fetchgit {
      url = "https://github.com/sddm/sddm";
      rev = "3e486499b9300ce8f9c62bd102e5119b27a2fad1";
      sha256 = "sha256-udpWdxi6SkYrJqbJRyubmn5o3/YSVcuWW6S//jQefYI=";
    };

    patches = [ ];
    buildInputs = pkgs.libsForQt5.sddm.buildInputs ++ [
      pkgs.libsForQt5.layer-shell-qt
    ];
  });
}
