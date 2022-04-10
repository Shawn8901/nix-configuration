final: prev: {
  s25rttr = prev.callPackage ./s25rttr {
    SDL2 = prev.SDL2.override {
      withStatic = true;
    };
  };
  proton-ge-custom = prev.callPackage ./proton-ge-custom { };
  haguichi = prev.callPackage ./haguichi { };
  stfc = prev.callPackage ./shellscripts/stfc.nix { };
  nas = prev.callPackage ./shellscripts/nas.nix { };
  backup_server = prev.callPackage ./shellscripts/backup_server.nix { };
  usb-backup-ela = prev.callPackage ./shellscripts/usb-backup-ela.nix { };
}
