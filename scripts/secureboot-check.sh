#!/usr/bin/env bash
# secureboot-check.sh -- prove Secure Boot enforces, after an install.
#
# Secure Boot comes up by itself from configuration.nix: the first boot
# makes the keys, the next one enrolls them through systemd-boot, and
# from then on the firmware verifies.  A status line is not proof on
# this board (firmware quirk FQ0001), so this script tests it, in two
# runs:
#
#   first run   Secure Boot must already report enforcing.  Checks that
#               every boot file is signed and adds a boot entry for the
#               one unsigned file, the kernel, then asks for a reboot.
#               Picked in the menu, that entry must fail to load.
#   second run  removes the entry and reports.
#
# It changes nothing but that entry.  The reasoning is in the README,
# under Boot and Secure Boot.
set -euo pipefail

stop() {
  echo >&2
  echo "STOP: $*" >&2
  exit 1
}

sbctl=/run/current-system/sw/bin/sbctl
entry=/boot/loader/entries/sb-test.conf
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

[ -x "$sbctl" ] || stop "sbctl is not installed in this system."

sb_line=$(sudo bootctl status --no-pager 2>/dev/null | grep 'Secure Boot:' || true)
echo "== bootctl: ${sb_line#"${sb_line%%[![:space:]]*}"}"
echo "== sbctl status"
sudo "$sbctl" status

if ! echo "$sb_line" | grep -q 'enabled (user)'; then
  echo "== keys waiting on the ESP for systemd-boot"
  sudo sh -c 'ls -1 /boot/loader/keys/auto 2>/dev/null' || echo "none"
  echo "== the services that make and export them"
  systemctl --no-pager status generate-sb-keys prepare-sb-auto-enroll \
    2>/dev/null | grep -E '^(●|○)|Active:|Condition' || true
  stop "Secure Boot is not enforcing yet.  On the first boot after an
  install, reboot once and let systemd-boot enroll the keys when it
  counts down, then run this again.  If it still is not enforcing,
  check the firmware: Secure Boot Enabled, Mode Custom, Preset Maximum
  Security."
fi
echo
echo "Secure Boot is enforcing, in user mode."

echo "== sbctl verify"
sudo "$sbctl" verify 2>&1 | tee "$work/verify.txt" > /dev/null || true
cat "$work/verify.txt"
grep -q 'BOOTX64.EFI is signed' "$work/verify.txt" \
  || stop "EFI/BOOT/BOOTX64.EFI is not reported signed."
grep -q 'systemd-bootx64.efi is signed' "$work/verify.txt" \
  || stop "EFI/systemd/systemd-bootx64.efi is not reported signed."
gen=$(readlink /nix/var/nix/profiles/system); gen=${gen#system-}; gen=${gen%-link}
grep -q "nixos-generation-$gen-.*is signed" "$work/verify.txt" \
  || stop "the image for generation $gen, the default, is not reported signed."
# Kernels and initrds are expected unsigned: the signed image carries
# their hashes.  No grep -q in this pipe, since with pipefail an early
# exit can hide a match.
grep 'not signed' "$work/verify.txt" | grep -v -E '/(kernel|initrd)-[^/]*$' \
  > "$work/unsigned.txt" || true
if [ -s "$work/unsigned.txt" ]; then
  cat "$work/unsigned.txt"
  stop "a boot file other than a kernel or initrd is not signed."
fi
echo "signed: systemd-boot, the fallback loader, generation $gen's image"

if sudo test -e "$entry"; then
  # --- second run ---------------------------------------------------
  sudo rm -f "$entry"
  sudo rmdir "${entry%/*}" 2>/dev/null || true
  echo "test entry removed"
  echo "== failed units"
  systemctl --failed --no-legend | grep . || echo "none"
  cat <<'EOF'

Done.  The proof is what the test entry did in the menu:
  an error such as "Error loading EFI Binary", menu back: enforcing.
  a kernel starting instead: not enforcing; check Secure Boot Preset.
(sbctl status names FQ0001 whatever the preset: it knows the board.)
EOF
  exit 0
fi

# --- first run --------------------------------------------------------
kernel=$(sudo sh -c 'ls -1 /boot/EFI/nixos/kernel-*.efi 2>/dev/null | head -n 1' || true)
[ -n "$kernel" ] || stop "no kernel file in /boot/EFI/nixos to test with."
# lanzaboote installs no Type #1 entries, so on a fresh install this
# directory does not exist; the second run removes it again if empty.
sudo mkdir -p "${entry%/*}"
printf 'title Secure Boot test (must be refused)\nefi /EFI/nixos/%s\n' \
  "${kernel##*/}" | sudo tee "$entry" > /dev/null
echo "== test entry"
sudo cat "$entry"
cat <<'EOF'

Now: reboot, pick "Secure Boot test (must be refused)" in the menu,
expect an error and the menu back, boot NixOS, and run this again.
EOF
