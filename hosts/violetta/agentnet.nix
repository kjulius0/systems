# agentnet on app.ultraviolet.law: the service from the agentnet flake,
# behind nginx (TLS via ACME, basic auth — agentnet itself has no login).
{ agentnet, config, ... }:
let
  host = "app.ultraviolet.law";
in
{
  imports = [ agentnet.nixosModules.default ];

  services.agentnet = {
    enable = true;
    inherit host;
    environmentFile = "/etc/agentnet/env";
  };

  services.nginx.virtualHosts.${host} = {
    enableACME = true;
    forceSSL = true;
    # the module exempts /.well-known/acme-challenge (auth_basic off), so
    # certificate renewal keeps working
    basicAuthFile = "/etc/agentnet-htpasswd";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.agentnet.port}";
      # LiveView runs over a websocket
      proxyWebsockets = true;
      # X-Forwarded-Proto: the app's force_ssl trusts it; without it every
      # proxied request looks like plain http and gets redirected forever
      recommendedProxySettings = true;
    };
  };
}
