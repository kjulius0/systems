{ pkgs, ... }:
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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBWZVz+NY4jhXnFoIw6O7ZTMzUdDmECXIBWTth1j6cw work@rakka"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1/FazxEZSGjnfqaR5tM8aifZCY+hns1DfCo87z8Hr1 marc@LWM"

  ];

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
}
