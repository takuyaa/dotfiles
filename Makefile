UNAME := $(shell uname)

# The darwinConfigurations entry for whoever is logged in (see flake.nix).
# Evaluated before sudo, so it is the real user, not root.
DARWIN_HOST := $(shell id -un | tr . -)

.PHONY: rebuild update

ifeq ($(UNAME), Darwin)
rebuild:
	sudo darwin-rebuild switch --flake .#$(DARWIN_HOST)

update:
	nix flake update
	sudo darwin-rebuild switch --flake .#$(DARWIN_HOST)
else
rebuild:
	home-manager switch -b backup --flake .#takuya-a

update:
	nix flake update
	home-manager switch -b backup --flake .#takuya-a
endif
