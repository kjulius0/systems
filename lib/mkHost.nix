{ nixpkgs, nixpkgs-unstable, disko, agentnet }:
name:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit nixpkgs-unstable agentnet; };
  modules = [
    disko.nixosModules.disko
    ../modules/base.nix
    ../modules/deployment.nix
    ../modules/s3fs.nix
    ../hosts/${name}
  ];
}
