# documentation.nix -- a machine that answers its own questions offline.

{ pkgs, ... }:

{
  # These two default to false, and are exactly the two worth turning
  # on: without the cache apropos and man -k find nothing, and without
  # dev there are no library pages.
  documentation.man.cache.enable = true;
  documentation.dev.enable = true;
  documentation.nixos.includeAllModules = true;

  environment.systemPackages = with pkgs; [
    man-pages
    man-pages-posix
  ];
}
