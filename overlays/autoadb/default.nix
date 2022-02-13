{ lib
, rustPlatform
, fetchFromGitHub
, libclang
, stdenv
, Security
}:

rustPlatform.buildRustPackage rec {
  pname = "autoadb";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "rom1v";
    repo = pname;
    rev = "7f8402983603a9854bf618a384f679a17cd85e2d";
    sha256 = "sha256-9Sv38dCtvbqvxSnRpq+HsIwF/rfLUVZbi0J+mltLres=";
  };

  cargoSha256 = "sha256-XglpWhwq4Xhlb28OnyJ/pkvVj4WDAoyNL1LIrPA9Fbo=";

  buildInputs = [];

  LIBCLANG_PATH = "${libclang.lib}/lib";

  preCheck = "HOME=$(mktemp -d)";

  checkFlags = [
    "--skip checker::hunspell::tests::hunspell_binding_is_sane"
  ];

  meta = with lib; {
    description = "Execute a command whenever a device is adb-connected ";
    homepage = "https://github.com/rom1v/autoadb";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
  };
}