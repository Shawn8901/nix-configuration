let
  pointalpha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILzWsbvSeDXhbrhEr+NLvG087/ahHJ0JV7a5gGtIr58l";
in
{
  "shawn_password.age".publicKeys = [ pointalpha ];
  "root_password.age".publicKeys = [ pointalpha ];

  "samba_credentials.age".publicKeys = [ pointalpha ];

  "zrepl_pointalpha.age".publicKeys = [ pointalpha ];
  "zrepl_tank.age".publicKeys = [ pointalpha ];
}
