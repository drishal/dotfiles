{ ... }:
{
  # CLI only — systemd.enable would start the RPC daemon, which isn't wanted here.
  programs.aria2 = {
    enable = true;

    settings = {
      # Connection counts measured on this line (Vi India ~300/55 Mbps, 27 ms RTT,
      # 1 GB from sin-speed.hetzner.com): 1 conn 117 Mbps, 4-8 conns 180-224,
      # 16 conns 140-155. Past ~4 there is no gain and 16 is consistently slower.
      # 8 hedges for mirrors that throttle per-connection, where 16 would help.
      split = 8;
      max-connection-per-server = 8;
      # 1M lets aria2 re-split the tail into tiny ranges; that churn is what makes
      # split=16 lose. Measured 154 Mbps at 1M vs 220 at 8M on the same 16 conns.
      min-split-size = "4M";
      # No optimize-concurrent-downloads: it is clamped *below* max-concurrent-downloads,
      # and its N = 5 + 25*log10(Mbps) already exceeds 4 by ~40 Mbps, so it would only
      # ever lower the count on a slow link. 4 items x 8 conns = 32 sockets.
      max-concurrent-downloads = 4;

      # Abandon a dead mirror instead of retrying forever. max-tries=0 + a short
      # retry-wait spins on an expired or 404 URL and blocks everything queued behind it.
      max-tries = 10;
      retry-wait = 5;
      connect-timeout = 15;
      timeout = 30;
      # Deliberately NOT setting max-file-not-found. It counts dead HTTP web seeds
      # embedded in a .torrent and aborts the whole download group when it trips —
      # the Debian DVD torrent ships a stale cdimage URL and died at count=3 with a
      # perfectly healthy swarm. max-tries still bounds a genuinely dead plain URL.
      # Per-connection stall escape; does not affect BitTorrent.
      lowest-speed-limit = "32K";
      continue = true;

      # ext4 + 64 GB RAM.
      file-allocation = "falloc";
      disk-cache = "128M";
      no-file-allocation-limit = "64M";

      remote-time = true;
      content-disposition-default-utf8 = true;
      allow-overwrite = false;
      auto-file-renaming = true;
      # Some mirrors 403 the default aria2 UA.
      user-agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36";

      console-log-level = "warn";
      summary-interval = 10;
      download-result = "full";

      listen-port = "51413-51423";
      dht-listen-port = "51413-51423";
      enable-dht = true;
      enable-dht6 = true;
      bt-enable-lpd = true;
      enable-peer-exchange = true;
      # 100, not 200: measured swarms topped out at 58-59 peers, so a higher cap is
      # never reached. Raising it looked like a 9x win only because that run had a
      # cold DHT table; a re-test with warm DHT showed 100 and 200 within noise.
      bt-max-peers = 100;
      # Default 50K is so low aria2 never widens the peer set on a slow torrent.
      bt-request-peer-speed-limit = "50M";
      bt-load-saved-metadata = true;
      # Dead trackers stall announces for a full minute at the 60s defaults.
      bt-tracker-connect-timeout = 10;
      bt-tracker-timeout = 15;
      # Obfuscate where the peer supports it; require=false keeps the peer pool whole.
      bt-min-crypto-level = "arc4";
      bt-require-crypto = false;
      # ~32 Mbps of the 55 Mbps up, so seeding can't starve download ACKs.
      max-overall-upload-limit = "4M";
      seed-ratio = 1.0;
      seed-time = 60;
      bt-detach-seed-only = true;
      bt-save-metadata = true;
      follow-torrent = true;
    };
  };
}
