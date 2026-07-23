{ pkgs, ... }:
let
  ssh-keys = import ../lib/ssh-keys.nix;
in
{
  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [ git htop curl vim ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    ssh-keys.julius
    ssh-keys.marc
    ssh-keys.martin
  ];

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
}
