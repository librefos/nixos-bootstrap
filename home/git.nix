# git.nix -- git with signed commits and send-email, GnuPG to sign with,
# and ssh-sendmail, which git and Gnus both send mail through.

{ pkgs, ... }:

{
  # signing sets user.signingKey, commit.gpgSign and tag.gpgSign; the
  # format is stated because its default depends on home.stateVersion.
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Thiago C. Silva";
        email = "librefos@newliber.com";
      };
      sendemail = {
        sendmailcmd = "ssh-sendmail";
        transferEncoding = "8bit";
        assume8bitEncoding = "UTF-8";
        confirm = "always";
        annotate = true;
      };
    };
    signing = {
      key = "74DB0F2861858C96D636C0BC1DCAB8FD50D746A9";
      format = "openpgp";
      signByDefault = true;
    };
  };

  # The secret key is imported by hand and never enters this repository.
  #
  # A graphical pinentry, so every caller gets the same prompt: git in a
  # terminal, Emacs, and git started from Emacs.  pinentry-curses has to
  # be told which terminal to draw in, and a program started from the
  # session has none, which surfaces as "Inappropriate ioctl for
  # device".  gnome3 over qt because GTK3 is already here; it draws
  # through gcr's prompter, the D-Bus service modules/session.nix
  # registers, and falls back to curses without it.
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };

  # A script, so it stays a file.  Built into a package rather than
  # linked into ~/.local/bin, so it is on PATH without that directory.
  # writeScriptBin copies the text verbatim, shebang included, and adds
  # no runtime dependencies, so whatever that shebang names has to be
  # resolvable when git or Gnus runs it.
  home.packages = [
    (pkgs.writeScriptBin "ssh-sendmail" (builtins.readFile ./files/ssh-sendmail))
  ];
}
