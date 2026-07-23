{ pkgs, ... }:
let
  ssh-keys = import ../../lib/ssh-keys.nix;
in
{
  imports = [ ./hardware.nix ./motd.nix ];

  networking.hostName = "fortress";

  # Machine -> address mapping used by ./fleet.
  deployment.targetHost = "167.233.160.10";

  # Lets generic dynamically-linked binaries run (VS Code remote server, etc.).
  programs.nix-ld.enable = true;

  # Zitadel v4 stack (traefik + api + login + postgres) via upstream compose.
  # Secrets (masterkey, DB password, DSN) live in /etc/secrets/zitadel.env.
  virtualisation.docker.enable = true;

  systemd.services.zitadel =
    let
      compose = "${pkgs.docker-compose}/bin/docker-compose"
        + " -f ${./zitadel/docker-compose.yml}"
        + " -f ${./zitadel/docker-compose.le.yml}"
        + " --env-file ${./zitadel/compose.env}"
        + " --env-file /etc/secrets/zitadel.env";
    in
    {
      description = "ZITADEL identity platform (docker compose stack)";
      requires = [ "docker.service" ];
      after = [ "docker.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = 0;
        ExecStart = "${compose} up -d --wait --remove-orphans";
        ExecStop = "${compose} down";
      };
    };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      ssh-keys.julius
      ssh-keys.marc
      ssh-keys.martin
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ "admin" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  system.stateVersion = "25.05";
}
