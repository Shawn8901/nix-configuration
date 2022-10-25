{ self, system, pkgs, ... }@inputs:
{
  s25rttr = pkgs.callPackage ./s25rttr {
    SDL2 = pkgs.SDL2.override { withStatic = true; };
  };
  proton-ge-custom = pkgs.callPackage ./proton-ge-custom { };
  rtc-helper = pkgs.callPackage ./shellscripts/rtc-helper.nix { };
  nas = pkgs.callPackage ./shellscripts/nas.nix { };
  usb-backup = pkgs.callPackage ./shellscripts/usb-backup.nix { };
  noisetorch = pkgs.callPackage ./noisetorch { };
  pytr = pkgs.python3.pkgs.callPackage ./pytr { };

  jameica = pkgs.callPackage ./jameica {
    Cocoa = null;
  };

  sddm-git = pkgs.sddm.overrideAttrs (oldAttrs: {
    name = "sddm-git";
    version = "unstable-2022-03-21";

    src = pkgs.fetchgit {
      url = "https://github.com/sddm/sddm";
      rev = "e67307e4103a8606d57a0c2fd48a378e40fcef06";
      sha256 = "1rcs8mkykvhlygiv6fs07q67q9bigywi5hz0m4g66fjrbsbyh7gp";
    };

    patches = [ ];
  });
}
