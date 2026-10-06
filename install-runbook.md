NixOS install runbook -- amd desktop, reinstall
===============================================

Reinstalling the desktop from this repository alone.  Nothing on the
disk is kept, the pins do not move, and the files cross on the Ventoy
stick.  What the installed system is, and why, is in the README.

Step 0 happens on the laptop and step A in the firmware.  Step 1 is the
only one typed on the installer; it starts scripts/reinstall.sh, which
runs steps 2 to 10 and stops with STOP: at the first thing that is not
as expected.  The script only saves the typing; what each step does and
why is written here.  Steps 11 to 13 run on the installed system.
Nothing is erased before step 4.  "If something goes wrong" is at the
end.

0. On the laptop: put the repository on the stick

   Only committed files go, so commit first.  The first command must
   print nothing.

     git -C ~/nixos status --short
     lsblk -o NAME,SIZE,FSTYPE,LABEL

   The stick's large partition is labelled Ventoy.  It is not sda:
   sda is the laptop's own disk.  With the stick at sdb:

     sudo mkdir -p /mnt/ventoy
     sudo mount /dev/sdb1 /mnt/ventoy
     sudo mkdir -p /mnt/ventoy/scripts
     sudo rm -f /mnt/ventoy/scripts/nixos-*.tar.gz
     rev=$(git -C ~/nixos rev-parse --short HEAD)
     git -C ~/nixos archive --format=tar.gz HEAD \
       | sudo tee /mnt/ventoy/scripts/nixos-$rev.tar.gz > /dev/null
     sha256sum /mnt/ventoy/scripts/nixos-$rev.tar.gz
     sudo umount /mnt/ventoy

   The archive is named by the commit it holds, so the installer shows
   which commit it is installing.  tmp/ is not tracked and stays
   behind.

A. In the firmware setup, before booting the stick

   systemctl reboot --firmware-setup from a running NixOS, or Delete at
   the MSI logo.  Then Settings, Advanced, Windows OS Configuration,
   Secure Boot.

     - Delete all Secure Boot variables.  That puts the firmware in
       Setup Mode, where it verifies nothing, so the stick and the
       freshly installed system both boot.
     - Leave Secure Boot Enabled, Secure Boot Mode Custom, and Secure
       Boot Preset at Maximum Security.  The preset is what makes a
       failed signature actually refuse (firmware quirk FQ0001).
     - Keep the administrator password.
     - Never "Provision Factory Default Keys" or "Restore Factory Keys".

   F10 saves.  F11 at the MSI logo is the boot menu: pick the stick, in
   Ventoy ISOs/Linux, the NixOS 26.05 minimal ISO, normal mode, and the
   newer kernel entry rather than the LTS one.

   Secure Boot then comes up by itself from configuration.nix.
   nixos-install writes unsigned boot files, because there are no keys
   yet.  The first boot makes the keys and puts them on the ESP.  The
   second, still in Setup Mode, has systemd-boot enroll them after a
   warning with a countdown.  From then on the firmware enforces.
   Step 13 checks it.

1. Take the files off the stick and start the script

     sudo -i
     mkdir -p /stick
     mount -o ro /dev/mapper/sda1 /stick
     ls /stick/scripts/nixos-*.tar.gz
     mkdir -p /root/nixos
     tar -xzf /stick/scripts/nixos-*.tar.gz -C /root/nixos
     umount /stick
     bash /root/nixos/scripts/reinstall.sh

   The archive's name must carry the commit from step 0.

   Ventoy holds the partition the ISO runs from, so /dev/sda1 itself
   refuses to mount as busy.  Since Ventoy 1.1.01 the same partition is
   /dev/mapper/sda1, and lsblk shows it as a second sda1 under the
   stick.  It is mounted read-only because the running ISO lives on it.
   (ventoy.net, doc_linux_remount.html)  If it does not exist: run
   udevadm trigger and try again; if it still does not, dmsetup ls
   names the mapping and /dev/dm-N works in its place.  An older Ventoy
   needs the mapping made by hand, per the same page:

     a=sda1; echo 0 $(cat /sys/class/block/$a/size) linear /dev/$a 0 \
       | dmsetup create $a

   The script's steps follow.  It builds disko and sbctl from the
   pinned nixpkgs, the versions the installed system has, and checks
   that its copy of the pin is the one in system.nix.

2. Check the installer

   Booted in UEFI mode; bootctl reads Secure Boot disabled (setup), or
   the firmware's keys are still there and step A was not done; the
   network answers; /dev/nvme0n1 is the 931.5G Lexar that disko.nix
   names.

3. Check for option ROMs, before erasing anything

   The keys get enrolled without Microsoft's certificates, and to allow
   that the module passes allowBrickingMyMachine, which skips sbctl's
   check for option ROMs, the firmware of add-in cards.  So the script
   runs that same check here: sbctl enroll-keys --export auth, with
   throwaway keys made in the installer's RAM.  It refuses on a missing
   or unreadable TPM event log and on any option ROM in it; otherwise
   it writes three .auth files into a temporary directory and nothing to
   the firmware.  (sbctl 0.18, tpm.go and cmd/sbctl/enroll-keys.go)

   If sbctl names an OptionROM, a graphics card added since for
   instance: remove includeMicrosoftKeys and allowBrickingMyMachine from
   /root/nixos/configuration.nix, so Microsoft's certificates are
   enrolled too, and run the script again.  If it names the event log,
   nothing was checked: stop and find out why.

4. Erase, partition, encrypt, format, mount

   disko --mode destroy,format,mount on disko.nix.  You answer twice.

   disko prints a WARNING and lists the disks it will destroy.  The list
   must be exactly one line, /dev/nvme0n1; type yes.  Anything else
   aborts, and nothing is erased.  Then the LUKS passphrase, twice; if
   the two differ it asks again.  That passphrase is what you type at
   every boot.  There is no TPM and no recovery key: if it is lost, the
   data is gone.

   The script then checks the five btrfs subvolumes are mounted under
   /mnt with compress=zstd:3, and /mnt/boot as vfat with fmask and dmask
   0077, and prints the tree.

5. Generate the hardware half

   nixos-generate-config --root /mnt --no-filesystems, then the file is
   printed.  Only hardware-configuration.nix is kept.  --no-filesystems
   leaves out the mounts and the LUKS device, which come from disko.nix;
   the script stops if the file defines either, because both would then
   be defined twice and the evaluation fails.

6. Put the real configuration in place

   system.nix, configuration.nix and disko.nix into /mnt/etc/nixos, with
   modules/, home/ and scripts/ beside them.  This overwrites the
   generated configuration.nix and leaves hardware-configuration.nix
   alone.  The layout matters: configuration.nix imports
   ./hardware-configuration.nix, ./disko.nix and every file in
   modules/, and modules/users.nix imports home/.

7. Check the pins

   Five sha256 lines in system.nix: nixpkgs, home-manager, disko,
   lanzaboote, and the rust-overlay handed to lanzaboote.  fetchTarball
   verifies them during the install and stops on a mismatch.  None moves
   today.

8. Write the password files

   users.mutableUsers = false means passwd does not work and both
   accounts take their hash from a file, /etc/passwords/root and
   /etc/passwords/librefos.  If these do not exist before the first
   activation, nobody can log in, root included.

   mkpasswd asks once and never confirms, so for each account the
   script asks twice: the second answer is hashed with the salt of the
   first, and only an identical hash is accepted.  A mismatch asks
   again.

9. Parse check, before spending the download

   nix-instantiate --parse on every .nix file.

10. Install

     nixos-install --root /mnt --file /mnt/etc/nixos/system.nix \
       --no-root-passwd --no-channel-copy

   --no-root-passwd because the prompt it would otherwise show writes a
   hash that the first activation immediately overwrites from step 8.
   --no-channel-copy because there is to be no channel on the machine.

   This downloads the whole unstable closure, and builds lzbt and the
   lanzaboote stub from source, since they are not on the binary cache.
   It is the long part.  Near the end expect

     No keys provided. Installing unsigned artifacts.
     Successfully installed Lanzaboote.

   The first line is correct, not an error: there are no keys until the
   first boot makes them.  The output is kept in /root/nixos-install.log
   and copied to /var/log/nixos-install.log on the installed system.

   If a channel was seeded all the same, the script stops; remove it:

     rm -f /mnt/root/.nix-defexpr/channels
     rmdir /mnt/root/.nix-defexpr
     rm -f /mnt/nix/var/nix/profiles/per-user/root/channels \
           /mnt/nix/var/nix/profiles/per-user/root/channels-*-link

11. Reboot

     reboot

   Pull the stick once the screen goes dark.  The firmware finds the
   entry lanzaboote installed.  The LUKS passphrase is asked for.  The
   firmware is still in Setup Mode, so the unsigned files boot.  Right
   after the entry is picked, the lanzaboote stub warns that Secure
   Boot is not active.  Until the keys are enrolled, that is expected.

12. First session

   Log in on tty1 as librefos.  The session starts by itself: the login
   shell runs

     uwsm start -e -D Hyprland hyprland.desktop

   behind uwsm check may-start, so only a local login on tty1 does it.
   Leaving Hyprland returns to the login prompt.  tty2 always stays a
   plain shell, and it is the way back in if the session does not come
   up.  The reasoning is in the README, under The session.

   home-manager's system service, home-manager-librefos, has already
   linked ~/.config/hypr/hyprland.lua and hypridle.conf into place.  If
   the session comes up with gaps, animation and Hyprland's wallpaper,
   and dead keys do not work, those links are missing.  From tty2:

     systemctl status home-manager-librefos --no-pager
     ls -l ~/.config/hypr/

   systemctl get-default prints default.target on this system, not
   graphical.target.  That is not a failure; ask
   systemctl is-active graphical.target instead.

13. Secure Boot: the first, second and third boot

   Still on the first boot, in foot (SUPER+Q) or on tty2:

     systemctl status generate-sb-keys prepare-sb-auto-enroll --no-pager
     sudo ls /boot/loader/keys/auto
     sudo sbctl verify

   Both services active (exited); PK.auth, KEK.auth and db.auth on the
   ESP; BOOTX64.EFI, systemd-bootx64.efi and generation 1's image
   signed, and the kernel not signed, which is expected, because the
   signed image carries its hash.

   Reboot.  systemd-boot shows a warning with a countdown before it
   enrolls the keys.  Press nothing and let it run out.  Unlock, log in,
   and:

     bash /etc/nixos/scripts/secureboot-check.sh

   It needs bootctl to report enabled (user).  If it stops with "not
   enforcing yet", reboot once more and run it again: this firmware
   shows a new mode only from the boot after the keys were written.
   If it still stops,
   check the firmware: Secure Boot Enabled, Mode Custom, Preset Maximum
   Security.

   Once enforcing, the script checks every boot file is signed and adds
   a test entry for the unsigned kernel.  Reboot and pick "Secure Boot
   test (must be refused)": it must fail with an error such as "Error
   loading EFI Binary".  The menu may come back afterwards, or the
   firmware may ask for its administrator password and open its setup
   instead; leave that without saving.  Either way the refusal is the
   result.  Boot NixOS and run the script again; it removes the entry
   and reports.

If something goes wrong
-----------------------
  A STOP           the script names the step and the command to carry
                   on once the cause is fixed:
                     bash /root/nixos/scripts/reinstall.sh --from N
                   Before step 4 nothing on the disk has changed.
                   --from 4 or lower erases again; --from 5 or higher
                   keeps the disk.

  The installer    was restarted in the middle.  Step 1 again, then
                   --from the step that did not finish.  From step 5 on,
                   disko mounts the existing disk and asks for the LUKS
                   passphrase instead of erasing.

  After step 11    the system does not come up, or a password does not
                   work.  Boot the stick, step 1 without its last line,
                   then fix the cause, a password with --from 8 for
                   instance, which installs again at the end.
                   nixos-enter --root /mnt gives a shell inside the
                   installed system once /mnt is mounted.

  Secure Boot      refuses to boot NixOS.  Secure Boot decides what the
                   firmware runs and writes nothing to the hardware.
                   In the firmware setup, delete all Secure Boot
                   variables again: back in Setup Mode, everything
                   boots, as on the first boot.  The picture comes from
                   the APU through the board's own outputs, so the setup
                   menu stays visible.

Changing the installed system
-----------------------------
  A new commit reaches the running desktop the way the reinstall's
  files do: step 0 puts its archive on the stick.  On the desktop the
  stick is an ordinary disk, so its partition mounts directly; check
  with lsblk that it is sda1 before mounting.

    sudo -i
    mount --mkdir -o ro /dev/sda1 /mnt
    rm -rf /root/nixos && mkdir /root/nixos
    tar -xzf /mnt/scripts/nixos-*.tar.gz -C /root/nixos
    umount /mnt
    bash /root/nixos/scripts/apply.sh

  An installed NixOS has no /mnt: only the installer image creates one.
  --mkdir makes it when it is missing, so nothing has to be declared for
  it.  /mnt is still where the NixOS manual itself mounts things by
  hand.  (nixos/doc/manual/configuration/nfs-file-systems.section.md)

  apply.sh parses every file, evaluates the new configuration in a
  staging copy, and lists what it would download and what it would
  compile, changing nothing until it is told yes.  Then it saves the
  old /etc/nixos to /root/etc-nixos.before-apply, puts the repository's
  files in its place and runs nixos-rebuild switch.  A wrong generation
  is still one boot menu entry away.

What comes after
----------------
  Moving the pins, which is a rebuild on the running system, not part of
  the install.  The open items are in the README, under Open.
  Every Secure Boot key is new after a reinstall, by design: no copy of
  /var/lib/sbctl is kept.
