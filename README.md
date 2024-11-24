# Overview

This flake contains nixos configuration for different boxes (2 Desktop, some servers), some custom packages, some nixos and home mananger modules.
The host `cache` is a aarch64 machine, others x86-64.
For secret provisioning sops-nix is used.

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

