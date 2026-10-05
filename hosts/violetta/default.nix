# violetta — Wodanio VPS, 91.24.43.181 (app.ultraviolet.law: public DNS and ~/.ssh/config alias).
# Workload: Jitsi Meet (./jitsi.nix), agentnet on app.ultraviolet.law
# (./agentnet.nix).
{ ... }:
{
  imports = [
    ./hardware.nix
    ./jitsi.nix
    ./jitsi-unstable.nix
    ./agentnet.nix
  ];

  networking.hostName = "violetta";

  deployment.targetHost = "91.24.43.181";
  deployment.sshUser = "root"; # no admin user yet

  # Wodanio has no DHCP. Addressing normally comes from a cloud-init seed
  # ISO, which this config does not consume, so it is declared here.
  # The exact addresses are load-bearing NAT mappings on the provider side:
  #   91.24.43.181         -> 10.1.252.36
  #   2003:ee:3022:0:aa::36 -> fc00:0:aa::1:36  (NAT66 from ULA)
  # Matched by MAC, not name: "eth0" does not survive predictable naming.
  networking.useDHCP = false;
  # this host is configured via networkd (below): without this, NixOS also
  # sets up its scripted-networking layer next to it (networking-scripted
  # .target etc.). Not optional once systemd.network is used.
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.MACAddress = "bc:24:11:b5:f0:0c";
      address = [
        "10.1.252.36/22"
        "fc00:0:aa::1:36/64"
      ];
      routes = [
        { Gateway = "10.1.255.254"; }
        { Gateway = "fc00:0:aa::1"; }
      ];
      dns = [ "10.1.255.254" ];
      domains = [ "vps.wodanio.net" ];
    };
  };

  system.stateVersion = "25.05";
}
