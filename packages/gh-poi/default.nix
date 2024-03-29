{ lib, fetchFromGitHub, buildGoModule, }:
buildGoModule rec {
  pname = "gh-poi";
  version = "0.9.8";

  src = fetchFromGitHub {
    owner = "seachicken";
    repo = "${pname}";
    rev = "v${version}";
    hash = "sha256-QpUZxho9hzmgbCFgNxwwKi6hhfyqc4b/JYKH3rP4Eb8=";
  };
  vendorHash = "sha256-D/YZLwwGJWCekq9mpfCECzJyJ/xSlg7fC6leJh+e8i0=";

  ldflags = [ "-s" "-w" ];

  # Does try to access some test repos (?)
  doCheck = false;
  passthru.runUpdate = true;

  meta = with lib; {
    homepage = "https://github.com/seachicken/gh-poi";
    description = "Safely clean up your local branches";
    license = licenses.mit;
    maintainers = with maintainers; [ shawn8901 ];
    platforms = [ "x86_64-linux" ];
  };
}
