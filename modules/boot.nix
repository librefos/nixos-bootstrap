# boot.nix -- Secure Boot, the boot loader, the kernel, microcode and
# firmware.

{
  # lanzaboote replaces the systemd-boot installer with one that signs:
  # the same systemd-boot, signed, and a signed image per generation in
  # EFI/Linux instead of the unsigned entries, so the menu and rollback
  # carry over and configurationLimit still applies.  The module is
  # imported in system.nix; the keys are in /var/lib/sbctl, protected
  # only by the encrypted disk.
  boot.loader.systemd-boot.enable = false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";

    # Together these make an install that enrolls itself, so no key is
    # kept or copied anywhere:
    #
    #   autoGenerateKeys  sbctl create-keys on boot, only while
    #                     /var/lib/sbctl/keys is absent.  It also turns
    #                     on allowUnsigned, which lzbt acts on only
    #                     while both key files are missing, which is
    #                     what lets nixos-install run before any key
    #                     exists.
    #   autoEnrollKeys    exports them once into /boot/loader/keys/auto
    #                     and sets secure-boot-enroll force, which
    #                     systemd-boot acts on in Setup Mode and ignores
    #                     in User Mode.
    #
    # includeMicrosoftKeys is false because there are no expansion cards
    # here, so no option ROM needs verifying.  The module allows that
    # only with allowBrickingMyMachine, which skips sbctl's own
    # option-ROM check; scripts/reinstall.sh runs that check from the
    # installer instead, before anything is erased.  No autoReboot.
    # (lanzaboote v1.1.0, nix/modules/lanzaboote.nix;
    # rust/tool/systemd/src/cli.rs)
    autoGenerateKeys.enable = true;
    autoEnrollKeys = {
      enable = true;
      includeMicrosoftKeys = false;
      allowBrickingMyMachine = true;
    };
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # NixOS leaves the boot menu's editor on for backwards compatibility
  # and recommends false, because it gives root through init=/bin/sh.
  # lanzaboote copies the value into its loader.conf.
  boot.loader.systemd-boot.editor = false;

  # The 1 GiB ESP holds a kernel and a signed image per generation.
  # Garbage collection bounds the store separately, in nix.nix; the two
  # limits are not the same limit.
  boot.loader.systemd-boot.configurationLimit = 10;

  boot.kernelParams = [ "amd_pstate=active" ];
  boot.initrd.kernelModules = [ "amdgpu" ];

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
}
