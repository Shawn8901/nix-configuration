HOSTNAME = $(shell hostname)
USER = $(shell whoami)

ifndef HOSTNAME
 $(error HOSTNAME unknown)
endif

ifndef USER
 $(error USER unknown)
endif

# cf https://stackoverflow.com/questions/2214575/passing-arguments-to-make-run
deploy:
	deploy .#${REMOTE_HOST}

flake-update:
	nix flake update

full: flake-update switch

garbage-collect:
	sudo nix-collect-garbage -d

check:
	nix flake check

boot:
	sudo nixos-rebuild boot --flake .#${HOSTNAME} -L

build:
	nixos-rebuild build --flake .#${HOSTNAME} -L
	nvd diff $$(ls --reverse -v /nix/var/nix/profiles | head --lines=1 | awk '{print "/nix/var/nix/profiles/" $$0}' -) result

switch:
	sudo nixos-rebuild switch --flake .#${HOSTNAME} -L
	ls -v /nix/var/nix/profiles | tail -n 2 | awk '{print "/nix/var/nix/profiles/" $$0}' - | xargs nvd diff
