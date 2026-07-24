{ ... }:
# Network performance tuning — BBR + latency optimization for Tailscale/WireGuard.
{
  boot.kernel.sysctl = {
    # Set BBR explicitly rather than relying on the kernel build default.
    # BBR paces via fq; fq_codel's AQM can drop in ways BBR doesn't expect.
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";

    # Without probing, PMTU black holes silently kill VPN-tunnelled connections.
    # 1 = probe on black-hole detection (2 = always, adds overhead on healthy paths).
    "net.ipv4.tcp_mtu_probing" = 1;

    # Keeps BBR's learned cwnd alive across idle SSH/Tailscale sessions
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # Dead-peer detection in ~110s instead of the default ~2h. Long-lived TCP only —
    # WireGuard's own UDP NAT keepalive is handled by Tailscale (~25s).
    "net.ipv4.tcp_keepalive_time" = 60;
    "net.ipv4.tcp_keepalive_intvl" = 10;
    "net.ipv4.tcp_keepalive_probes" = 5;

    # 8 MiB caps — headroom for concurrent large transfers over Tailscale
    "net.core.rmem_max" = 8388608;
    "net.core.wmem_max" = 8388608;
    "net.ipv4.tcp_rmem" = "4096 131072 8388608";  # min/default/max
    "net.ipv4.tcp_wmem" = "4096 16384 8388608";   # min/default/max

    # 1 = also initiate ECN outbound (2 = only honor it). Lets the path mark
    # instead of drop, which helps non-BBR flows; tcp_ecn_fallback covers stragglers.
    "net.ipv4.tcp_ecn" = 1;

    # Default 60s is conservative for desktop use
    "net.ipv4.tcp_fin_timeout" = 15;

    # Floor stays above 1024 so ephemeral ports can't grab registered service
    # ports that docker/libvirt/dev servers bind without SO_REUSEADDR.
    "net.ipv4.ip_local_port_range" = "10240 65535";

    # Stops stale ssthresh/cwnd biasing new connections when switching LAN ↔ Tailscale
    "net.ipv4.tcp_no_metrics_save" = 1;
  };
}
