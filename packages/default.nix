{ self, ... }@inputs:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

  unfree-pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };

in {

  s25rttr = pkgs.callPackage ./s25rttr {
    SDL2 = pkgs.SDL2.override { withStatic = true; };
  };
  proton-ge-custom = pkgs.callPackage ./proton-ge-custom { };
  haguichi = unfree-pkgs.callPackage ./haguichi { };
  stfc = pkgs.callPackage ./shellscripts/stfc.nix { };
  rtc-helper = pkgs.callPackage ./shellscripts/rtc-helper.nix { };
  nas = pkgs.callPackage ./shellscripts/nas.nix { };
  usb-backup = pkgs.callPackage ./shellscripts/usb-backup.nix { };

  statix = inputs.statix.defaultPackage.x86_64-linux;
  agenix = inputs.agenix.defaultPackage.x86_64-linux;
}
