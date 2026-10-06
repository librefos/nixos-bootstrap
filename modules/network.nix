# network.nix -- the machine's name, wired DHCP, DNS, the firewall, and
# where and in which language it is.

{
  networking.hostName = "amd";

  # No wireless hardware, so NetworkManager buys nothing.  The trap:
  # setting systemd.network.enable while useNetworkd is false lets
  # networkd and dhcpcd fight over the same interface.
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.networks."20-wired" = {
    matchConfig.Name = "enp34s0";
    networkConfig.DHCP = "yes";
    linkConfig.RequiredForOnline = "routable";
  };

  services.resolved.enable = true;

  # The firewall is already on and already denies incoming; this only
  # selects the nftables backend.
  networking.nftables.enable = true;

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
}
