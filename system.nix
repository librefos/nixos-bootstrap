# system.nix -- entry point for the amd desktop.  A pinned nixpkgs, no
# channels and no flakes; nixos-install and nixos-rebuild both
# understand this file.
#
#   install:  nixos-install --root /mnt --file /mnt/etc/nixos/system.nix
#   rebuild:  nixos-rebuild switch --file /etc/nixos/system.nix
#
# Both build -A config.system.build.toplevel out of what this file
# evaluates to, which is why the import below is returned bare.
#
# To move a pin, on purpose and never by accident:
#   curl -I https://channels.nixos.org/nixos-unstable   # the revision
#   nix-prefetch-url --unpack <the archive url>         # the hash

let
  # nixos-unstable, 2026-10-05.
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/494ce7fd23ff6a5dff39e1fb11e9b6f2ac74bf25.tar.gz";
    sha256 = "1z191lhpx4iy9igcv54qg8aaxdsn4szdldg9l6y2hs3k4w3hnb9n";
  };

  # nixpkgs has home-manager's CLI but not its NixOS module, so the
  # module is a second input.  Its release.json says 26.11, the same
  # release as the pin above; home-manager warns when the two disagree,
  # so this moves when that one crosses a release.
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/fe48612c5321a2cc09b0f563757a9c9733d641f8.tar.gz";
    sha256 = "1n2h4yi9kxjsk39cksr188ykza418k6rff6jb4n19c925wdpl5pa";
  };

  # Likewise disko: nixpkgs has the command, not the module.  Pinned to
  # the v1.13.0 release commit, the version of that command, so
  # disko.nix is read by one disko and not two.
  disko = builtins.fetchTarball {
    url = "https://github.com/nix-community/disko/archive/de5708739256238fb912c62f03988815db89ec9a.tar.gz";
    sha256 = "03jz60kw0khm1lp72q65z8gq69bfrqqbj08kw0hbiav1qh3g7p08";
  };

  # lanzaboote is not in nixpkgs at all, and its guide says to track a
  # release.  Its crane is pinned by hash inside it; its rust-overlay is
  # the fifth pin below instead; the nixpkgs it locks is never fetched,
  # because it is handed this one.
  lanzaboote = builtins.fetchTarball {
    url = "https://github.com/nix-community/lanzaboote/archive/7c9a54a7f87b4539ddbd8bda09a8a5f5f9361aa9.tar.gz";
    sha256 = "0rgjccwwzfanbf5chx91grmi8v9cgxgsm963ldkdnkh445as7a46";
  };

  # The rust-overlay lanzaboote v1.1.0 locks still writes stdenv.isLinux
  # and printed two deprecation warnings on every evaluation.  This is
  # the revision lanzaboote's own master moved to, handed over through
  # its rust-overlay argument so the release stays the release.  Drop
  # this pin once a lanzaboote release carries the fix.
  rust-overlay = builtins.fetchTarball {
    url = "https://github.com/oxalica/rust-overlay/archive/4748ec2f5ed4a881474ed4c98aa71a5308cdac8d.tar.gz";
    sha256 = "14s884zdrf2i8qnhfznqyfiq8di6jszrd052jxdby8qrbsjrpjm5";
  };
in
import "${nixpkgs}/nixos" {
  configuration = {
    imports = [
      ./configuration.nix
      "${home-manager}/nixos"
      "${disko}/module.nix"

      # Called with this system's pkgs, so lzbt and its stub are built
      # against the same pin as the rest.
      ({ pkgs, ... }: {
        imports = [
          (import lanzaboote { inherit pkgs rust-overlay; }).nixosModules.lanzaboote
        ];
      })
    ];

    # There is no channel here, so <nixpkgs> has to resolve to the pin
    # or nix-shell and nix repl have nothing to look at.
    nix.channel.enable = false;
    nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
  };
}
