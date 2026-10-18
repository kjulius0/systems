{
  description = "Business server fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Only for hosts that need newer packages than the stable channel
    # (violetta: Jitsi). Hosts opt in per package; the system stays stable.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # the full prototype (login, tenancy, client portal) lives on this branch
    agentnet.url = "git+ssh://git@github.com.private/wintermute-cell/agentnet?ref=full-prototype";
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      disko,
      agentnet,
      ...
    }:
    let
      mkHost = import ./lib/mkHost.nix {
        inherit
          nixpkgs
          nixpkgs-unstable
          disko
          agentnet
          ;
      };
    in
    {
      nixosConfigurations = {
        # Add hosts here. Each host lives in hosts/<name>/.
        # example = mkHost "example";
        cookiehorst = mkHost "cookiehorst";
        fortress = mkHost "fortress";
        violetta = mkHost "violetta";
      };
    };
}
