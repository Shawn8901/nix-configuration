{ lib
, fetchFromGitHub
, buildGoModule
,
}:
buildGoModule rec {
  pname = "gh-poi";
  version = "0.9.3";

  src = fetchFromGitHub {
    owner = "seachicken";
    repo = "${pname}";
    rev = "v${version}";
    sha256 = "sha256-Oh0l+WUj2G6EBhyhF1YVlyTsbH9eyK0R5heAfp6zUUc=";
  };
  vendorSha256 = "sha256-D/YZLwwGJWCekq9mpfCECzJyJ/xSlg7fC6leJh+e8i0=";

  ldflags = [
    "-s"
    "-w"
  ];

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
