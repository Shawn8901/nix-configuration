# My systems configuration for nixos system from a random person on the internet

Special thanks to [NobbZ](https://github.com/NobbZ/nixos-config/) and [Mic92](https://github.com/Mic92/dotfiles) public configurations, which heavily inspired this.

## Useful commands
List of useful commands which are required on maintenance jobs.

### zrepl certificate generation

This configuraton uses tls authentication for zrepl. The following command, executed on the target host, will generate a usable RSA-4k keypair.
The pair must then be placed in `secrets` (encryption done via agenix) and `public_certs`.

```bash
(name=$(hostname); nix run nixpkgs#openssl -- req -x509 -sha256 -nodes  -newkey rsa:4096  -days 365  -keyout $name.key  -out $name.crt -addext "subjectAltName = DNS:$name" -subj "/CN=$name")
```
