final: prev: {
  s25rttr = prev.callPackage ./s25rttr {
    SDL2 = prev.SDL2.override {
      withStatic = true;
    };
  };
  proton-ge-custom = prev.callPackage ./proton-ge-custom { };
  stfc = prev.callPackage ./shellscripts/stfc.nix { };
  nas = prev.callPackage ./shellscripts/nas.nix { };
  haguichi = prev.callPackage ./haguichi { };
}
