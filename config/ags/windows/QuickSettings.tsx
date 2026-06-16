import app from "ags/gtk4/app"
import AstalWp from "gi://AstalWp"
import AstalNetwork from "gi://AstalNetwork"
import AstalBluetooth from "gi://AstalBluetooth"
import AstalPowerProfiles from "gi://AstalPowerProfiles"
import AstalBattery from "gi://AstalBattery"
import AstalNotifd from "gi://AstalNotifd"
import Pango from "gi://Pango"
import { Astal, Gtk } from "ags/gtk4"
import { createBinding, createComputed, type Accessor } from "ags"
import { execAsync } from "ags/process"
import { createBrightness } from "../lib/brightness"
import { uptime } from "../lib/system"
import type Gdk from "gi://Gdk"

function run(cmd: string) {
  execAsync(["bash", "-c", cmd]).catch(console.error)
}

const LOCK =
  "swaylock --screenshots --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5"

// ---------------------------------------------------------------------------
// Material filled-tonal toggle (icon + title + status subtitle)
// ---------------------------------------------------------------------------

function Toggle(props: {
  icon: Accessor<string> | string
  title: string
  subtitle: Accessor<string> | string
  active: Accessor<boolean>
  onClicked: () => void
}) {
  return (
    <button
      class={props.active((a) => (a ? "qs-toggle active" : "qs-toggle"))}
      onClicked={props.onClicked}
    >
      <box spacing={10}>
        <image class="qs-toggle-icon" iconName={props.icon} />
        <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER} hexpand>
          <label class="qs-toggle-title" label={props.title} xalign={0} />
          <label
            class="qs-toggle-sub"
            label={props.subtitle}
            xalign={0}
            maxWidthChars={12}
            ellipsize={Pango.EllipsizeMode.END}
          />
        </box>
      </box>
    </button>
  )
}

function NetworkToggle() {
  const net = AstalNetwork.get_default()
  const wifi = net.wifi
  if (!wifi) {
    return (
      <Toggle
        icon="network-wired-symbolic"
        title="Network"
        subtitle="Wired"
        active={createComputed([], () => true)}
        onClicked={() => run("nm-connection-editor")}
      />
    )
  }
  const enabled = createBinding(wifi, "enabled")
  const ssid = createBinding(wifi, "ssid")
  return (
    <Toggle
      icon={enabled((e) =>
        e ? "network-wireless-signal-excellent-symbolic" : "network-wireless-offline-symbolic",
      )}
      title="Wi-Fi"
      subtitle={createComputed([enabled, ssid], (e, s) => (e ? s || "On" : "Off"))}
      active={enabled}
      onClicked={() => wifi.set_enabled(!wifi.enabled)}
    />
  )
}

function BluetoothToggle() {
  const bt = AstalBluetooth.get_default()
  const powered = createBinding(bt, "isPowered")
  const devices = createBinding(bt, "devices")
  const connected = createComputed([devices], (ds) => ds.find((d) => d.connected)?.name ?? "")
  return (
    <Toggle
      icon={powered((p) => (p ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"))}
      title="Bluetooth"
      subtitle={createComputed([powered, connected], (p, c) => (p ? c || "On" : "Off"))}
      active={powered}
      onClicked={() => {
        const a = bt.adapter
        if (a) a.powered = !a.powered
      }}
    />
  )
}

function PowerProfileToggle() {
  const pp = AstalPowerProfiles.get_default()
  const profiles = (pp.get_profiles?.() ?? []).map((p) => p.profile)
  const active = createBinding(pp, "activeProfile")
  const label = (p: string) =>
    p === "performance" ? "Performance" : p === "power-saver" ? "Power Saver" : "Balanced"
  const icon = (p: string) =>
    p === "performance"
      ? "power-profile-performance-symbolic"
      : p === "power-saver"
        ? "power-profile-power-saver-symbolic"
        : "power-profile-balanced-symbolic"
  return (
    <Toggle
      icon={active(icon)}
      title="Profile"
      subtitle={active(label)}
      active={active((p) => p === "performance")}
      onClicked={() => {
        if (profiles.length === 0) return
        const i = profiles.indexOf(pp.activeProfile)
        pp.activeProfile = profiles[(i + 1) % profiles.length]
      }}
    />
  )
}

function DndToggle() {
  const notifd = AstalNotifd.get_default()
  const dnd = createBinding(notifd, "dontDisturb")
  return (
    <Toggle
      icon={dnd((d) =>
        d ? "notifications-disabled-symbolic" : "preferences-system-notifications-symbolic",
      )}
      title="Silent"
      subtitle={dnd((d) => (d ? "On" : "Off"))}
      active={dnd}
      onClicked={() => (notifd.dontDisturb = !notifd.dontDisturb)}
    />
  )
}

function MuteToggle(props: { kind: "speaker" | "microphone" }) {
  const wp = AstalWp.get_default()
  const ep = props.kind === "speaker" ? wp?.defaultSpeaker : wp?.defaultMicrophone
  if (!ep) return <box />
  const mute = createBinding(ep, "mute")
  return (
    <Toggle
      icon={createBinding(ep, "volumeIcon")}
      title={props.kind === "speaker" ? "Audio" : "Mic"}
      subtitle={mute((m) => (m ? "Muted" : "On"))}
      active={mute((m) => !m)}
      onClicked={() => (ep.mute = !ep.mute)}
    />
  )
}

// ---------------------------------------------------------------------------
// Sliders
// ---------------------------------------------------------------------------

function VolumeSlider() {
  const wp = AstalWp.get_default()
  const speaker = wp?.defaultSpeaker
  if (!speaker) return <box />
  return (
    <box class="qs-slider" spacing={10}>
      <button class="qs-slider-icon" onClicked={() => (speaker.mute = !speaker.mute)}>
        <image iconName={createBinding(speaker, "volumeIcon")} />
      </button>
      <slider
        hexpand
        value={createBinding(speaker, "volume")}
        onChangeValue={({ value }) => speaker.set_volume(value)}
      />
    </box>
  )
}

function BrightnessSlider() {
  const bri = createBrightness()
  if (!bri.available) return <box visible={false} />
  return (
    <box class="qs-slider" spacing={10}>
      <box class="qs-slider-icon static">
        <image iconName="display-brightness-symbolic" />
      </box>
      <slider hexpand value={bri.value} onChangeValue={({ value }) => bri.set(value)} />
    </box>
  )
}

// ---------------------------------------------------------------------------
// Footer (battery / uptime / power actions)
// ---------------------------------------------------------------------------

function Footer() {
  const bat = AstalBattery.get_default()
  const present = createBinding(bat, "isPresent")
  const percent = createBinding(bat, "percentage")
  const charging = createBinding(bat, "charging")

  const batLine = createComputed([present, percent, charging], (p, pc, ch) =>
    p ? `${ch ? "󰚥 " : ""}${Math.round(pc * 100)}%` : "󰚥 Plugged in",
  )

  return (
    <box class="qs-footer" spacing={12}>
      <image class="qs-avatar" iconName="avatar-default-symbolic" />
      <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER} hexpand>
        <label class="qs-bat" label={batLine} xalign={0} />
        <label class="qs-uptime" label={uptime((u) => `up ${u}`)} xalign={0} />
      </box>
      <box class="qs-power" spacing={6}>
        <button tooltipText="Lock" onClicked={() => run(LOCK)}>
          <image iconName="system-lock-screen-symbolic" />
        </button>
        <button tooltipText="Log out" onClicked={() => run("hyprctl dispatch exit")}>
          <image iconName="system-log-out-symbolic" />
        </button>
        <button class="qs-power-off" tooltipText="Shut down" onClicked={() => run("systemctl poweroff")}>
          <image iconName="system-shutdown-symbolic" />
        </button>
      </box>
    </box>
  )
}

// ---------------------------------------------------------------------------

export default function QuickSettings({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name={`quicksettings-${gdkmonitor.get_connector()}`}
      namespace="ags-quicksettings"
      class="ags-window ags-quicksettings-window"
      application={app}
      gdkmonitor={gdkmonitor}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
    >
      <box class="ags-window-content qs-panel" orientation={Gtk.Orientation.VERTICAL} spacing={12}>
        <box class="qs-grid" orientation={Gtk.Orientation.VERTICAL} spacing={8}>
          <box spacing={8} homogeneous>
            <NetworkToggle />
            <BluetoothToggle />
          </box>
          <box spacing={8} homogeneous>
            <PowerProfileToggle />
            <DndToggle />
          </box>
          <box spacing={8} homogeneous>
            <MuteToggle kind="speaker" />
            <MuteToggle kind="microphone" />
          </box>
        </box>

        <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
          <VolumeSlider />
          <BrightnessSlider />
        </box>

        <Footer />
      </box>
    </window>
  )
}
