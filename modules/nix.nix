# nix.nix -- Nix itself: features, garbage collection, store
# optimisation.

{
  # Flakes stay off; nix-command is kept for the newer CLI.
  nix.settings.experimental-features = [ "nix-command" ];

  # Generations are the rollback mechanism and this deletes them, so the
  # window is the safety net being sized.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}
