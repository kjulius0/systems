{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.s3fs;
in
{
  options.services.s3fs = {
    enable = mkEnableOption "Mount S3 object storage using s3fs";

    keyPath = mkOption {
      type = types.str;
      default = "/etc/passwd-s3fs";
      description = "Path to s3fs credentials file in ACCESS_KEY:SECRET_KEY format.";
    };

    mountPath = mkOption {
      type = types.str;
      default = "/mnt/data";
      description = "Local mount path for the S3 bucket.";
    };

    bucket = mkOption {
      type = types.str;
      default = "data";
      description = "S3 bucket name.";
    };

    url = mkOption {
      type = types.str;
      default = "https://s3.amazonaws.com";
      description = "S3 endpoint URL.";
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional s3fs -o mount options.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.s3fs = {
      description = "S3 object storage s3fs";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -m 0777 -pv ${cfg.mountPath}"
        ];
        ExecStart =
          let
            options = [
              "passwd_file=${cfg.keyPath}"
              "use_path_request_style"
              "allow_other"
              "url=${cfg.url}"
              "umask=0000"
            ] ++ cfg.extraOptions;
          in
          "${pkgs.s3fs}/bin/s3fs ${cfg.bucket} ${cfg.mountPath} -f "
          + lib.concatMapStringsSep " " (opt: "-o ${opt}") options;
        ExecStopPost = "-${pkgs.fuse}/bin/fusermount -u ${cfg.mountPath}";
        KillMode = "process";
        Restart = "on-failure";
      };
    };
  };
}