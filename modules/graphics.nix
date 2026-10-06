# graphics.nix -- the Cezanne APU, and audio, which needs nothing.

{
  # mesa carries both radeonsi and RADV here, so there is nothing to add
  # to extraPackages: vulkan-radeon is an Arch split package and is not
  # an attribute in nixpkgs at all.
  hardware.graphics.enable = true;
  environment.sessionVariables.LIBVA_DRIVER_NAME = "radeonsi";

  # No audio configuration at all, on purpose: wireplumber selects the
  # analog sink unconfigured, and naming no card index is what makes
  # probe order stop mattering.  pipewire itself arrives through
  # services.graphical-desktop, which programs.hyprland pulls in.
}
