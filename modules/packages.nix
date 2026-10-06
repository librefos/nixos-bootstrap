# packages.nix -- what is installed without a module of its own.
#
# Anything with a NixOS or home-manager module is enabled through that
# module instead, because that is also where it is configured.

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # No configuration at all; it runs on its own defaults.
    tmux

    # Makes, verifies and enrolls the Secure Boot keys.
    sbctl

    # wg and wg-quick only, not networking.wg-quick, so the tunnel is
    # configured by hand in /etc/wireguard and its keys never enter this
    # repository.  The kernel has WireGuard itself.
    wireguard-tools

    # enough to work on the machine itself
    curl
    wget
    file
    tree
    ripgrep
    htop
  ];
}
