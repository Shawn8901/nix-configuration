{ lib
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "gh-poi";
  version = "0.8.1";

  src = fetchFromGitHub {
    owner = "seachicken";
    repo = "${pname}";
    rev = "v${version}";
    sha256 = "sha256-Duh3jNKAAVplTgMQryXtJi8dVtGSFnC+M+l9PKcoLpQ=";
  };
  vendorSha256 = "sha256-KYrP88e5sauQVDega5plFYEll+MU+aXtC2vDw7E+Qpk=";

  ldflags = [
    "-s"
    "-w"
  ];

  # Does try to access some test repos (?)
  doCheck = false;

  meta = with lib; {
    homepage = "https://github.com/seachicken/gh-poi";
    description = "Safely clean up your local branches";
    license = licenses.mit;
    maintainers = with maintainers; [ shawn8901 ];
    platforms = [ "x86_64-linux" ];
  };
}
