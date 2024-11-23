{
  config.fp-lib.modules.nixos = {
    public = ./nixos/public;
    private = ./nixos/private;
  };

  config.fp-lib.modules.home-manager = {
    public = ./home-manager/public;
    private = ./home-manager/private;
  };
}
