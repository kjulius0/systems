# Jitsi Meet for meet.kanzlei-violett.de: nginx + ACME, Prosody, Jicofo,
# Videobridge, with Kanzlei Violett branding. Packages/modules come from
# nixos-unstable (./jitsi-unstable.nix).
{ pkgs, ... }:
let
  # Branding overrides: Jitsi bundle files are replaced (via nginx) with
  # variants that append/merge the Kanzlei Violett customisations.
  # pkgs.jitsi-meet is the overlaid unstable package, so these follow
  # every Jitsi update automatically.
  jitsiCss = pkgs.runCommand "all.css" { } ''
    cat ${pkgs.jitsi-meet}/css/all.css ${./branding/overrides.css} > $out
  '';
  jitsiLangDe = pkgs.runCommand "main-de.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq -s '.[0] * .[1]' ${pkgs.jitsi-meet}/lang/main-de.json ${./branding/lang-de.json} > $out
  '';
  jitsiLangEn = pkgs.runCommand "main.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq -s '.[0] * .[1]' ${pkgs.jitsi-meet}/lang/main.json ${./branding/lang-en.json} > $out
  '';
  jitsiTitle = pkgs.writeText "title.html" "<title>Kanzlei Violett – Videokonferenz</title>\n";
in
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  # UDP 10000 (videobridge) is opened by services.jitsi-videobridge.openFirewall

  security.acme = {
    acceptTerms = true;
    defaults.email = "martin@dieter-datenschutz.de";
  };

  services.jitsi-meet = {
    enable = true;
    hostName = "meet.kanzlei-violett.de";
    # The module sets up the nginx vhost with ACME + forceSSL (mkDefault true).
    # Secure domain: only registered accounts may open rooms
    # (prosodyctl register <user> meet.kanzlei-violett.de <pw>); guests then
    # join anonymously.
    secureDomain = {
      enable = true;
      authentication = "internal_hashed";
    };
    config = {
      defaultLanguage = "de";
      enableWelcomePage = true;
      prejoinConfig.enabled = true;
      p2p.enabled = true;
      # Branding (Kanzlei Violett CI): logo, colours, background come from
      # branding/branding.json, served by nginx under /branding/.
      dynamicBrandingUrl = "https://meet.kanzlei-violett.de/branding/branding.json";
      disableThirdPartyRequests = true; # no Gravatar etc.
      # no end-to-end encryption: its key exchange uses libolm (deprecated,
      # CVE-2024-45191..93, see ./jitsi-unstable.nix). Media stays encrypted
      # in transit (WebRTC) to our own videobridge.
      e2ee.disabled = true;
    };
    interfaceConfig = {
      APP_NAME = "Kanzlei Violett";
      NATIVE_APP_NAME = "Kanzlei Violett";
      PROVIDER_NAME = "Kanzlei Violett";
      DEFAULT_BACKGROUND = "#4f2775";
      DEFAULT_LOGO_URL = "/branding/logo.png";
      DEFAULT_WELCOME_PAGE_LOGO_URL = "/branding/logo.png";
      JITSI_WATERMARK_LINK = "https://kanzlei-violett.de";
      SHOW_JITSI_WATERMARK = true; # shows our logo (DEFAULT_LOGO_URL), not Jitsi's
      SHOW_WATERMARK_FOR_GUESTS = true;
      SHOW_BRAND_WATERMARK = false;
      SHOW_POWERED_BY = false;
      MOBILE_APP_PROMO = false;
      SHOW_CHROME_EXTENSION_BANNER = false;
      DEFAULT_REMOTE_DISPLAY_NAME = "Teilnehmer";
      DEFAULT_LOCAL_DISPLAY_NAME = "ich";
      DISPLAY_WELCOME_FOOTER = false; # no app store footer
      GENERATE_ROOMNAMES_ON_WELCOME_PAGE = false; # no random English room names
    };
  };

  # Serve the branding files statically and replace Jitsi bundle files with
  # the branded variants. Exact locations win over the module's "/";
  # index.html pulls title.html in via SSI.
  services.nginx.virtualHosts."meet.kanzlei-violett.de".locations = {
    "/branding/" = {
      alias = "${./branding}/";
      extraConfig = ''
        add_header Cache-Control "public, max-age=3600";
        add_header Access-Control-Allow-Origin "https://meet.kanzlei-violett.de";
      '';
    };
    "= /css/all.css".alias = "${jitsiCss}";
    "= /lang/main-de.json".alias = "${jitsiLangDe}";
    "= /lang/main.json".alias = "${jitsiLangEn}";
    "= /title.html".alias = "${jitsiTitle}";
  };

  services.jitsi-videobridge = {
    openFirewall = true; # UDP 10000
    nat = {
      publicAddress = "91.24.43.181"; # what the browser must reach
      localAddress = "10.1.252.36";
    };
  };
}
