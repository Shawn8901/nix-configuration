inputs: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [ (import ../home-manager inputs) ];
    users.shawn = {
      home.stateVersion = "22.05";
      programs.zsh = { enable = true; };
      programs.git = {
        enable = true;
        userName = "Shawn8901";
        userEmail = "shawn8901@googlemail.com";
        ignores = [ "*.swp" ];
        extraConfig = { init = { defaultBranch = "main"; }; };
      };
    };
  };
}
