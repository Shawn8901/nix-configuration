let
  shawn = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMguHbKev03NMawY9MX6MEhRhd6+h2a/aPIOorgfB5oM";

  pointalpha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILzWsbvSeDXhbrhEr+NLvG087/ahHJ0JV7a5gGtIr58l";
  pointjig = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/mOOPSGuN9nikbteB8pZhKAE7i8K5/B214/UoBy0nU";
  tank = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIsh4IWvnMlQTfU9N1BpcE0b4KzxDYrjh+k8TTqj07Gw";

  systems = [ pointalpha pointjig tank ];
in
{
  "shawn_password.age".publicKeys = [ shawn ] ++ systems;
  "root_password.age".publicKeys = [ shawn ] ++ systems;

  "samba_credentials.age".publicKeys = [ shawn pointalpha ];

  "zrepl_pointalpha.age".publicKeys = [ shawn pointalpha ];
  "zrepl_tank.age".publicKeys = [ shawn tank ];
}
