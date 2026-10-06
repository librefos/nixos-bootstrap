# hyprland.nix -- the compositor's settings, the bar, the lock screen
# and the idle rules, all four through home-manager options.
#
# The standing preference for this machine is values over visuals: no
# icons, no animation, monochrome, and nothing on screen that has to be
# decoded before it can be read.

{ lib, ... }:

let
  toLua = lib.generators.toLua { };
  lua = lib.generators.mkLuaInline;
  exec = command: lua "hl.dsp.exec_cmd(${toLua command})";

  bind = key: dispatcher: { _args = [ key dispatcher ]; };
  bindWith = key: dispatcher: flags: { _args = [ key dispatcher flags ]; };

  mod = "SUPER";
  terminal = "foot";

  # wmenu has no configuration file, so its whole appearance is these
  # flags.  No -l, so it is the single dmenu line across the top rather
  # than a box.  The font is "monospace" for the same reason foot's is:
  # fontconfig resolves it to Terminus.
  #
  # 12px, not a point size, so that it matches the bar's stylesheet
  # exactly; wmenu then sizes its window to that font and lands on the
  # 16 pixels the bar's height is set to below, which is what puts the
  # two lines of text on one baseline.
  #
  # N/n are the line, M/m the prompt, S/s the highlighted match, all of
  # them black, grey or white.  The match is marked the way the bar
  # marks its clock, white text among grey with no background of its
  # own, so S is the line's black; wmenu has one font for everything,
  # -f, so colour is the only thing the selection can change.  The caret
  # is not one of these: wmenu draws it always and in the -n colour, so
  # no flag turns it off.  (wmenu 0.2.0, render.c render_cursor)
  menu =
    "wmenu-run -i -f 'monospace 12px'"
    + " -N 000000 -n bbbbbb -M 000000 -m 888888 -S 000000 -s ffffff";

  # Switch workspaces with mod + [0-9], move the active window with
  # mod + SHIFT + [0-9]; 0 is the tenth.  Upstream writes this as a Lua
  # loop; here the loop runs in Nix and writes twenty binds.
  workspaceBinds = lib.concatMap (
    i:
    let
      key = toString (lib.mod i 10);
    in
    [
      (bind "${mod} + ${key}" (lua "hl.dsp.focus({ workspace = ${toString i} })"))
      (bind "${mod} + SHIFT + ${key}" (lua "hl.dsp.window.move({ workspace = ${toString i} })"))
    ]
  ) (lib.range 1 10);
in
{
  # --- the compositor ---------------------------------------------------
  # Written to ~/.config/hypr/hyprland.lua: each attribute becomes an
  # hl.<name>(...) call, _args one with several arguments, mkLuaInline
  # raw Lua.  package and portalPackage are null because NixOS installs
  # both; systemd.enable is false because uwsm owns the session, and
  # home-manager's hyprland-session.target would be a second session
  # manager.  importantPrefixes puts monitor and config ahead of the
  # binds.  (home-manager, services/window-managers/hyprland/)
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    configType = "lua";
    importantPrefixes = [
      "monitor"
      "config"
    ];

    settings = {
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = "1";
      };

      config = {
        # Hyprland reads its own input block and ignores
        # services.xserver.xkb, which only feeds systemd-localed and the
        # console.  Without these two, dead keys stop working and
        # accented characters go with them.
        input = {
          kb_layout = "us";
          kb_variant = "intl";
          follow_mouse = 1;
        };

        # Everything visual, turned off explicitly: gaps, rounding,
        # blur, shadows, animations and the bundled wallpaper are all
        # defaults in Hyprland's built-in configuration, so this is
        # subtraction, not a fight with the tool.  With border_size 0
        # there is nothing to colour, so there is no col block.
        general = {
          gaps_in = 0;
          gaps_out = 0;
          border_size = 0;
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };

        decoration = {
          rounding = 0;
          active_opacity = 1.0;
          inactive_opacity = 1.0;
          shadow.enabled = false;
          blur.enabled = false;
        };

        animations.enabled = false;

        misc = {
          # 0 disables the wallpaper Hyprland ships with, which is why
          # there is no wallpaper daemon: there is nothing to cover.
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
          # The line of text along the bottom of an empty screen is the
          # splash, a separate switch from the logo.
          disable_splash_rendering = true;
          # What is behind every window once the wallpaper is gone.  The
          # default is a near-black grey, 0xff111111.  Colours must be
          # strings: the Lua colour type rejects a number.
          # (src/config/lua/types/LuaConfigColor.cpp)
          background_color = "rgba(000000ff)";
        };

        # Upstream's, kept.  New windows split the active window, not
        # the one under the mouse, along its longer side, so opening one
        # while the terminal has focus halves the terminal; mod + J
        # turns a split around.
        dwindle.preserve_split = true;

        # Nothing installed here needs X, and 0.56.2 starts Xwayland
        # with the compositor rather than on demand.  Off here, at
        # runtime, and not through programs.hyprland.xwayland.enable,
        # which would rebuild the package; a reload applies either way.
        xwayland.enabled = false;
      };

      # Upstream's own binds, from example/hyprland.lua at v0.56.2, on
      # purpose.  Only what they launch changed, to what is installed,
      # and binds for programs that are not installed were left out.
      # One bind is not upstream's: the lock.
      bind = [
        (bind "${mod} + Q" (exec terminal))
        (bind "${mod} + C" (lua "hl.dsp.window.close()"))
        # hyprshutdown is packaged but not installed, so this falls
        # through to a plain exit, which returns to the tty1 login.
        (bind "${mod} + M" (
          exec "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
        ))
        (bind "${mod} + V" (lua ''hl.dsp.window.float({ action = "toggle" })''))
        (bind "${mod} + R" (exec menu))
        (bind "${mod} + P" (lua "hl.dsp.window.pseudo()"))
        # dwindle only
        (bind "${mod} + J" (lua ''hl.dsp.layout("togglesplit")''))

        # Move focus with mod + arrow keys
        (bind "${mod} + left" (lua ''hl.dsp.focus({ direction = "left" })''))
        (bind "${mod} + right" (lua ''hl.dsp.focus({ direction = "right" })''))
        (bind "${mod} + up" (lua ''hl.dsp.focus({ direction = "up" })''))
        (bind "${mod} + down" (lua ''hl.dsp.focus({ direction = "down" })''))
      ]
      ++ workspaceBinds
      ++ [
        # Example special workspace (scratchpad)
        (bind "${mod} + S" (lua ''hl.dsp.workspace.toggle_special("magic")''))
        (bind "${mod} + SHIFT + S" (lua ''hl.dsp.window.move({ workspace = "special:magic" })''))

        # Scroll through existing workspaces with mod + scroll
        (bind "${mod} + mouse_down" (lua ''hl.dsp.focus({ workspace = "e+1" })''))
        (bind "${mod} + mouse_up" (lua ''hl.dsp.focus({ workspace = "e-1" })''))

        # Move and resize windows with mod + LMB/RMB and dragging
        (bindWith "${mod} + mouse:272" (lua "hl.dsp.window.drag()") { mouse = true; })
        (bindWith "${mod} + mouse:273" (lua "hl.dsp.window.resize()") { mouse = true; })

        # Volume keys.  wpctl comes with wireplumber.  locked keeps them
        # working while hyprlock is up.
        (bindWith "XF86AudioRaiseVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+") {
          locked = true;
          repeating = true;
        })
        (bindWith "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") {
          locked = true;
          repeating = true;
        })
        (bindWith "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") {
          locked = true;
          repeating = true;
        })
        (bindWith "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") {
          locked = true;
          repeating = true;
        })

        # The one bind that is not upstream's.  It asks logind to lock
        # the session rather than starting hyprlock itself, so the lock
        # goes through hypridle's lock_cmd, the same path as the idle
        # timeout and sleep, and a second press cannot start a second
        # hyprlock.
        (bind "${mod} + SHIFT + L" (exec "loginctl lock-session"))
      ];

      # Upstream's window rules, kept as they are.  The second has
      # nothing to match while XWayland is off.
      window_rule = [
        {
          # Ignore maximize requests from all apps.
          name = "suppress-maximize-events";
          match.class = ".*";
          suppress_event = "maximize";
        }
        {
          # Fix some dragging issues with XWayland
          name = "fix-xwayland-drags";
          match = {
            class = "^$";
            title = "^$";
            xwayland = true;
            float = true;
            fullscreen = false;
            pin = false;
          };
          no_focus = true;
        }
        {
          name = "move-hyprland-run";
          match.class = "hyprland-run";
          move = "20 monitor_h-120";
          float = true;
        }
      ];
    };
  };

  # --- the bar ------------------------------------------------------------
  # Text only, on purpose: an icon is a value you have to decode, a word
  # is the value itself.  So there is no icon font anywhere, and no
  # battery module, this being a tower.
  #
  # The whole bar is here because NixOS's programs.waybar has a service
  # but no settings.  home-manager runs it as a user service wanted by
  # graphical-session.target, which uwsm provides.
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "graphical-session.target" ];
    };

    settings.bar = {
      layer = "top";
      position = "top";
      # The height wmenu computes for itself at the shared 12px font, so
      # the launcher covers the bar rather than sitting above it.  The
      # text needs 13 of those pixels; waybar grows the bar rather than
      # clipping if a module ever needs more.
      height = 16;
      spacing = 12;

      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "hyprland/window" ];
      modules-right = [
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "clock"
      ];

      "hyprland/workspaces" = {
        format = "{id}";
        on-click = "activate";
      };

      "hyprland/window" = {
        format = "{title}";
        max-length = 70;
        separate-outputs = true;
      };

      pulseaudio = {
        format = "vol {volume}%";
        format-muted = "vol muted";
        on-click = "pavucontrol";
      };

      network = {
        # No wifi formats: there is no wireless hardware on this board.
        format-ethernet = "net {ipaddr}";
        format-linked = "net {ifname} no address";
        format-disconnected = "net down";
        tooltip-format = "{ifname} via {gwaddr}";
      };

      cpu.format = "cpu {usage}%";
      memory.format = "mem {percentage}%";

      clock = {
        format = "{:%Y-%m-%d %H:%M}";
        tooltip-format = "<tt>{calendar}</tt>";
      };
    };

    # Monochrome, no rounding, no transparency, and no line under the
    # bar.  The font is named rather than left to fontconfig because
    # waybar's own stylesheet hardcodes FontAwesome, and this replaces
    # it wholesale.
    style = ''
      * {
        font-family: "Terminus (TTF)", "DejaVu Sans Mono", monospace;
        font-size: 12px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background-color: #000000;
        color: #bbbbbb;
      }

      #workspaces button {
        padding: 0 6px;
        color: #666666;
        background: transparent;
      }

      #workspaces button.active {
        color: #ffffff;
      }

      #workspaces button.urgent {
        color: #ffffff;
        background-color: #333333;
      }

      #window {
        color: #888888;
      }

      #pulseaudio,
      #network,
      #cpu,
      #memory,
      #clock {
        padding: 0 4px;
      }

      #clock {
        color: #ffffff;
      }

      #network.disconnected {
        color: #ffffff;
        background-color: #333333;
      }
    '';
  };

  # --- the lock screen ----------------------------------------------------
  # package is null: NixOS installs hyprlock and owns its PAM service.
  #
  # Everything below subtracts from widget defaults that are animated
  # and coloured.  fail_color also covers caps lock, since
  # capslock_color is unset and falls back to it.  fail_text is plain
  # $FAIL because the default wraps it in <i></i>.
  #
  # Positions are offsets from the centre, positive y upward.  The date
  # needs cmd[] because $TIME is only the time, and update:1000 so the
  # minute turns over on time.
  programs.hyprlock = {
    enable = true;
    package = null;
    settings = {
      animations.enabled = false;

      background = [
        {
          monitor = "";
          color = "rgba(000000ff)";
        }
      ];

      label = [
        {
          monitor = "";
          text = "$USER";
          color = "rgba(ffffffff)";
          font_size = 12;
          font_family = "monospace";
          position = "0, 66";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:1000] date +'%Y-%m-%d %H:%M'";
          color = "rgba(ffffffff)";
          font_size = 12;
          font_family = "monospace";
          position = "0, 42";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "250, 40";
          rounding = 0;
          outline_thickness = 1;
          inner_color = "rgba(000000ff)";
          outer_color = "rgba(666666ff)";
          check_color = "rgba(ffffffff)";
          fail_color = "rgba(ffffffff)";
          font_color = "rgba(ffffffff)";
          font_family = "monospace";
          fade_on_empty = false;
          placeholder_text = "";
          fail_text = "$FAIL";
        }
      ];
    };
  };

  # --- idle -----------------------------------------------------------------
  # package is null: the user service is NixOS's, from
  # programs.hyprlock.  It reads this file at start, so a change applies
  # from the next login.  It cannot be left out: hypridle exits when it
  # finds no config at all.
  services.hypridle = {
    enable = true;
    package = null;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({action = \"on\"})'";
      };

      listener = [
        # lock the session after five minutes idle
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        # turn the monitor off shortly after that
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({action = \"off\"})'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({action = \"on\"})'";
        }
      ];
    };
  };
}
