{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "example";

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBWZVz+NY4jhXnFoIw6O7ZTMzUdDmECXIBWTth1j6cw work@rakka"
    ];
  };

  security.sudo.extraRules = [{
    users = [ "admin" ];
    commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
  }];

  virtualisation.docker.enable = true;

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  systemd.services.myapp = {
    description = "myapp docker compose stack";
    after = [ "docker.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/srv/myapp";
      ExecStartPre = pkgs.writeShellScript "myapp-pull" ''
        token=$(cat /etc/secrets/github-token)
        if [ -d /srv/myapp ]; then
          ${pkgs.git}/bin/git -C /srv/myapp pull https://x-access-token:$token@github.com/you/myapp
        else
          ${pkgs.git}/bin/git clone https://x-access-token:$token@github.com/you/myapp /srv/myapp
        fi
      '';
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d --build --remove-orphans";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
    };
  };

  system.stateVersion = "25.05";
}
