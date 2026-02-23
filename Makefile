UNAME := $(shell uname)

.PHONY: rebuild update

ifeq ($(UNAME), Darwin)
rebuild:
	sudo darwin-rebuild switch --flake .#macos

update:
	nix flake update
	sudo darwin-rebuild switch --flake .#macos
else
rebuild:
	home-manager switch --flake .#takuya-a

update:
	nix flake update
	home-manager switch --flake .#takuya-a
endif
