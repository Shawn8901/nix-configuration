{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  protobuf,
  bzip2,
  openssl,
  sqlite,
  zstd,
  stdenv,
  darwin,
  rocksdb,
}:

let
  stalwart_rocksdb = rocksdb.overrideAttrs rec {
    pname = "rocksdb";
    version = "8.10.0";

    src = fetchFromGitHub {
      owner = "facebook";
      repo = "rocksdb";
      rev = "v${version}";
      hash = "sha256-KGsYDBc1fz/90YYNGwlZ0LUKXYsP1zyhP29TnRQwgjQ=";
    };
  };

  version = "0.7.3";
in
rustPlatform.buildRustPackage {
  pname = "stalwart-mail";
  inherit version;

  src = fetchFromGitHub {
    owner = "stalwartlabs";
    repo = "mail-server";
    rev = "v${version}";
    hash = "sha256-Hpb7/GLrbZkruY3UTWdwIzwiwgcCT/JzFnUH5tCZaOQ=";
    fetchSubmodules = true;
  };

  cargoHash = "sha256-/q+27KM/syWmRUiXhrzRqG8arjD007jL5JedU4RGC20=";

  nativeBuildInputs = [
    pkg-config
    protobuf
    rustPlatform.bindgenHook
  ];

  buildInputs =
    [
      bzip2
      openssl
      sqlite
      zstd
    ]
    ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.CoreFoundation
      darwin.apple_sdk.frameworks.Security
      darwin.apple_sdk.frameworks.SystemConfiguration
    ];

  env = {
    OPENSSL_NO_VENDOR = true;
    ZSTD_SYS_USE_PKG_CONFIG = true;
    ROCKSDB_INCLUDE_DIR = "${stalwart_rocksdb}/include";
    ROCKSDB_LIB_DIR = "${stalwart_rocksdb}/lib";
  };

  postInstall = ''
    mkdir -p $out/etc/stalwart $out/share/web/
    cp resources/config/spamfilter.toml $out/etc/stalwart/spamfilter.toml
    cp -r resources/config/spamfilter $out/etc/stalwart/
    cp resources/webadmin.zip $out/share/web/
  '';

  # Tests require reading to /etc/resolv.conf
  doCheck = false;

  meta = with lib; {
    description = "Secure & Modern All-in-One Mail Server (IMAP, JMAP, SMTP)";
    homepage = "https://github.com/stalwartlabs/mail-server";
    changelog = "https://github.com/stalwartlabs/mail-server/blob/${version}/CHANGELOG";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ shawn8901 ];
  };
}
