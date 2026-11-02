UNAME := $(shell uname)

# The darwinConfigurations entry for whoever is logged in (see flake.nix).
# Evaluated before sudo, so it is the real user, not root.
DARWIN_HOST := $(shell id -un | tr . -)

# Generations older than this are dropped by `make gc`, which rebuild/update
# run afterwards. One week of rollback targets is plenty; beyond that, old
# generations only pin dead store paths (the dev pod's 100Gi /nix filled up with
# 36 generations whose live closure was 11 GiB). A bare `nix store gc` is not
# enough on its own, because every generation is a GC root.
GC_KEEP := 7d

.PHONY: rebuild update gc

ifeq ($(UNAME), Darwin)
rebuild:
	sudo darwin-rebuild switch --flake .#$(DARWIN_HOST)
	$(MAKE) gc

update:
	nix flake update
	sudo darwin-rebuild switch --flake .#$(DARWIN_HOST)
	$(MAKE) gc

# Twice on purpose: as the user for Home Manager and `nix profile`
# generations under ~/.local/state/nix/profiles, as root for the nix-darwin
# system generations under /nix/var/nix/profiles.
gc:
	nix-collect-garbage --delete-older-than $(GC_KEEP)
	sudo nix-collect-garbage --delete-older-than $(GC_KEEP)
else
rebuild:
	home-manager switch -b backup --flake .#takuya-a
	$(MAKE) gc

update:
	nix flake update
	home-manager switch -b backup --flake .#takuya-a
	$(MAKE) gc

gc:
	nix-collect-garbage --delete-older-than $(GC_KEEP)
endif
