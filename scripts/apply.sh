#!/usr/bin/env bash
# apply.sh -- bring a new commit of this repository onto the running
# desktop.
#
# Runs as root, from a copy of the repository unpacked off the stick, as
# install-runbook.md describes under Changing the installed system:
#
#   bash /root/nixos/scripts/apply.sh
#
# Nothing changes until it has shown what would be built and been told
# yes.  In order: every .nix file parses; the new configuration
# evaluates in a staging copy beside this machine's own
# hardware-configuration.nix, and nixos-rebuild dry-build lists what it
# would download and what it would compile; then, after a yes, the
# previous /etc/nixos is saved to /root/etc-nixos.before-apply, the
# repository's files replace it, and nixos-rebuild switch runs.  A
# generation that turns out wrong is still one boot menu entry away,
# and the saved /etc/nixos is what puts the files back to match it.
set -euo pipefail

repo=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
managed=(system.nix configuration.nix disko.nix modules home scripts)
stage=/root/nixos-stage
saved=/root/etc-nixos.before-apply

stop() {
  echo >&2
  echo "STOP: $*" >&2
  exit 1
}
trap 'echo "STOP: a command failed, line $LINENO.  Its output is above." >&2' ERR

[ "$(id -u)" = 0 ] || { echo "Run it as root: sudo -i first." >&2; exit 1; }
[ "$(cat /proc/sys/kernel/hostname)" = amd ] || stop "this is not the amd desktop."
[ "$repo" != /etc/nixos ] || stop "run it from the unpacked copy, not from /etc/nixos."
for f in "${managed[@]}"; do
  [ -e "$repo/$f" ] || stop "missing $repo/$f"
done
[ -f /etc/nixos/hardware-configuration.nix ] || stop "no /etc/nixos/hardware-configuration.nix."

echo "== parse"
while IFS= read -r f; do
  nix-instantiate --parse "$f" > /dev/null || stop "${f#"$repo"/} does not parse."
done < <(find "$repo" -name '*.nix' | sort)
echo "every .nix file parses"

echo
echo "== what differs from /etc/nixos"
for f in "${managed[@]}"; do
  diff -rq "/etc/nixos/$f" "$repo/$f" 2>&1 || true
done

echo
echo "== evaluate and dry-build, in $stage"
rm -rf "$stage"
mkdir -p "$stage"
for f in "${managed[@]}"; do
  cp -r "$repo/$f" "$stage/"
done
cp /etc/nixos/hardware-configuration.nix "$stage/"
if ! nixos-rebuild dry-build --file "$stage/system.nix" 2>&1 | tee /root/apply-dry-build.log; then
  stop "the configuration does not evaluate or build; the output is above and in /root/apply-dry-build.log.  /etc/nixos is untouched."
fi

cat <<'EOF'

Read the list above.  "will be fetched" comes from the binary cache.
"will be built" is compiled here: small derivations, configuration
files, wrappers, home-manager's generation, are expected.  A large
package in that list, firefox-devedition-unwrapped or hyprland for
instance, means hours of compiling and is a reason to answer no.

EOF
read -rp "Switch to this configuration?  Type yes: " answer
[ "$answer" = yes ] || { echo "Nothing changed."; exit 0; }

echo
echo "== /etc/nixos"
rm -rf "$saved"
cp -a /etc/nixos "$saved"
echo "the previous /etc/nixos is in $saved"
find /etc/nixos -mindepth 1 -maxdepth 1 ! -name hardware-configuration.nix -exec rm -rf {} +
for f in "${managed[@]}"; do
  cp -r "$repo/$f" /etc/nixos/
done
ls /etc/nixos

echo
echo "== switch"
switched=yes
if ! nixos-rebuild switch --file /etc/nixos/system.nix 2>&1 | tee /root/apply-switch.log; then
  switched=no
fi

# Shown whatever happened: a switch that fails while starting units has
# still activated the new generation, and these say what is left to do.
echo
echo "== home-manager-librefos"
systemctl --no-pager --lines=15 status home-manager-librefos || true
echo
echo "== failed units"
systemctl --failed --no-legend | grep . || echo "none"

if [ "$switched" = no ]; then
  cat <<EOF

STOP: nixos-rebuild switch reported a failure.  The output is above and
in /root/apply-switch.log.

If it got as far as starting units, the new generation is active, and
only the failed units above need attention.  home-manager saying a file
"would be clobbered" means a real file is where a link belongs: look at
it, move it aside, then run

  systemctl restart home-manager-librefos

If it failed before activating, nothing changed but /etc/nixos.  Either
way the previous generation is in the boot menu, and the previous
/etc/nixos is in $saved.
EOF
  exit 1
fi

cat <<'EOF'

Switched.  Log out of Hyprland and back in on tty1, so the session, the
shell and the agents all start from the new generation.
EOF
