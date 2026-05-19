# justfile — fleet management commands
#
# Requirements on your local machine:
#   nix, nixos-anywhere, openssh
#
# Install nixos-anywhere:
#   nix shell github:nix-community/nixos-anywhere

# Fresh NixOS install onto a machine reachable at <ip> (e.g. a rescue boot).
# The target must already be running Linux with an SSH server.
# Example: just install example 1.2.3.4
install host ip:
    nix run github:nix-community/nixos-anywhere -- \
        --flake .#{{host}} \
        root@{{ip}}

# Push a config update to a running host.
# Example: just deploy example 1.2.3.4
deploy host ip:
    nixos-rebuild switch \
        --flake .#{{host}} \
        --target-host root@{{ip}} \
        --use-remote-sudo

# Same as deploy but only build; don't activate (dry run / sanity check).
build host:
    nixos-rebuild build --flake .#{{host}}

# Open an SSH shell to a host.
# Example: just ssh example 1.2.3.4
ssh host ip:
    ssh admin@{{ip}}

# Update flake inputs and commit the new lock file.
update:
    nix flake update
    git add flake.lock
    git commit -m "flake: update inputs"
