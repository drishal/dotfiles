// Stands in for app.asar: injects a user CSS file into Discord's pages, then starts the real app.
const fs = require("fs");
const os = require("os");
const path = require("path");
const Module = require("module");
const { app } = require("electron");

const cssFile =
  process.env.DISCORD_CSS_FILE ||
  path.join(
    process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config"),
    "discord-theme",
    "custom.css",
  );

app.on("web-contents-created", (_, wc) => {
  let key;
  let watcher;

  const apply = async () => {
    if (wc.isDestroyed() || !wc.getURL().startsWith("https://discord.com/")) return;
    try {
      const css = fs.readFileSync(cssFile, "utf8");
      if (key) await wc.removeInsertedCSS(key).catch(() => {});
      key = await wc.insertCSS(css);
    } catch (e) {
      console.error("[discord-css]", e.message);
    }
  };

  const watch = () => {
    if (watcher) return;
    try {
      watcher = fs.watch(path.dirname(cssFile), (_, name) => {
        if (name === path.basename(cssFile)) apply();
      });
      wc.once("destroyed", () => watcher.close());
    } catch {}
  };

  wc.on("dom-ready", () => {
    apply();
    if (wc.getURL().startsWith("https://discord.com/")) watch();
  });
});

const asar = path.join(path.dirname(require.main.filename), "..", "_app.asar");
const pkg = require(path.join(asar, "package.json"));
require.main.filename = path.join(asar, pkg.main);
app.setAppPath(asar);
Module._load(require.main.filename, null, true);
