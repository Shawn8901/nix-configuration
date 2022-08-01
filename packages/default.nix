{ self, system, pkgs, ... }@inputs:
{
  s25rttr = pkgs.callPackage ./s25rttr {
    SDL2 = pkgs.SDL2.override { withStatic = true; };
  };
  proton-ge-custom = pkgs.callPackage ./proton-ge-custom { };
  stfc = pkgs.callPackage ./shellscripts/stfc.nix { };
  rtc-helper = pkgs.callPackage ./shellscripts/rtc-helper.nix { };
  nas = pkgs.callPackage ./shellscripts/nas.nix { };
  usb-backup = pkgs.callPackage ./shellscripts/usb-backup.nix { };
  noisetorch = pkgs.callPackage ./noisetorch { };

  jameica = pkgs.callPackage ./jameica {
    Cocoa = null;
  };

  agenix = inputs.agenix.defaultPackage.${system};
}
