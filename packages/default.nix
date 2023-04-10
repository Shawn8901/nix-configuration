{
  self,
  pkgs,
  ...
} @ inputs: rec {
  deezer = pkgs.callPackage ./deezer {};

  s25rttr = pkgs.callPackage ./s25rttr {
    SDL2 = pkgs.SDL2.override {withStatic = true;};
  };
  proton-ge-custom = pkgs.callPackage ./proton-ge-custom {};
  rtc-helper = pkgs.callPackage ./shellscripts/rtc-helper.nix {};
  nas = pkgs.callPackage ./shellscripts/nas.nix {};
  usb-backup = pkgs.callPackage ./shellscripts/usb-backup.nix {};
  generate-zrepl-ssl = pkgs.callPackage ./shellscripts/generate-zrepl-ssl.nix {};
  noisetorch = pkgs.callPackage ./noisetorch {};
  pytr = pkgs.python3.pkgs.callPackage ./pytr {};
  asus-touchpad-numpad-driver = pkgs.python3.pkgs.callPackage ./asus-touchpad-numpad-driver {};
  notify_push = pkgs.callPackage ./notify_push {};

  gh-poi = pkgs.callPackage ./gh-poi {};
  vdhcoapp = pkgs.callPackage ./vdhcoapp {};
  wg-reresolve-dns = pkgs.callPackage ./wg-reresolve-dns {};

  jameica-fhs = pkgs.callPackage ./jameica/fhsenv.nix {};

  libcapi = pkgs.callPackage ./libcapi {};
  librm = pkgs.callPackage ./librm {inherit libcapi;};
  rogerrouter = pkgs.callPackage ./rogerrouter {inherit librm;};

  sddm-git = pkgs.libsForQt5.callPackage ./sddm {};
}
