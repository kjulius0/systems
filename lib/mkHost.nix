{ nixpkgs, disko }:
name:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    disko.nixosModules.disko
    ./modules/base.nix
    ./hosts/${name}
  ];
}
