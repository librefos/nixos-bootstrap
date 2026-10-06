# compat.nix -- letting prebuilt, dynamically linked binaries run.

{ pkgs, ... }:

{
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
  ];
}
