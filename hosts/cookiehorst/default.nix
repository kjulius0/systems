{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "cookiehorst";

  environment.systemPackages = with pkgs; [ s3fs ];

  fileSystems."/mnt/s3" = {
    device = "backup";
    fsType = "fuse.s3fs";
    options = [
      "_netdev"
      "allow_other"
      "nonempty"
      "passwd_file=/etc/secrets/s3fs-creds"
      "url=https://storage.dieter-datenschutz.de"
      "use_path_request_style"
      "dbglevel=info"
      "multipart_size=5000"
      "nofail"
    ];
  };

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBWZVz+NY4jhXnFoIw6O7ZTMzUdDmECXIBWTth1j6cw work@rakka"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1/FazxEZSGjnfqaR5tM8aifZCY+hns1DfCo87z8Hr1 marc@LWM"
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

  virtualisation.docker.enable = true;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  systemd.services.cookie-radar = {
    description = "cookie-radar docker compose stack";
    after = [
      "docker.service"
      "network-online.target"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "-/srv/cookie-radar";
      ExecStartPre = pkgs.writeShellScript "cookie-radar-pull" ''
        token=$(cat /etc/secrets/github-token)
        if [ -d /srv/cookie-radar/.git ]; then
          ${pkgs.git}/bin/git -C /srv/cookie-radar remote set-url origin https://x-access-token:$token@github.com/workmh155/cookie-radar
          ${pkgs.git}/bin/git -C /srv/cookie-radar fetch origin
          ${pkgs.git}/bin/git -C /srv/cookie-radar checkout dieter-version
          ${pkgs.git}/bin/git -C /srv/cookie-radar reset --hard origin/dieter-version
        else
          mkdir -p /srv/cookie-radar
          ${pkgs.git}/bin/git clone --branch dieter-version https://x-access-token:$token@github.com/workmh155/cookie-radar /srv/cookie-radar
        fi
      '';
      # ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d --build --remove-orphans";
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f docker-compose.yml -f docker-compose.server.yml up --build -d --remove-orphans";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
    };
  };

  systemd.services.db-backup = {
    description = "PostgreSQL backup to S3";
    after = [ "mnt-s3.mount" "docker.service" "cookie-radar.service" ];
    requires = [ "mnt-s3.mount" ];
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/srv/cookie-radar";
      ExecStart = pkgs.writeShellScript "db-backup" ''
        set -euo pipefail
        ${pkgs.docker-compose}/bin/docker-compose exec -T postgres \
          pg_dump -U cookie_radar -d cookie_radar \
          > /mnt/s3/cookie_radar_$(${pkgs.coreutils}/bin/date +%F_%H-%M-%S).sql
        ${pkgs.findutils}/bin/find /mnt/s3 -name "cookie_radar_*.sql" -mtime +7 -delete
      '';
    };
  };

  systemd.timers.db-backup = {
    description = "Nightly PostgreSQL backup at 01:00 UTC";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 01:00:00 UTC";
      Persistent = true;
    };
  };

  system.stateVersion = "25.05";
}
