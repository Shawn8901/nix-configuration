{ self, ... }@inputs:
let
  pkgs = inputs.nixpkgs-stable.legacyPackages.x86_64-linux;

  unfree-pkgs = import inputs.nixpkgs-stable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };

in {

  s25rttr = pkgs.callPackage ./s25rttr {
    SDL2 = pkgs.SDL2.override { withStatic = true; };
  };
  proton-ge-custom = pkgs.callPackage ./proton-ge-custom { };
  epson = pkgs.callPackage ./epson { };
  stfc = pkgs.callPackage ./shellscripts/stfc.nix { };
  rtc-helper = pkgs.callPackage ./shellscripts/rtc-helper.nix { };
  nas = pkgs.callPackage ./shellscripts/nas.nix { };
  usb-backup = pkgs.callPackage ./shellscripts/usb-backup.nix { };
  zrepl = pkgs.callPackage ./zrepl { };
  agenix = inputs.agenix.defaultPackage.x86_64-linux;
}
