final: prev: {
  s25rttr = prev.callPackage ./s25rttr {       
    SDL2 = prev.SDL2.override {
      withStatic = true;
    };
  };
}
