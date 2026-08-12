{
  config,
  pkgs,
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
        secret_key = "be07787f1bb522a61853986d4468578701af5d536a96bba2048d6094f45dc6d2";
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
