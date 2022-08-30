{ self, system, uPkgs, sPkgs, ... }@inputs:
{
  s25rttr = uPkgs.callPackage ./s25rttr {
    SDL2 = uPkgs.SDL2.override { withStatic = true; };
  };
  proton-ge-custom = uPkgs.callPackage ./proton-ge-custom { };
  #stfc = pkgs.callPackage ./shellscripts/stfc.nix { };
  rtc-helper = sPkgs.callPackage ./shellscripts/rtc-helper.nix { };
  nas = sPkgs.callPackage ./shellscripts/nas.nix { };
  usb-backup = sPkgs.callPackage ./shellscripts/usb-backup.nix { };
  noisetorch = uPkgs.callPackage ./noisetorch { };

  jameica = uPkgs.callPackage ./jameica {
    Cocoa = null;
  };

  agenix = inputs.agenix.defaultPackage.${system};
}
