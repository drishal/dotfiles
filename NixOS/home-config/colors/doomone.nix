{ config, inputs, pkgs, lib, ... }:
{
  colorScheme = {
    name = "doomone";
    palette = {
      base00 = "282C34";
      base01 = "21242B";
      base02 = "3F444A";
      base03 = "5B6268"; #brightblack
      base04 = "BBC2CF";
      base05 = "BBC2CF"; #white
      base06 = "BBC2CF";
      base07 = "BBC2CF";
      base08 = "FF6C6B"; #brightred
      base09 = "DA8548"; #
      base0A = "ECBE7B"; #yellow
      base0B = "98BE65"; #green
      base0C = "46D9FF"; #cyan 
      base0D = "51AFEF"; #blue
      base0E = "C678DD"; #magenta
      base0F = "A9A1E1";
    };
  };

  # colorScheme = {
  # name = "palenight"; 
  #   colors = {
  #     base00 = "292D3E";
  #     base01 = "676E95";
  #     base02 = "3F444A";
  #     base03 = "5B6268"; #brightblack
  #     base04 = "BBC2CF";
  #     base05 = "BBC2CF"; #white
  #     base06 = "BBC2CF";
  #     base07 = "BBC2CF";
  #     base08 = "FF5370"; #brightred
  #     base09 = "DA8548";
  #     base0A = "F78C6C"; #orange
  #     base0B = "C3E88D"; #green
  #     base0C = "89DDFF"; #cyan
  #     base0D = "82AAFF"; #blue
  #     base0E = "C792EA"; #magenta
  #     base0F = "BB80B3";
  #   };
  # };

  # ./modules/myModule.nix

}
