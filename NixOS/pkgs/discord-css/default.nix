{
  lib,
  discord,
  commandLineArgs ? "",
}:

# Stock discord plus a CSS injector in place of app.asar (same stub layout as nixpkgs' withVencord).
# It reads $XDG_CONFIG_HOME/discord-theme/custom.css and reloads on change; no webpack patching.
let
  # commandLineArgs are baked into the unwrapped build, so apply them before swapping it out.
  base = discord.override { inherit commandLineArgs; };
  unwrapped = base.unwrappedDiscord.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      res=$out/opt/Discord/resources
      mv $res/app.asar $res/_app.asar
      mkdir $res/app.asar
      echo '{"name":"discord","main":"index.js"}' > $res/app.asar/package.json
      cp ${./injector.js} $res/app.asar/index.js
    '';
  });
in
base.override { unwrappedDiscord = unwrapped; }
