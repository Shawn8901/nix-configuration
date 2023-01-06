# Systems configuration for nixos system from a random person on the internet

This flake hosts different boxes (1 Desktop, some servers), some custom packages, some nixos and home mananger modules and it uses agenix for secrets.
Two boxes have RootFS on ZFS and do rollback their root fs similar to the blog post from [grahamc](https://grahamc.com/blog/erase-your-darlings).

The some structural inspiration was taken from [NobbZ](https://github.com/NobbZ/nixos-config) (old) public flake configuraton.
