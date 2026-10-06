# memory-cpu.nix -- zram, the reclaim sysctls that go with it, and the
# CPU governor.

{
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
    priority = 100;
  };

  # Correct only because the swap device is RAM; carrying these without
  # zram would be a mistake.  swappiness above 100 prefers the
  # compressed device over dropping page cache, which is only sensible
  # when swap is faster than disk.  watermark_boost_factor 0 stops the
  # burst of reclaim after fragmentation, which with zram would compress
  # pages for nothing; watermark_scale_factor widens the reclaim gaps to
  # 1.25% of memory so kswapd starts earlier.  page-cluster 0 disables
  # swap readahead, which amortises seeks that RAM does not have.
  #
  # Nothing in nixpkgs sets any of them, so nothing collides here.
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  powerManagement.cpuFreqGovernor = "performance";
}
