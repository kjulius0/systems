# Deployment metadata. Pure data — has no effect on the built system.
# Read by ./fleet via `nix eval`.
{ lib, ... }:
{
  options.deployment = {
    targetHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "IP address or DNS name the host is reachable at.";
    };

    targetUser = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "SSH user used for deploys.";
    };

    sshUser = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "SSH user for interactive shells (fleet ssh).";
    };
  };
}
