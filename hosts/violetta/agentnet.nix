# agentnet on app.ultraviolet.law: the service from the agentnet flake,
# behind nginx (TLS via ACME). No basic auth: agentnet has its own login
# (Zitadel) and clients reach the client portal directly.
{ agentnet, config, ... }:
let
  host = "app.ultraviolet.law";
in
{
  imports = [ agentnet.nixosModules.default ];

  services.agentnet = {
    enable = true;
    inherit host;
    # DATABASE_URL, SECRET_KEY_BASE, BIFROST_API_KEY, TOKEN_KEY,
    # ZITADEL_ISSUER/_PAT/_ORG_ID, MJ_APIKEY_PUBLIC/_PRIVATE,
    # MAIL_FROM_EMAIL/_NAME, PUBLIC_BASE_URL
    environmentFile = "/etc/agentnet/env";
    # firms' own client portal addresses (CNAME to portal.ultraviolet.law):
    # nginx answers other hostnames with certificates fetched on demand
    portalDomains = {
      enable = true;
      target = "portal.ultraviolet.law";
    };
  };

  services.nginx.virtualHosts.${host} = {
    enableACME = true;
    forceSSL = true;
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
