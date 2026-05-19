# hardware.nix — disk layout + boot for a generic VPS (BIOS/GPT, single disk)
#
# Adjust `device` to match the actual disk on your provider
# (Hetzner/DigitalOcean/Vultr: usually /dev/sda or /dev/vda).
{ modulesPath, lib, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";   # <-- change if needed
    content = {
      type = "gpt";
      partitions = {
        # 1 MiB BIOS boot partition required by GRUB on GPT without UEFI
        boot = {
          size = "1M";
          type = "EF02";
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  boot.loader.grub = {
    enable = true;
    devices = lib.mkForce [ "/dev/sda" ];   # match device above
  };

  boot.initrd.availableKernelModules = [
    "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
