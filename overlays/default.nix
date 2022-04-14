final: prev: {
  s25rttr = prev.callPackage ./s25rttr {
    SDL2 = prev.SDL2.override {
      withStatic = true;
    };
  };
  proton-ge-custom = prev.callPackage ./proton-ge-custom { };
  haguichi = prev.callPackage ./haguichi { };
  stfc = prev.callPackage ./shellscripts/stfc.nix { };
  rtc-helper = prev.callPackage ./shellscripts/rtc-helper.nix { };
  nas = prev.callPackage ./shellscripts/nas.nix { };
  backup_server = prev.callPackage ./shellscripts/backup_server.nix { };
  usb-backup-ela = prev.callPackage ./shellscripts/usb-backup-ela.nix { };

  portfolio = prev.portfolio.overrideAttrs (attrs: rec {
    version = "0.57.1";
    src = prev.fetchurl {
    url = "https://github.com/buchen/portfolio/releases/download/${version}/PortfolioPerformance-${version}-linux.gtk.x86_64.tar.gz";
    sha256 = "sha256-uEEFkHyApf+TObcu+Yo5vBOs2Erq0IXGhbjzlEe8NmI=";
  };
  });
}
