# TODO: remove this file (and its import in ./default.nix, plus the
# nixpkgs-unstable input if nothing else uses it) once a NixOS stable
# release ships a current Jitsi — check with 26.11 (due Nov 2026): compare
# its jitsi-meet / jicofo / jitsi-videobridge versions against the ones below.

# Jitsi-Pakete und -Module aus nixpkgs-unstable statt aus nixos-26.05.
# Hintergrund (16.09.2026): 26.05 liefert jitsi-meet 1.0.8792 (Sep 2024), jicofo 1.0-1153,
# jvb 2.3-249; unstable liefert 1.0.9365 / 1.0-1189 / 2.3-307 (upstream stable: 1.0.9442).
# Die Module werden mit den Paketen getauscht, damit Optionen und Pfade zusammenpassen.
# Prosody muss mit, weil das unstable-Jitsi-Modul services.prosody.muc.*.extraModules nutzt.
{ config, pkgs, lib, nixpkgs-unstable, ... }:
let
  unstable = import nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    # jitsi-meet erbt die knownVulnerabilities von libolm (E2EE-Bibliothek, Seitenkanal-
    # CVEs 2024-45191..93). Wir nutzen Jitsis E2EE-Funktion nicht; gezielte Freigabe nur
    # für dieses Paket statt eines pauschalen NIXPKGS_ALLOW_INSECURE.
    config.allowInsecurePredicate = p: (p.pname or "") == "jitsi-meet";
  };
in
{
  disabledModules = [
    "services/web-apps/jitsi-meet.nix"
    "services/networking/jitsi-videobridge.nix"
    "services/networking/jicofo.nix"
    "services/networking/prosody.nix"
  ];
  imports = [
    "${nixpkgs-unstable}/nixos/modules/services/networking/prosody.nix"
    "${nixpkgs-unstable}/nixos/modules/services/web-apps/jitsi-meet.nix"
    "${nixpkgs-unstable}/nixos/modules/services/networking/jitsi-videobridge.nix"
    "${nixpkgs-unstable}/nixos/modules/services/networking/jicofo.nix"
  ];

  nixpkgs.overlays = [
    (final: prev: {
      jitsi-meet = unstable.jitsi-meet;
      jitsi-meet-prosody = unstable.jitsi-meet-prosody;
      jicofo = unstable.jicofo;
      jitsi-videobridge = unstable.jitsi-videobridge;
      prosody = unstable.prosody;
    })
  ];
}
