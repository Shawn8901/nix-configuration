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
  epson-escpr2 = pkgs.callPackage ./epson-escpr2 { };
  stfc = pkgs.callPackage ./shellscripts/stfc.nix { };
  rtc-helper = pkgs.callPackage ./shellscripts/rtc-helper.nix { };
  nas = pkgs.callPackage ./shellscripts/nas.nix { };
  usb-backup = pkgs.callPackage ./shellscripts/usb-backup.nix { };
  agenix = inputs.agenix.defaultPackage.x86_64-linux;
}
