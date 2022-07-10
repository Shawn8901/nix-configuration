# My systems configuration for nixos systems

Special thanks to [NobbZ](https://github.com/NobbZ/nixos-config/) and [Mic92](https://github.com/Mic92/dotfiles) public configurations, which havily inspired this.

## Useful commands

### zrepl certificate generation
```bash
(name=$(hostname); nix run nixpkgs#openssl -- req -x509 -sha256 -nodes  -newkey rsa:4096  -days 365  -keyout $name.key  -out $name.crt -addext "subjectAltName = DNS:$name" -subj "/CN=$name")
```
