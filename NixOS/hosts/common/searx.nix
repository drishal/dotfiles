{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  services.searx = {
    enable = true;
    package = pkgs.searxng;
    redisCreateLocally = true;

    settings = {
      use_default_settings = true;

      server = {
        port = 48431;
        bind_address = "0.0.0.0";
        # Read from ~/.private-stuff/searx-secret.txt (local-only git repo).
        # Still lands in /nix/store via readFile — migrate to sops-nix eventually.
        secret_key = builtins.readFile "${inputs.private-stuff}/searx-secret.txt";
        # Redis is enabled (redisCreateLocally) for engine caching, but the
        # SearXNG request rate-limiter is off — we're behind Tailscale and
        # only Argus/Hermes call this locally.
        limiter = false;
        image_proxy = true;
        method = "GET";
      };

      search = {
        safe_search = 0;
        autocomplete = "duckduckgo";
        formats = [
          "html"
          "json"
        ];
      };

      ui = {
        static_use_hash = true;
        default_theme = "simple";
        theme_args.simple_style = "auto";
      };

      outgoing = {
        request_timeout = 5.0;
        max_request_timeout = 15.0;
        pool_connections = 100;
        pool_maxsize = 15;
        enable_http2 = true;
      };

      enabled_plugins = [
        "Tracker URL remover"
      ];

    };
  };
}
