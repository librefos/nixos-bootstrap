#!/usr/bin/env bash
# reinstall.sh -- steps 2 to 10 of install-runbook.md, in one run.
#
# Runs as root in the NixOS 26.05 minimal installer, from the copy of
# this repository that step 1 of the runbook unpacks.  What each step
# does, and why, is in the runbook; this only saves the typing.
#
#   bash /root/nixos/scripts/reinstall.sh            steps 2 to 10
#   bash /root/nixos/scripts/reinstall.sh --from N   from step N on
#
# It stops with STOP: at the first thing that is not as expected, and
# says how to continue.  Nothing is erased before step 4, and step 4
# erases only after disko's own question is answered with yes.  Started
# from step 5 or later it keeps the disk: if /mnt is not mounted, disko
# mounts it and asks for the LUKS passphrase.  It never reboots.
set -euo pipefail
shopt -s nocasematch

repo=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)

# The nixpkgs system.nix pins.  disko and sbctl are taken from it, so
# they are the versions the installed system has.  Compared with
# system.nix below, so the two cannot drift apart.
pin_url=https://github.com/NixOS/nixpkgs/archive/494ce7fd23ff6a5dff39e1fb11e9b6f2ac74bf25.tar.gz
pin_sha=1z191lhpx4iy9igcv54qg8aaxdsn4szdldg9l6y2hs3k4w3hnb9n

from=2
current=0

stop() {
  echo >&2
  echo "STOP at step $current: $*" >&2
  echo "Once it is fixed: bash $repo/scripts/reinstall.sh --from $current" >&2
  exit 1
}
trap 'echo "STOP at step $current: a command failed, line $LINENO.  Its output is above." >&2' ERR

step() {
  current=$1
  echo
  echo "== step $1: $2"
}

case "${1-}" in
  "") ;;
  --from)
    from=${2-}
    [[ $from =~ ^([2-9]|10)$ ]] || { echo "--from takes a step number, 2 to 10." >&2; exit 1; }
    ;;
  *) echo "usage: reinstall.sh [--from N]" >&2; exit 1 ;;
esac

[ "$(id -u)" = 0 ] || { echo "Run it as root: sudo -i first." >&2; exit 1; }

for f in system.nix configuration.nix disko.nix modules/users.nix \
         home/default.nix scripts/secureboot-check.sh; do
  [ -f "$repo/$f" ] || { echo "Missing $repo/$f" >&2; exit 1; }
done
if ! grep -qF "$pin_url" "$repo/system.nix" || ! grep -qF "$pin_sha" "$repo/system.nix"; then
  echo "The nixpkgs pin in this script is not the one in system.nix." >&2
  exit 1
fi

# nixos-install, in step 10, gets the environment the first install had.
had_nix_path=${NIX_PATH+x}
installer_nix_path=${NIX_PATH-}
# disko evaluates <nixpkgs>, so it has to resolve to the pin.
export NIX_PATH="nixpkgs=$pin_url"

# A package from the pinned nixpkgs, fetched from the binary cache.
tool() {
  nix-build '<nixpkgs>' -A "$1" --no-out-link
}

# Output is captured before it is matched, never piped into grep -q:
# with pipefail an early exit can hide a match.
check_mounts() {
  local pair target subvol opts re
  for pair in /mnt:@ /mnt/home:@home /mnt/home/.snapshots:@snapshots \
              /mnt/nix:@nix /mnt/var/log:@log; do
    target=${pair%%:*}
    subvol=${pair#*:}
    opts=$(findmnt -n -o FSTYPE,OPTIONS "$target" || true)
    re="^btrfs[[:space:]].*compress=zstd:3.*subvol=/${subvol}(,|\$)"
    [[ $opts =~ $re ]] || stop "$target is not btrfs from $subvol with the disko.nix options."
  done
  opts=$(findmnt -n -o FSTYPE,OPTIONS /mnt/boot || true)
  [[ $opts =~ ^vfat[[:space:]].*fmask=0077.*dmask=0077 ]] \
    || stop "/mnt/boot is not the ESP with fmask and dmask 0077."
  findmnt -R /mnt -o TARGET,SOURCE,FSTYPE
}

# --- step 2 -----------------------------------------------------------
if [ "$from" -le 2 ]; then
  step 2 "check the installer"
  [ -d /sys/firmware/efi/efivars ] || stop "not booted in UEFI mode."
  sb=$(bootctl status 2>/dev/null | grep 'Secure Boot:' || true)
  echo "firmware: ${sb#"${sb%%[![:space:]]*}"}"
  [[ $sb == *"disabled (setup)"* ]] \
    || stop "the firmware is not in Setup Mode.  Delete all Secure Boot variables in the firmware setup, runbook step A."
  ping -c 2 -W 5 cache.nixos.org > /dev/null || stop "no network: cache.nixos.org does not answer."
  echo "network: cache.nixos.org answers"
  disk=$(lsblk -dn -o SIZE,MODEL /dev/nvme0n1 2>/dev/null || true)
  echo "nvme0n1: $disk"
  [[ $disk == *931.5G*lexar* ]] || stop "/dev/nvme0n1 is not the 931.5G Lexar that disko.nix is written for."
fi

# --- step 3 -----------------------------------------------------------
if [ "$from" -le 3 ]; then
  step 3 "option ROMs, through sbctl's own check"
  sbctl=$(tool sbctl) || stop "could not fetch sbctl from the pinned nixpkgs."
  sbctl=$sbctl/bin/sbctl
  work=$(mktemp -d)
  # Throwaway keys in the installer's RAM, gone at reboot and never
  # enrolled.  enroll-keys refuses on a missing or unreadable event log
  # and on any EV_EFI_BOOT_SERVICES_DRIVER event in it; with --export it
  # then writes three .auth files here and returns before any code that
  # writes to the firmware.  (sbctl 0.18, tpm.go CheckEventlogOprom and
  # cmd/sbctl/enroll-keys.go KeySync)
  [ -d /var/lib/sbctl/keys ] || "$sbctl" create-keys > /dev/null \
    || stop "sbctl create-keys failed."
  if ! (cd "$work" && "$sbctl" enroll-keys --export auth); then
    stop "sbctl refused, and its reason is above.  Do not go on: an OptionROM means the configuration has to change first, and an event log error means nothing was checked."
  fi
  for f in PK.auth KEK.auth db.auth; do
    [ -s "$work/$f" ] || stop "sbctl did not export $f."
  done
  echo "the event log was read and holds no option ROM"
fi

# --- step 4 -----------------------------------------------------------
if [ "$from" -le 4 ]; then
  step 4 "erase, partition, encrypt, format, mount"
  disko=$(tool disko) || stop "could not fetch disko from the pinned nixpkgs."
  cat <<'EOF'
disko lists the disks it will destroy.  The list must be exactly one
line, /dev/nvme0n1; then type yes.  Then the LUKS passphrase, twice.  It
is typed at every boot from now on, and there is no other way in.

EOF
  "$disko/bin/disko" --mode destroy,format,mount "$repo/disko.nix" \
    || stop "disko did not finish."
elif ! findmnt -n /mnt > /dev/null; then
  current=$from
  echo
  echo "== mounting the installed disk, without erasing it"
  disko=$(tool disko) || stop "could not fetch disko from the pinned nixpkgs."
  "$disko/bin/disko" --mode mount "$repo/disko.nix" || stop "disko could not mount the disk."
fi
check_mounts

# --- step 5 -----------------------------------------------------------
if [ "$from" -le 5 ]; then
  step 5 "generate the hardware half"
  nixos-generate-config --root /mnt --no-filesystems
  hw=/mnt/etc/nixos/hardware-configuration.nix
  cat "$hw"
  n=$(grep -v '^[[:space:]]*#' "$hw" | grep -cE 'fileSystems|luks' || true)
  [ "$n" = 0 ] || stop "hardware-configuration.nix defines mounts or LUKS; disko.nix owns those."
fi

# --- step 6 -----------------------------------------------------------
if [ "$from" -le 6 ]; then
  step 6 "put the configuration in place"
  [ -f /mnt/etc/nixos/hardware-configuration.nix ] || stop "no hardware-configuration.nix: run from step 5."
  rm -rf /mnt/etc/nixos/modules /mnt/etc/nixos/home /mnt/etc/nixos/scripts
  cp -r "$repo/system.nix" "$repo/configuration.nix" "$repo/disko.nix" \
        "$repo/modules" "$repo/home" "$repo/scripts" /mnt/etc/nixos/
  ls /mnt/etc/nixos
fi

# --- step 7 -----------------------------------------------------------
if [ "$from" -le 7 ]; then
  step 7 "check the pins"
  grep 'sha256 = "' /mnt/etc/nixos/system.nix || true
  n=$(grep -c 'sha256 = "' /mnt/etc/nixos/system.nix || true)
  [ "$n" = 5 ] || stop "system.nix has $n pinned hashes, not 5: nixpkgs, home-manager, disko, lanzaboote and rust-overlay."
fi

# --- step 8 -----------------------------------------------------------
if [ "$from" -le 8 ]; then
  step 8 "the password files"
  echo "mkpasswd asks once and never confirms, so each password is typed twice"
  echo "and the second is hashed with the salt of the first."
  install -d -m 700 /mnt/etc/passwords
  for u in root librefos; do
    file=/mnt/etc/passwords/$u
    while :; do
      echo
      echo "Password for $u:"
      (umask 077; mkpasswd -m sha-512 > "$file")
      echo "The same password for $u again:"
      salt=$(cut -d'$' -f3 "$file")
      if [[ $(head -c 3 "$file") == "\$6\$" ]] \
         && mkpasswd -m sha-512 -S "$salt" | cmp -s - "$file"; then
        echo "$u: same"
        break
      fi
      echo "$u: the two did not match.  Once more."
    done
  done
  chmod 600 /mnt/etc/passwords/root /mnt/etc/passwords/librefos
fi

# --- step 9 -----------------------------------------------------------
if [ "$from" -le 9 ]; then
  step 9 "parse check"
  while IFS= read -r f; do
    nix-instantiate --parse "$f" > /dev/null || stop "${f#/mnt/etc/nixos/} does not parse."
    echo "${f#/mnt/etc/nixos/} parses"
  done < <(find /mnt/etc/nixos -name '*.nix' | sort)
fi

# --- step 10 ----------------------------------------------------------
step 10 "install"
for u in root librefos; do
  [[ $(head -c 3 "/mnt/etc/passwords/$u" 2>/dev/null) == "\$6\$" ]] \
    || stop "/mnt/etc/passwords/$u is missing or not a hash: run from step 8."
done
if [ -n "$had_nix_path" ]; then
  export NIX_PATH="$installer_nix_path"
else
  unset NIX_PATH
fi
cat <<'EOF'
The long part: the whole closure downloads, and lzbt and its stub
compile.  "No keys provided. Installing unsigned artifacts." near the
end is expected: there are no keys until the first boot makes them.

EOF
log=/root/nixos-install.log
if ! nixos-install --root /mnt --file /mnt/etc/nixos/system.nix \
       --no-root-passwd --no-channel-copy 2>&1 | tee "$log"; then
  stop "nixos-install failed, and its output is in $log."
fi
out=$(cat "$log")
[[ $out == *"installation finished!"* ]] || stop "nixos-install did not report success; see $log."
[ ! -e /mnt/root/.nix-defexpr/channels ] || stop "a channel was seeded into /mnt/root; the runbook, step 10, removes it."
cp "$log" /mnt/var/log/nixos-install.log

cat <<'EOF'

Installed.  Next is runbook step 11: reboot, pull the stick once the
screen goes dark, unlock with the LUKS passphrase, and log in on tty1
as librefos.
EOF
