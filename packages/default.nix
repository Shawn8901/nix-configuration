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

  sddm-git = uPkgs.sddm.overrideAttrs (oldAttrs: {
    name = "sddm-git";
    version = "unstable-2022-03-21";

    src = uPkgs.fetchgit {
      url = "https://github.com/sddm/sddm";
      rev = "e67307e4103a8606d57a0c2fd48a378e40fcef06";
      sha256 = "1rcs8mkykvhlygiv6fs07q67q9bigywi5hz0m4g66fjrbsbyh7gp";
    };

    patches = [ ];
  });

  agenix = inputs.agenix.defaultPackage.${system};
}
