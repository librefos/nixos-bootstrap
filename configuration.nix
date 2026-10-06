# configuration.nix -- the amd desktop.  MSI A520M-A PRO, Ryzen 5700G,
# one Lexar NVMe, Realtek Ethernet, no wireless.
#
# The system half, split by concern under modules/; the user half, for
# librefos, under home/.  Where NixOS or home-manager has an option for
# something, the option is used; a file is kept only where no option can
# express the content.
#
# Deliberately absent, each for a reason recorded in the README:
#   TPM auto-unlock                        deferred
#   an overlay, patched packages           none needed
#   zswap.enabled=0                        a no-op on NixOS
#   UFW, reflector, mkinitcpio, genfstab   no equivalent and none needed
#   impermanence                           tried and removed

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./modules/boot.nix
    ./modules/filesystems.nix
    ./modules/memory-cpu.nix
    ./modules/graphics.nix
    ./modules/session.nix
    ./modules/shell.nix
    ./modules/firefox.nix
    ./modules/network.nix
    ./modules/users.nix
    ./modules/documentation.nix
    ./modules/packages.nix
    ./modules/compat.nix
    ./modules/nix.nix
  ];

  # Set once, at install time, and never bumped casually: it pins
  # stateful defaults, not package versions.
  system.stateVersion = "26.11";
}
