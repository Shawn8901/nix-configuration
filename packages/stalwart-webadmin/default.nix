{ lib
, fetchFromGitHub
, stdenv
, fetchurl
,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "stalwart-webadmin";
  version = "0.1.7";

  src = fetchurl {
    url = "https://github.com/stalwartlabs/webadmin/releases/download/v${finalAttrs.version}/webadmin.zip";
    hash = "sha256-TnJZB2EjjFUM0jTZ47Nxrozf+1zZR+PFXkoW1YXODWE=";
  };

  outputs = [
    "out"
    "webadmin"
  ];

  buildCommand = ''
    runHook preBuild

    # Make it impossible to add to an environment. You should use the appropriate NixOS option.
    # Also leave some breadcrumbs in the file.
    echo "${finalAttrs.pname} should not be installed into environments. Please use  services.stalwart-mail.settings.config.resource.webadmin instead." > $out

    mkdir -p $webadmin
    ln -s $src $webadmin/webadmin.zip

    runHook postBuild
  '';

  passthru.runUpdate = true;

  meta = with lib; {
    homepage = "https://github.com/stalwartlabs/webadmin";
    description = "Web-based admin for Stalwart Mail Server ";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ shawn8901 ];
    platforms = lib.platforms.all;
  };
})
