{ pkgs, ... }:
let
  cookieRadarDir = "/home/admin/cookie-radar";
in
{
  imports = [ ./hardware.nix ];

  networking.hostName = "cookiehorst";

  environment.systemPackages = with pkgs; [ go-task ];

  services.s3fs = {
    enable = true;
    keyPath = "/etc/secrets/s3fs-creds";
    mountPath = "/mnt/s3";
    bucket = "scannerbackup";
    url = "https://storage.dieter-datenschutz.de";
    extraOptions = [
      "dbglevel=info"
      "multipart_size=5000"
      "nonempty"
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
    wants = [ "network-online.target" ];
    after = [
      "docker.service"
      "network-online.target"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "admin";
      WorkingDirectory = "-${cookieRadarDir}";
      ExecStartPre = pkgs.writeShellScript "cookie-radar-pull" ''
        token=$(cat /etc/secrets/github-token)
        if [ -d ${cookieRadarDir}/.git ]; then
          ${pkgs.git}/bin/git -C ${cookieRadarDir} remote set-url origin https://x-access-token:$token@github.com/workmh155/cookie-radar
          ${pkgs.git}/bin/git -C ${cookieRadarDir} fetch origin
          ${pkgs.git}/bin/git -C ${cookieRadarDir} checkout dieter-version
          ${pkgs.git}/bin/git -C ${cookieRadarDir} reset --hard origin/dieter-version
        else
          mkdir -p ${cookieRadarDir}
          ${pkgs.git}/bin/git clone --branch dieter-version https://x-access-token:$token@github.com/workmh155/cookie-radar ${cookieRadarDir}
        fi
      '';
      # ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d --build --remove-orphans";
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f docker-compose.yml -f docker-compose.server.yml up --build -d --remove-orphans";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
    };
  };

  systemd.services.db-backup = {
    description = "PostgreSQL backup to S3";
    after = [
      "s3fs.service"
      "docker.service"
      "cookie-radar.service"
    ];
    requires = [ "s3fs.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "admin";
      WorkingDirectory = "${cookieRadarDir}";
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
