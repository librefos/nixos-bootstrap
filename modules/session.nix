# session.nix -- Hyprland under uwsm, started from tty1, and the parts
# of the session the system owns.  The compositor's settings, the bar,
# the lock screen and the idle rules are the user's: home/hyprland.nix.

{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    # xwayland.enable stays at its default of true, so the package is
    # the one the binary cache has; false overrides it with a variant
    # nobody else builds and compiles Hyprland here on every pin move.
    # XWayland is switched off at runtime instead, in home/hyprland.nix.
    # (nixos/modules/programs/wayland/hyprland.nix, package apply)
  };

  # There is deliberately no programs.uwsm.waylandCompositors block.
  # The entry it generates is "uwsm start -F -- <binPath>", with no way
  # to pass uwsm's -D, so XDG_CURRENT_DESKTOP comes out derived from the
  # binary name, and it collides by name with upstream's own
  # hyprland-uwsm.desktop.  Dropping it costs nothing else: that branch
  # only feeds services.displayManager.sessionPackages, and there is no
  # display manager here.  (nixos/modules/programs/wayland/uwsm.nix)

  # may-start is the guard and is not optional: uwsm's environment
  # preloader sources the profile itself, so an unguarded exec loops.
  # It passes only in a local login shell, not root, on VT 1, with
  # graphical.target active and no session already running.  exec, so
  # leaving Hyprland returns to the login prompt; every other VT stays a
  # plain console, which is the way back in if the session fails.
  programs.bash.loginShellInit = ''
    if uwsm check may-start -q; then
      exec uwsm start -e -D Hyprland hyprland.desktop
    fi
  '';

  # Installs hyprlock with the PAM service it needs to authenticate, and
  # turns on services.hypridle.  Both read ~/.config/hypr, which
  # home/hyprland.nix writes.
  programs.hyprlock.enable = true;

  # Writes /etc/xdg/foot/foot.ini, which foot reads through
  # XDG_CONFIG_DIRS when the user has no foot.ini.  The family is
  # "monospace" so it resolves through defaultFonts.monospace below;
  # size is in points and foot is not DPI-aware, so 12 lands on the
  # 16 pixel cell the console uses.
  programs.foot = {
    enable = true;
    settings = {
      main.font = "monospace:size=12";

      # The section is colors-dark, not colors: foot 1.28.0 removed
      # [colors] and refuses the whole file over it, so every other
      # setting silently stops applying too.  The sixteen ANSI colours
      # are left alone on purpose; red for an error is a value.
      "colors-dark" = {
        background = "000000";
        foreground = "bbbbbb";
      };
    };
  };

  # 24 is a floor, not a preference: DMZ is built only at 24, 32 and 48,
  # libXcursor returns the nearest, and Hyprland draws that image at its
  # own pixel size without scaling, so asking for 16 still draws 24.
  # Set here so the login shell has it before the compositor starts.
  environment.sessionVariables = {
    XCURSOR_THEME = "DMZ-Black";
    XCURSOR_SIZE = "24";
  };

  # This writes the snippet systemd-localed reads, which is also what
  # gives the console its keymap.  Hyprland reads its own input block,
  # so home/hyprland.nix sets kb_layout and kb_variant as well or dead
  # keys stop working.
  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };
  console.useXkbConfig = true;

  # Two statements, not one: share/consolefonts is searched only for
  # packages named in console.packages, whose default is empty.  8x16 is
  # the kernel's own cell size, so only the letterforms change.
  console.packages = [ pkgs.terminus_font ];
  console.font = "ter-v16n";

  fonts.packages = with pkgs; [
    dejavu_fonts
    liberation_ttf
    noto-fonts
    noto-fonts-color-emoji
    terminus_font_ttf
  ];

  # "Terminus (TTF)" is the family name fc-list reports.  DejaVu stays
  # last so anything Terminus does not cover still renders.
  fonts.fontconfig.defaultFonts.monospace = [
    "Terminus (TTF)"
    "DejaVu Sans Mono"
  ];

  # No wallpaper daemon: there is no wallpaper, and Hyprland's own is
  # turned off in home/hyprland.nix rather than covered up.
  environment.systemPackages = with pkgs; [
    wmenu
    vanilla-dmz
    grim
    slurp
    wl-clipboard
    pavucontrol
  ];

  # gcr's prompter, the window pinentry-gnome3 draws the GPG passphrase
  # prompt in.  NixOS's GnuPG module registers it when its own pinentry
  # is gnome3; GnuPG here is home-manager's, which cannot, so it is
  # written out.  gcr_3, because that is what pinentry-gnome3 is built
  # against.  (nixos/modules/programs/gnupg.nix)
  services.dbus.packages = [ pkgs.gcr_3 ];
}
