import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding, createComputed, With, type Accessor } from "ags"
import AstalWp from "gi://AstalWp"
import AstalBluetooth from "gi://AstalBluetooth"
import AstalNotifd from "gi://AstalNotifd"
import AstalMpris from "gi://AstalMpris"
import GLib from "gi://GLib"

import { createBrightness } from "../lib/brightness"
import { airplaneOn, toggleAirplane } from "../lib/radios"
import { networkState } from "../lib/network"
import { sh, togglePopup } from "../lib/windows"

// ── reusable quick-toggle tile ─────────────────────────────────────────────
function Tile(props: {
  icon: Accessor<string> | string
  title: string
  subtitle: Accessor<string> | string
  active: Accessor<boolean>
  chevron?: boolean
  onClicked: () => void
}) {
  return (
    <button
      class={props.active((a) => (a ? "tile tile-on" : "tile"))}
      hexpand
      onClicked={props.onClicked}
    >
      <box valign={Gtk.Align.CENTER}>
        <label class="tile-glyph" valign={Gtk.Align.CENTER} label={props.icon} />
        <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
          <label class="tile-title" halign={Gtk.Align.START} maxWidthChars={12} ellipsize={3} label={props.title} />
          <label class="tile-sub" halign={Gtk.Align.START} maxWidthChars={14} ellipsize={3} label={props.subtitle} />
        </box>
        {props.chevron && <label class="tile-chev" valign={Gtk.Align.CENTER} label="󰅂" />}
      </box>
    </button>
  )
}

// ── reusable slider row ────────────────────────────────────────────────────
function SliderRow(props: {
  icon: Accessor<string> | string
  extraClass?: string
  value: Accessor<number>
  onChange: (v: number) => void
  knobTip?: string
  onKnob?: () => void
}) {
  const cls = props.extraClass ?? ""
  return (
    <box class="sliderrow" valign={Gtk.Align.CENTER}>
      <button
        class={`slider-knob ${cls}`}
        tooltipText={props.knobTip ?? ""}
        onClicked={() => props.onKnob?.()}
      >
        <label label={props.icon} />
      </button>
      <slider
        class={`slider ${cls}`}
        hexpand
        valign={Gtk.Align.CENTER}
        value={props.value}
        onChangeValue={({ value }) => props.onChange(value)}
      />
    </box>
  )
}

// ── tiles ───────────────────────────────────────────────────────────────────
function Tiles() {
  const bt = AstalBluetooth.get_default()
  const notifd = AstalNotifd.get_default()
  const wp = AstalWp.get_default()
  const speaker = wp?.defaultSpeaker
  const mic = wp?.defaultMicrophone

  const netState = networkState()

  const btPowered = createBinding(bt, "isPowered")
  const btLabel = createComputed(
    [btPowered, createBinding(bt, "devices")],
    (p, ds) => (p ? ds.find((d) => d.connected)?.name || "On" : "Off"),
  )

  const dnd = createBinding(notifd, "dontDisturb")
  const micMute = mic ? createBinding(mic, "mute") : createComputed([], () => true)
  const spkMute = speaker ? createBinding(speaker, "mute") : createComputed([], () => true)
  const spkVol = speaker ? createBinding(speaker, "volume") : createComputed([], () => 0)

  return (
    <box class="tilegrid" orientation={Gtk.Orientation.VERTICAL}>
      <box class="tilerow" homogeneous spacing={10}>
        <Tile
          icon={netState.icon}
          title="Network"
          chevron
          subtitle={netState.label}
          active={netState.active}
          onClicked={() => sh("nm-connection-editor")}
        />
        <Tile
          icon="󰂯"
          title="Bluetooth"
          subtitle={btLabel}
          active={btPowered}
          onClicked={() => {
            const a = bt.adapter
            if (a) a.powered = !a.powered
          }}
        />
        <Tile
          icon="󰀝"
          title="Airplane"
          subtitle={airplaneOn((a) => (a ? "On" : "Off"))}
          active={airplaneOn}
          onClicked={() => toggleAirplane(airplaneOn.get())}
        />
      </box>
      <box class="tilerow" homogeneous spacing={10}>
        <Tile
          icon={micMute((m) => (m ? "󰍭" : "󰍬"))}
          title="Microphone"
          subtitle={micMute((m) => (m ? "Muted" : "Active"))}
          active={micMute((m) => !m)}
          onClicked={() => mic && (mic.mute = !mic.mute)}
        />
        <Tile
          icon="󰂛"
          title="Do Not Disturb"
          subtitle={dnd((d) => (d ? "On" : "Off"))}
          active={dnd}
          onClicked={() => (notifd.dontDisturb = !notifd.dontDisturb)}
        />
        <Tile
          icon={spkMute((m) => (m ? "󰖁" : "󰕾"))}
          title="Volume"
          subtitle={spkVol((v) => `${Math.round(v * 100)}%`)}
          active={spkMute((m) => !m)}
          onClicked={() => speaker && (speaker.mute = !speaker.mute)}
        />
      </box>
    </box>
  )
}

// ── sliders ───────────────────────────────────────────────────────────────
function Sliders() {
  const wp = AstalWp.get_default()
  const speaker = wp?.defaultSpeaker
  const bri = createBrightness()

  return (
    <box class="sliders" orientation={Gtk.Orientation.VERTICAL}>
      {speaker && (
        <SliderRow
          extraClass="vol"
          icon={createBinding(speaker, "mute")((m) => (m ? "󰖁" : "󰕾"))}
          value={createBinding(speaker, "volume")}
          onChange={(v) => speaker.set_volume(v)}
          knobTip="Mute"
          onKnob={() => (speaker.mute = !speaker.mute)}
        />
      )}
      {bri.available && (
        <SliderRow extraClass="bri" icon="󰃢" value={bri.value} onChange={(v) => bri.set(v)} />
      )}
    </box>
  )
}

// mpv-mpris exposes embedded cover art as a `data:image/...;base64,` URI, which
// AstalMpris.coverArt can't cache (no path → copy_async fails) so the box ends
// up blank. Decode such URIs to a temp file ourselves; defer to coverArt for
// players that already expose a normal file://‌ / http url (browsers, Spotify).
function coverPath(p: AstalMpris.Player): Accessor<string> {
  const fileUri = (path: string) => (path.includes("://") ? path : `file://${path}`)
  return createComputed(
    [createBinding(p, "coverArt"), createBinding(p, "artUrl")],
    (cover, url) => {
      if (cover) return fileUri(cover)
      if (!url?.startsWith("data:")) return ""
      const comma = url.indexOf(",")
      if (comma === -1) return ""
      const path = `/tmp/ags-cover-${GLib.compute_checksum_for_string(GLib.ChecksumType.SHA1, url, -1)}`
      if (!GLib.file_test(path, GLib.FileTest.EXISTS))
        GLib.file_set_contents(path, GLib.base64_decode(url.slice(comma + 1)))
      return fileUri(path)
    },
  )
}

// ── media player (mpris) ────────────────────────────────────────────────────
function Player() {
  const mpris = AstalMpris.get_default()
  const players = createBinding(mpris, "players")
  const player = players((ps) => ps[0] ?? null)

  // Wrap the dynamic <With> in an always-present box so the player keeps its
  // slot above the date chip (an empty <With> otherwise gets appended last when
  // a player appears, dropping it below the chip with no gap).
  return (
    <box orientation={Gtk.Orientation.VERTICAL}>
    <With value={player}>
      {(p: AstalMpris.Player | null) =>
        p && (
          <box
            class={createBinding(p, "playbackStatus")((s) =>
              s === AstalMpris.PlaybackStatus.PLAYING ? "card player playing" : "card player",
            )}
            valign={Gtk.Align.CENTER}
          >
            <box
              class="player-art"
              valign={Gtk.Align.CENTER}
              css={coverPath(p)((art) =>
                art ? `background-image: url("${art}");` : "",
              )}
            />
            <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
              <label class="player-title" halign={Gtk.Align.START} maxWidthChars={24} ellipsize={3} label={createBinding(p, "title")((t) => t || "Unknown")} />
              <label class="player-artist" halign={Gtk.Align.START} maxWidthChars={24} ellipsize={3} label={createBinding(p, "artist")((a) => a || "")} />
            </box>
            <box class="player-ctl" valign={Gtk.Align.CENTER}>
              <button class="iconbtn" onClicked={() => p.previous()}>
                <label label="󰒮" />
              </button>
              <button class="iconbtn play" onClicked={() => p.play_pause()}>
                <label label={createBinding(p, "playbackStatus")((s) => (s === AstalMpris.PlaybackStatus.PLAYING ? "󰏤" : "󰐊"))} />
              </button>
              <button class="iconbtn" onClicked={() => p.next()}>
                <label label="󰒭" />
              </button>
            </box>
          </box>
        )
      }
    </With>
    </box>
  )
}

export default function Dashboard({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name={`dashboard-${gdkmonitor.get_connector()}`}
      namespace="ags-dashboard"
      class="ags-dashboard"
      application={app}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
    >
      <box class="dashboard" orientation={Gtk.Orientation.VERTICAL} widthRequest={520}>
        {/* header */}
        <box class="header" valign={Gtk.Align.CENTER}>
          <box class="userchip" valign={Gtk.Align.CENTER} halign={Gtk.Align.START}>
            <box class="avatar" valign={Gtk.Align.CENTER} />
            <label class="username" label="drishal" />
          </box>
          <box hexpand />
          <box class="header-actions" valign={Gtk.Align.CENTER}>
            <button class="hbtn" tooltipText="Settings" onClicked={() => sh("pavucontrol")}>
              <label label="󰒓" />
            </button>
            <button class="hbtn" tooltipText="Lock" onClicked={() => sh("loginctl lock-session")}>
              <label label="󰍁" />
            </button>
            <button
              class="hbtn"
              tooltipText="Power"
              onClicked={() => togglePopup("powermenu", gdkmonitor)}
            >
              <label label="󰐥" />
            </button>
          </box>
        </box>

        <label class="seclabel" halign={Gtk.Align.START} label="Quick Controls" />
        <Tiles />
        <Sliders />
        <Player />
      </box>
    </window>
  )
}
