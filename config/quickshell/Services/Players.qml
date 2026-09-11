pragma ComponentBehavior: Bound
pragma Singleton

// Mpris player selection + cover-art fallback (caelestia's Players.qml,
// condensed). `active` prefers whatever is playing, then mpv, then the first
// player. `artUrl(player)` falls back to the YouTube thumbnail when the
// player reports no trackArtUrl but plays from a watch URL — mpv + yt-dlp
// never set art, and this is what makes the lock/dashboard cards show it.

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var active: {
        for (const p of root.players)
            if (p.playbackState === MprisPlaybackState.Playing)
                return p;
        // Nothing playing: prefer mpv (the usual source), else first.
        for (const p of root.players)
            if (/mpv/i.test(p.identity || ""))
                return p;
        return root.players.length > 0 ? root.players[0] : null;
    }

    // YouTube thumbnail fallback — 5 lines that turn mpv-mpris + yt-dlp from
    // "no art" into real cover art.
    function artUrl(player) {
        if (!player)
            return "";
        if (player.trackArtUrl)
            return player.trackArtUrl;
        const url = player.metadata && player.metadata["xesam:url"];
        if (typeof url === "string" && url.startsWith("https://www.youtube.com/watch")) {
            const id = url.match(/[?&]v=([\w-]{11})/);
            return id ? `https://img.youtube.com/vi/${id[1]}/hqdefault.jpg` : "";
        }
        return "";
    }
}
