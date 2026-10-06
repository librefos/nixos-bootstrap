# emacs.nix -- Emacs, native Wayland, and Gnus.

{ pkgs, ... }:

{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
  };

  # Gnus reads ~/.gnus.el and nothing else, and no option writes it.
  home.file.".gnus.el".source = ./files/gnus.el;
}
