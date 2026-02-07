{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # Import the secrets from your private repository
  secrets = import "${inputs.private-stuff}/ai-secrets.nix";
in
{
  programs.nixvim = {
    plugins.codecompanion = {
      enable = true;
      settings = {
        adapters = {
          http = {
            localai = {
              __raw = ''
                function()
                  return require("codecompanion.adapters").extend("openai_compatible", {
                    env = {
                      url = "${secrets.url}",
                      api_key = "${secrets.api_key}",
                    },
                    schema = {
                      model = {
                        default = "better-coder",
                      },
                      max_tokens = {
                        default = 128000,
                      },
                    },
                  })
                end
              '';
            };
          };
        };
      };
      strategies = {
        chat = {
          adapter = "localai";
        };
        inline = {
          adapter = "localai";
        };
        agent = {
          adapter = "localai";
        };
      };
      opts = {
        log_level = "DEBUG";
        send_code = true;
        use_default_actions = true;
        use_default_prompts = true;
      };
    };
  };
}
