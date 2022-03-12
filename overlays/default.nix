final: prev: {
  remmina = prev.callPackage ./remmina { inherit prev; };
  autoadb = prev.callPackage ./autoadb { };
}
