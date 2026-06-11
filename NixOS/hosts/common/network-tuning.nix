{ ... }:
# Network performance tuning — BBR + latency optimization for Tailscale/WireGuard.
# Imported by hosts/<host>/default.nix alongside ../common.
{
  boot.kernel.sysctl = {
    # --- Congestion control + qdisc (make BBR explicit) ---
    # XanMod defaults to BBR, but don't rely on the kernel build default — set it
    # here so the tuning below is correct regardless of kernel. BBR is designed to
    # pace packets via `fq`; the stock NixOS default is `fq_codel`, whose CoDel AQM
    # can drop/mark packets in ways BBR's model doesn't expect. On a desktop the
    # gigabit NIC is rarely the bottleneck, so pacing (fq) beats local AQM (fq_codel).
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";

    # --- MTU probing (critical for Tailscale/WireGuard) ---
    # Default is 0 (disabled). Without probing, PMTU black holes silently kill
    # connections over VPN tunnels where path MTU < interface MTU.
    # Mode 1 = probe on ICMP black-hole detection; mode 2 = always PLMTUD.
    # Mode 1 is safest (won't add overhead on healthy paths).
    "net.ipv4.tcp_mtu_probing" = 1;

    # --- Don't restart slow-start after idle periods ---
    # Keeps BBR's learned cwnd alive across idle SSH/Tailscale sessions.
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # --- Faster TCP keepalive (dead-session detection) ---
    # Affects long-lived TCP sockets only (e.g. SSH over Tailscale) — NOT WireGuard's
    # own UDP NAT keepalive, which Tailscale handles separately (~25s). Default
    # 7200s/75s/9 means ~2h to notice a dead peer; these bring it to ~110s.
    "net.ipv4.tcp_keepalive_time" = 60;
    "net.ipv4.tcp_keepalive_intvl" = 10;
    "net.ipv4.tcp_keepalive_probes" = 5;

    # --- Socket buffer sizes (already good, minor bump for high-BDP) ---
    # rmem_max and wmem_max cap per-socket buffers. BBR at 50ms RTT needs ~625KB
    # per connection at 100Mbps, so 4MB is adequate. Bumping to 8MB gives headroom
    # for multiple concurrent large transfers (e.g., rsync over Tailscale).
    "net.core.rmem_max" = 8388608;   # 8 MiB (was 4 MiB)
    "net.core.wmem_max" = 8388608;   # 8 MiB (was 4 MiB)
    "net.ipv4.tcp_rmem" = "4096 131072 8388608";  # min/default/max, max 8 MiB
    "net.ipv4.tcp_wmem" = "4096 16384 8388608";   # min/default/max, max 8 MiB

    # --- ECN: actively negotiate on outgoing + honor incoming (mode 1) ---
    # Mode 2 (default) only honors ECN when a peer requests it; mode 1 also initiates
    # it on our outbound connections. BBRv1 itself ignores ECN, but mode 1 lets the
    # path mark instead of drop, which helps non-BBR flows and fq's own AQM. Safe in
    # 2025+ — middleboxes that mishandle ECN are rare, and tcp_ecn_fallback covers the
    # stragglers by retrying without ECN.
    "net.ipv4.tcp_ecn" = 1;

    # --- Faster FIN_WAIT2 recycling ---
    # Default 60s is conservative. 15s is safe for desktop use and frees sockets faster.
    "net.ipv4.tcp_fin_timeout" = 15;

    # --- Widen local port range for high concurrent connections ---
    # Default 32768-60999 gives ~28K ports. Floor stays at 10240 (not 1024) so
    # ephemeral outbound connections can't grab registered service ports that
    # docker/libvirt/dev servers bind without SO_REUSEADDR. ~55K ports is plenty.
    "net.ipv4.ip_local_port_range" = "10240 65535";

    # --- Don't cache per-destination TCP metrics ---
    # Prevents stale ssthresh/cwnd from past connections from biasing new ones,
    # which matters when switching between LAN and Tailscale peers.
    "net.ipv4.tcp_no_metrics_save" = 1;
  };
}