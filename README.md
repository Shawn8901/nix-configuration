# Systems configuration for nixos system from a random person on the internet

This flake hosts different boxes (2 Desktop, some servers), some custom packages, some nixos and home mananger modules and it uses sops-nix for secrets.
The host `cache` is a aarch64 machine, others x86-64.

Other interesing flakes (alphabetic order):

- [fufexan](https://github.com/fufexan/dotfiles)
- [Kranzes](https://github.com/Kranzes/nix-config)
- [NobbZ](https://github.com/NobbZ/nixos-config)
- [viperML](https://github.com/viperML/dotfiles)

# Maintainance notes:
## attic 
```bash
# Read Only Token
atticd-atticadm make-token --sub 'ro' --validity '1 year'  --pull '*'

# Root Token
atticd-atticadm make-token --sub 'root' --validity '1 year' --push '*' --pull '*' --delete '*' --create-cache '*' --destroy-cache '*' --configure-cache '*' --configure-cache-retention '*'
```
## Generate new zrepl certificate
```bash
 nix run github:shawn8901/nix-configuration#generate-zrepl-ssl <hostname>

