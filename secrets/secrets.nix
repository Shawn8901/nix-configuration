let
  shawn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM";
  pointalpha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILzWsbvSeDXhbrhEr+NLvG087/ahHJ0JV7a5gGtIr58l";
  pointjig = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8lC09BhCwsbqawejuRFA5gs/qhzZQiRdUH3LRXAkOW";
  tank = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIsh4IWvnMlQTfU9N1BpcE0b4KzxDYrjh+k8TTqj07Gw";
  shelter = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDg8wKBWXd+v9FeoujUAppfFp4FUX4IobYNujKO8PBGL";
  next = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXIWr2IzBmFBqcLZ503WFiKt1jcxZcn2oklGcnv9F8W";
  cache = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGsbOU2fH6DUf3MTnMJuMU6PLT7sugH7s1cC2i0ob2pY";

  systems = [pointalpha pointjig tank shelter cache];
in {
  "shawn_password.age".publicKeys = [shawn] ++ systems;
  "root_password.age".publicKeys = [shawn] ++ systems;
  "builder_ssh_priv.age".publicKeys = [shawn tank];
  "ela_password.age".publicKeys = [shawn tank];

  "shawn_samba_credentials.age".publicKeys = [shawn pointalpha];
  "ela_samba_credentials.age".publicKeys = [shawn pointalpha];

  "zrepl_pointalpha.age".publicKeys = [shawn pointalpha];
  "zrepl_shelter.age".publicKeys = [shawn shelter];
  "zrepl_tank.age".publicKeys = [shawn tank];
  "ztank_key.age".publicKeys = [shawn tank];

  "nextcloud_db.age".publicKeys = [shawn tank];
  "nextcloud_admin.age".publicKeys = [shawn tank];

  "nextcloud_prometheus.age".publicKeys = [shawn tank next];
  "fritzbox_prometheus.age".publicKeys = [shawn tank];
  "pve_prometheus.age".publicKeys = [shawn cache];
  "prometheus_internal_web_config.age".publicKeys = [shawn pointalpha tank];
  "prometheus_public_web_config.age".publicKeys = [shawn next pointjig shelter];
  "grafana_env_file.age".publicKeys = [shawn cache];
  "nix-gh-token.age".publicKeys = [shawn next] ++ systems;
  "gh-write-token.age".publicKeys = [shawn tank];
  "nix-netrc-ro.age".publicKeys = [shawn next] ++ systems;
  "nix-netrc-rw.age".publicKeys = [shawn tank pointalpha];
  "stfc-env-dev.age".publicKeys = [shawn tank];
  "mimir-env-dev.age".publicKeys = [shawn tank];
  "stfc-env.age".publicKeys = [shawn pointjig];
  "mimir-env.age".publicKeys = [shawn pointjig];
  "sms-shawn-passwd.age".publicKeys = [shawn pointjig];
  "sms-technical-passwd.age".publicKeys = [shawn tank pointjig];

  "ffm_root_password.age".publicKeys = [shawn next];
  "ffm_nextcloud_db.age".publicKeys = [shawn next];
  "cache-signing-key.age".publicKeys = [shawn tank cache];
  "attic_env.age".publicKeys = [shawn cache];
  "cache-wg-priv-key.age".publicKeys = [shawn cache];
  "cache-wg-preshared-key.age".publicKeys = [shawn cache];
}
