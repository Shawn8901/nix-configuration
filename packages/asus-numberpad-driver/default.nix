{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  python3,
  i2c-tools,
}:
let
  version = "6.0.0";
in
buildPythonApplication {
  pname = "asus-numberpad-driver";
  format = "other";

  inherit version;

  src = fetchFromGitHub {
    owner = "asus-linux-drivers";
    repo = "asus-numberpad-driver";
    # These needs to be updated from time to time
    rev = "v${version}";
    sha256 = "sha256-TuH9+quubGAd7nsSmb16T6VD/Avz6D7dDWAe0vRzygA=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    libevdev
    numpy
    pyinotify
    xlib
    smbus2
    pyasyncore
    pywayland
    xkbcommon
  ];

  installPhase = ''
    install -Dm744 numberpad.py $out/bin/numberpad.py
    install -Dm644 -t $out/bin/layouts layouts/*.py
  '';

  meta = with lib; {
    description = "Maintained feature-rich linux driver for NumberPad(2.0) on Asus laptops";
    longdescription = "Maintained feature-rich linux driver for NumberPad(2.0) on Asus laptops. NumberPad(2.0) is illuminated numeric keypad integrated to touchpad which appears when is done tap on top right corner of touchpad for atleast 1s by default (configurable) or slide gesture from top right corner to center (configurable). ";
    homepage = "https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver";
    license = licenses.gpl2;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ shawn8901 ];
    mainProgram = "numberpad.py";
  };
}
