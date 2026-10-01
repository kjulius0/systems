{ nixpkgs, nixpkgs-unstable, disko }:
name:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit nixpkgs-unstable; };
  modules = [
    disko.nixosModules.disko
    ../modules/base.nix
    ../modules/deployment.nix
    ../modules/s3fs.nix
    ../hosts/${name}
  ];
}
