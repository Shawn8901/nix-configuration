let
  shawn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM";

  pointalpha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILzWsbvSeDXhbrhEr+NLvG087/ahHJ0JV7a5gGtIr58l";
  pointjig = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/mOOPSGuN9nikbteB8pZhKAE7i8K5/B214/UoBy0nU";
  tank = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIsh4IWvnMlQTfU9N1BpcE0b4KzxDYrjh+k8TTqj07Gw";
  backup = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDg8wKBWXd+v9FeoujUAppfFp4FUX4IobYNujKO8PBGL";

  systems = [ pointalpha pointjig tank backup ];
in
{
  "shawn_password.age".publicKeys = [ shawn ] ++ systems;
  "root_password.age".publicKeys = [ shawn ] ++ systems;

  "samba_credentials.age".publicKeys = [ shawn pointalpha ];

  "zrepl_pointalpha.age".publicKeys = [ shawn pointalpha ];

  "zrepl_tank.age".publicKeys = [ shawn tank ];
  "ela_password.age".publicKeys = [ shawn tank ];
  "nextcloud_db.age".publicKeys = [ shawn tank ];
  "nextcloud_admin.age".publicKeys = [ shawn tank ];
  "nextcloud_prometheus.age".publicKeys = [ shawn tank ];
  "fritzbox_prometheus.age".publicKeys = [ shawn tank ];
  "ztank_key.age".publicKeys = [ shawn tank ];
  "grafana_db.age".publicKeys = [ shawn tank ];
  "grafana_admin_password_file.age".publicKeys = [ shawn tank ];
  "grafana_secret_key_file.age".publicKeys = [ shawn tank ];

  "zrepl_backup.age".publicKeys = [ shawn backup ];
}
