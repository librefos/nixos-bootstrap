# disko.nix -- the disk of the amd desktop, declared.
#
# One description, two jobs: the disko module turns it into fileSystems
# and boot.initrd.luks.devices for the running system, and the disko
# command reads the same file on a reinstall to erase, partition,
# encrypt, format and mount.  hardware-configuration.nix is generated
# with --no-filesystems so nothing is defined twice.
#
# Partitions are found by GPT partition name, /dev/disk/by-partlabel/,
# which is what lets one file describe a disk that does not exist yet.
# label is set explicitly because disko's defaults (disk-main-ESP and
# so on) would name partitions this disk does not have.

let
  # zstd defaults to level 3; the level is written out so these read the
  # same as findmnt reports them.  subvol= is added by disko, after.
  btrfs = [
    "noatime"
    "compress=zstd:3"
    "ssd"
    "discard=async"
    "space_cache=v2"
  ];
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";

    content = {
      type = "gpt";

      partitions = {
        # Every generation keeps a kernel and a signed image here, so
        # the depth of the menu is capped by configurationLimit in
        # modules/boot.nix.
        ESP = {
          label = "ESP";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            extraArgs = [ "-F" "32" "-n" "BOOT" ];
            mountpoint = "/boot";
            mountOptions = [ "fmask=0077" "dmask=0077" ];
          };
        };

        cryptroot = {
          label = "cryptroot";
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            extraFormatArgs = [ "--type" "luks2" "--label" "cryptroot" ];

            # No passwordFile and no keyFile, so a reinstall asks at the
            # terminal for the passphrase typed at every boot.
            #
            # allowDiscards passes TRIM through the container; without
            # it fstrim and discard=async reach the filesystem and stop
            # there.  The cost is that somebody holding the powered-off
            # disk learns which blocks are in use.  Accepted.
            settings.allowDiscards = true;

            content = {
              type = "btrfs";
              extraArgs = [ "-L" "nixos" ];

              # @nix is separate so that rolling @ back never rolls the
              # store back with it.  @snapshots is top-level rather than
              # nested under @home, because services.snapper never runs
              # create-config and so nothing would otherwise create it.
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = btrfs;
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = btrfs;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfs;
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = btrfs;
                };
                "@snapshots" = {
                  mountpoint = "/home/.snapshots";
                  mountOptions = btrfs;
                };
              };
            };
          };
        };
      };
    };
  };
}
