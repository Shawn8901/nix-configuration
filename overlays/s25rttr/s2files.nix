{ stdenv, requireFile }:

stdenv.mkDerivation {
  name = "s2files";

  src = requireFile rec {
    name = "S2.tar";
    sha256 = "0k7ki4baz06j8adbqmf6dvpqhyg2is919hc89zbd7m4s6v95vsj2";
    message = ''
      Copy the S2 folder of the Settler 2 Gold Edition and create a tar archive out ot it, e.G. "tar -cf ${name} S2".

      Afterwards use "nix-prefetch-url file://\$PWD/${name}" to add it to the Nix store.
    '';
  };

  buildCommand = ''
    mkdir -vp "$out"
    tar xf "$src" -C "$out" --strip-components=1
  '';
}
