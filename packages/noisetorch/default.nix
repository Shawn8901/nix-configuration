{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "NoiseTorch";
  version = "0.12.2.pre+date=2022-08-11";

  src = fetchFromGitHub {
    owner = "noisetorch";
    repo = pname;
    rev = "2792a642b8c483475d78518a0c148e5f68eb980b";
    sha256 = "sha256-mtGTa3jH7QR9RU6Gy9An7EX+B7ZM/+9EzlhBPxeQ/4M=";
    fetchSubmodules = true;
  };

  vendorSha256 = null;

  doCheck = false;

  ldflags = ["-s" "-w" "-X main.version=${version}" "-X main.distribution=nix"];

  subPackages = ["."];

  preBuild = ''
    make -C c/ladspa/
    go generate
    rm  ./scripts/*
  '';

  postInstall = ''
    install -D ./assets/icon/noisetorch.png $out/share/icons/hicolor/256x256/apps/noisetorch.png
    install -Dm444 ./assets/noisetorch.desktop $out/share/applications/noisetorch.desktop
  '';

  meta = with lib; {
    insecure = true;
    knownVulnerabilities =
      lib.optional (lib.versionOlder version "0.12") "https://github.com/noisetorch/NoiseTorch/releases/tag/v0.12.0";
    description = "Virtual microphone device with noise supression for PulseAudio";
    homepage = "https://github.com/noisetorch/NoiseTorch";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [panaeon lom];
  };
}
