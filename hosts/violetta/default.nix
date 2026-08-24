# violetta — Wodanio VPS (app.ultraviolet.law in ~/.ssh/config; no public DNS).
# No workload yet; base.nix provides SSH access for julius/marc/martin.
{ ... }:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "violetta";

  deployment.targetHost = "91.24.43.181";
  deployment.sshUser = "root"; # no admin user until the box has a workload

  # Wodanio has no DHCP. Addressing normally comes from a cloud-init seed
  # ISO, which this config does not consume, so it is declared here.
  # The exact addresses are load-bearing NAT mappings on the provider side:
  #   91.24.43.181         -> 10.1.252.36
  #   2003:ee:3022:0:aa::36 -> fc00:0:aa::1:36  (NAT66 from ULA)
  # Matched by MAC, not name: "eth0" does not survive predictable naming.
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.MACAddress = "bc:24:11:b5:f0:0c";
      address = [ "10.1.252.36/22" "fc00:0:aa::1:36/64" ];
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
