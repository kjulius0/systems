# hardware.nix — Wodanio VPS (Proxmox/KVM, i440FX BIOS, single 50G /dev/sda)
{ modulesPath, lib, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
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
    devices = lib.mkForce [ "/dev/sda" ];
  };

  boot.initrd.availableKernelModules = [
    "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"
  ];

  # Proxmox console/status/shutdown integration.
  services.qemuGuest.enable = true;

  # compressed swap in RAM first (zram, priority 5); the swap file on disk
  # only catches what no longer fits, so a peak of agent sessions slows the
  # VM down instead of the OOM killer ending a process
  zramSwap.enable = true;
  swapDevices = [
    { device = "/var/lib/swapfile"; size = 8 * 1024; priority = 1; }
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
