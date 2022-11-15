{ lib
, fetchFromGitHub
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "notify_push";
  version = "v0.5.0";

  src = fetchFromGitHub {
    owner = "nextcloud";
    repo = "notify_push";
    rev = version;
    sha256 = "sha256-LkC2mD3klMQRF3z5QuVPcRHzz33VJP+UcN6LxsQXq7Q=";
  };

  cargoSha256 = "sha256-MfqabxC5Mt9wuHqEB++jcGVhHpUJnK3IKVSYTWSl8BY=";

  meta = with lib; {
    description = "Update notifications for nextcloud clients";
    homepage = "https://github.com/nextcloud/notify_push";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ shawn8901 ];
  };

}
