{
  config,
  inputs,
  pkgs,
  ...
}:
{
  programs.fastfetch = {
    enable = true;
    settings = {

      schema = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
      logo = {
        type = "small";
      };

      display = {
        key.width = 4;
        separator = " ";
        size.binaryPrefix = "si";
      };

      modules = [
        {
          format = "{3}";
          key = " ";
          keyColor = "green";
          type = "os";
        }

        {
          key = " ";
          keyColor = "yellow";
          type = "kernel";
        }

        {
          key = " ";
          keyColor = "blue";
          type = "uptime";
        }

        {
          key = "󰏖 ";
          keyColor = "magenta";
          type = "packages";
        }

        "break"

        {
          format = "{1} ({5})";
          key = " ";
          keyColor = "green";
          type = "cpu";
        }

        {
          driverSpecific = true;
          format = "{2}";
          #hideType = "integrated";
          key = " ";
          keyColor = "yellow";
          type = "gpu";
        }

        {
          format = "{/1}{-}{/}{/2}{-}{/}{} / {}";
          key = " ";
          keyColor = "blue";
          type = "memory";
        }

        {
          key = "󰌢 ";
          type = "host";
          keyColor = "red";
        }

        "break"

        {
          compactType = "scaled";
          key = "󰍹 ";
          keyColor = "cyan";
          type = "display";
        }

        {
          format = "{2}";
          key = " ";
          keyColor = "green";
          type = "wm";
        }

        {
          format = "{3}";
          key = " ";
          keyColor = "yellow";
          type = "terminal";
        }

        {
          key = " ";
          keyColor = "blue";
          type = "shell";
        }

        "break"

        {
          key = " ";
          symbol = "circle";
          type = "colors";
        }
      ];

    };
  };
}
