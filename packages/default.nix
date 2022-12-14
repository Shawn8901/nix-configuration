{ self, pkgs, ... }@inputs:
rec {
  s25rttr = pkgs.callPackage ./s25rttr {
    SDL2 = pkgs.SDL2.override { withStatic = true; };
  };
  proton-ge-custom = pkgs.callPackage ./proton-ge-custom { };
  rtc-helper = pkgs.callPackage ./shellscripts/rtc-helper.nix { };
  nas = pkgs.callPackage ./shellscripts/nas.nix { };
  usb-backup = pkgs.callPackage ./shellscripts/usb-backup.nix { };
  generate-zrepl-ssl = pkgs.callPackage ./shellscripts/generate-zrepl-ssl.nix { };
  update-packages = pkgs.callPackage ./shellscripts/update-packages.nix { };
  noisetorch = pkgs.callPackage ./noisetorch { };
  pytr = pkgs.python3.pkgs.callPackage ./pytr { };
  notify_push = pkgs.callPackage ./notify_push { };


  jameica = pkgs.callPackage ./jameica {
    Cocoa = null;
  };

  libcapi = pkgs.callPackage ./libcapi { };
  librm = pkgs.callPackage ./librm { inherit libcapi; };
  rogerrouter = pkgs.callPackage ./rogerrouter { inherit librm; };

  sddm-git = pkgs.sddm.overrideAttrs (oldAttrs: {
    name = "sddm-git";
    version = "unstable-2022-11-17";

    src = pkgs.fetchgit {
      url = "https://github.com/sddm/sddm";
      rev = "ebe6110bd2bb5047ca09d4446fe739da468086e1";
      sha256 = "sha256-ovx4G+AIfghOSHtIroOJh9hzXiyVx8MCsBM6h+Vvpv8=";
    };

    patches = [ ];
    buildInputs = pkgs.libsForQt5.sddm.buildInputs ++ [
      pkgs.libsForQt5.layer-shell-qt
      pkgs.libsForQt5.qt5.qtvirtualkeyboard
    ];
  });


}
