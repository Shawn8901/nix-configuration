{
  stdenvNoCC,
  fetchzip,
  wireguard-tools,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "wg-reresolve-dns";
  version = "1.0.20210914";

  src = fetchzip {
    url = "https://git.zx2c4.com/wireguard-tools/snapshot/wireguard-tools-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-eGGkTVdPPTWK6iEyowW11F4ywRhd+0IXJTZCqY3OZws=";
  };

  sourceRoot = "source/contrib/reresolve-dns";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    install -Dm744 reresolve-dns.sh "$out/bin/"

    runHook postInstall
  '';
})
