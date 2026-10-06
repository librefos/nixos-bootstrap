# shell.nix -- what every shell shares: the prompt, the editor and the
# SSH agent.  librefos's own bash settings are in home/shell.nix.

{ pkgs, ... }:

{
  # The NixOS default prompt begins with \n -- the blank line after
  # every command's output -- and paints itself green, or red as root.
  # Both are dropped; bash's \$ already prints # for uid 0.  The escape
  # sets the window title, which the bar reads, so it stays.
  # (nixos/modules/programs/bash/bash.nix, promptInit)
  programs.bash.promptInit = ''
    if [ "$TERM" != "dumb" ]; then
      PS1="\[\e]0;\u@\h: \w\a\][\u@\h:\w]\$ "
    fi
  '';

  # The editors here are Emacs, in home/emacs.nix, and ed.  nano has to
  # be switched off explicitly: NixOS installs it and sets EDITOR=nano
  # with mkDefault.
  #
  # EDITOR is a session variable, not environment.variables, so it also
  # reaches /etc/pam/environment and therefore the systemd user manager
  # and the services under it.  NixOS copies session variables into
  # environment.variables, where this plain definition outranks nano's
  # mkDefault.  (nixos/modules/config/shells-environment.nix)
  programs.nano.enable = false;
  environment.systemPackages = [ pkgs.ed ];
  environment.sessionVariables.EDITOR = "ed";

  # SSH_AUTH_SOCK is exported from /etc/profile, before the login shell
  # starts the session, so Hyprland and everything under it find the
  # agent.  Keys are still added by hand, with ssh-add.
  programs.ssh.startAgent = true;
}
