# filesystems.nix -- what runs on top of the disk disko.nix declares.
#
# The disk, the LUKS container, the subvolumes and every mount option
# are in disko.nix, which the disko module turns into fileSystems and
# boot.initrd.luks.devices.

{
  services.fstrim.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  hardware.block.defaultSchedulerRotational = "bfq";
  hardware.block.scheduler = {
    "nvme[0-9]*" = "none";
  };

  # snapper on /home only: generations cover everything the
  # configuration owns and never touch /home.  @snapshots is declared in
  # disko.nix, because this module never runs snapper create-config and
  # so nothing else would create it.
  services.snapper.configs.home = {
    SUBVOLUME = "/home";
    FSTYPE = "btrfs";
    ALLOW_USERS = [ "librefos" ];
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
  };
}
