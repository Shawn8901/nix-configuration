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
	make flake-update
	deploy .#${REMOTE_HOST}

flake-update:
	nix flake update

full: flake-update switch
#home-manager-switch

garbage-collect:
	nix-collect-garbage -d
	sudo nix-collect-garbage -d

check:
	nix flake check


#home-manager-switch:
## other method
## nix build --profile /nix/var/nix/profiles/per-user/${USER}/home-manager   .#homeConfigurations.${USER}@${HOSTNAME}.activationPackage
#	home-manager switch --flake .#${USER}@${HOSTNAME} -v
#	echo "### HOME-MANAGER DIFF ###"
#	ls -d /nix/var/nix/profiles/per-user/${USER}/home* | tail -n 2 | xargs nvd diff
#	echo ""

boot:
	sudo nixos-rebuild boot --flake .#${HOSTNAME} -L

build:
## other method
## nix build .#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel
	nixos-rebuild build --flake .#${HOSTNAME} -L
	nvd diff $$(ls --reverse -v /nix/var/nix/profiles | head --lines=1 | awk '{print "/nix/var/nix/profiles/" $$0}' -) result

switch:
## other method
## sudo nix build --profile /nix/var/nix/profiles/system  .#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel
	sudo nixos-rebuild switch --flake .#${HOSTNAME} -L -v
	echo "### NIXOS DIFF ###"
	ls -v /nix/var/nix/profiles | tail -n 2 | awk '{print "/nix/var/nix/profiles/" $$0}' - | xargs nvd diff
	echo ""

