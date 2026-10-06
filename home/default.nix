# home/ -- the user half of the amd desktop, for librefos.
#
# Never built on its own: modules/users.nix imports it as
# home-manager.users.librefos, so nixos-rebuild builds it with the rest
# and a bad generation rolls back from the boot menu like any other.
#
# Nothing secret is here.  The GPG key, ~/.authinfo.gpg, the SSH keys
# and ~/.ssh/config are placed by hand.

{
  imports = [
    ./hyprland.nix
    ./shell.nix
    ./git.nix
    ./firefox.nix
    ./emacs.nix
  ];

  # Where the user's state started.  Not moved when the pin moves.
  home.stateVersion = "26.11";
}
