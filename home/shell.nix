# shell.nix -- librefos's bash.  The prompt, the editor and the SSH
# agent are the system's: modules/shell.nix.

{
  # set -o vi stays a line of shell: the only option for vi keys is
  # readline's editing-mode, which would change every readline program.
  # History sizes, histappend and checkwinsize are left to the defaults.
  programs.bash = {
    enable = true;
    historyControl = [
      "erasedups"
      "ignoreboth"
    ];
    shellAliases = {
      ls = "ls --classify --color=never";
      grep = "grep --color=auto";
    };
    initExtra = ''
      set -o vi
    '';
  };
}
