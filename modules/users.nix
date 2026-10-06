# users.nix -- the two accounts, sudo, and the home-manager wiring for
# the user half.

{ pkgs, ... }:

{
  # With mutableUsers off, passwd stops working and both hashes come
  # from files outside this repository, so no hash is ever committed.
  # Those files have to exist before the first activation or nobody can
  # log in, root included.
  users.mutableUsers = false;

  users.users.root.hashedPasswordFile = "/etc/passwords/root";

  users.users.librefos = {
    isNormalUser = true;
    description = "Thiago C. Silva";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
    hashedPasswordFile = "/etc/passwords/librefos";
  };

  security.sudo.enable = true;
  security.sudo.execWheelOnly = true;

  # useGlobalPkgs builds it from this system's pkgs, the one pin, not a
  # second nixpkgs instance.  useUserPackages hands home.packages to
  # users.users.librefos.packages; without it, activation runs nix-env
  # into a per-user profile, which is the imperative state this avoids.
  #
  # No backupFileExtension, so an existing file where a link belongs
  # stops activation with "would be clobbered".  Wanted: a stray file
  # should be looked at, not renamed out of sight.
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.librefos = import ../home;
}
