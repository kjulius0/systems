{
  description = "Business server fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, disko, ... }:
    let
      mkHost = import ./lib/mkHost.nix { inherit nixpkgs disko; };
    in
    {
      nixosConfigurations = {
        # Add hosts here. Each host lives in hosts/<name>/.
        # example = mkHost "example";
        cookiehorst = mkHost "cookiehorst";
      };
    };
}
