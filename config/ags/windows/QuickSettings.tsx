import app from "ags/gtk4/app"
import AstalWp from "gi://AstalWp"
import AstalNetwork from "gi://AstalNetwork"
import AstalPowerProfiles from "gi://AstalPowerProfiles"
import { Astal, Gtk } from "ags/gtk4"
import { createBinding, createComputed, With } from "ags"
import { execAsync } from "ags/process"
import type Gdk from "gi://Gdk"

function run(cmd: string) {
  execAsync(["bash", "-c", cmd]).catch(console.error)
}

function VolumeRow() {
  const wp = AstalWp.get_default()
  const speaker = wp?.defaultSpeaker
  if (!speaker) return <box />

  return (
    <box class="qs-row" spacing={8}>
      <button onClicked={() => (speaker.mute = !speaker.mute)}>
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

function MicRow() {
  const wp = AstalWp.get_default()
  const mic = wp?.defaultMicrophone
  if (!mic) return <box />

  return (
    <box class="qs-row" spacing={8}>
      <button onClicked={() => (mic.mute = !mic.mute)}>
        <image iconName={createBinding(mic, "volumeIcon")} />
      </button>
      <slider
        hexpand
        value={createBinding(mic, "volume")}
        onChangeValue={({ value }) => mic.set_volume(value)}
      />
    </box>
  )
}

function NetworkRow() {
  const net = AstalNetwork.get_default()
  const primary = createBinding(net, "primary")
  const wifi = createBinding(net, "wifi")

  const label = createComputed([primary, wifi], (p, w) => {
    if (p === AstalNetwork.Primary.WIFI && w) return w.ssid || "Wi-Fi"
    if (p === AstalNetwork.Primary.WIRED) return "Wired"
    return "Disconnected"
  })

  return (
    <box class="qs-row" spacing={8}>
      <With value={wifi}>
        {(w) =>
          w ? (
            <image iconName={createBinding(w, "iconName")} />
          ) : (
            <image iconName="network-wired-symbolic" />
          )
        }
      </With>
      <label label={label} hexpand xalign={0} />
    </box>
  )
}

function PowerProfiles() {
  const pp = AstalPowerProfiles.get_default()
  const profiles = pp.get_profiles?.() ?? []
  if (profiles.length === 0) return <box />

  const active = createBinding(pp, "activeProfile")

  return (
    <box class="qs-profile" orientation={Gtk.Orientation.VERTICAL}>
      <label class="qs-title" label="POWER PROFILE" xalign={0} />
      <box spacing={4} homogeneous>
        {profiles.map(({ profile }) => (
          <button onClicked={() => (pp.activeProfile = profile)}>
            <label
              label={profile}
              class={active((a) => (a === profile ? "ws-focused" : "dim"))}
            />
          </button>
        ))}
      </box>
    </box>
  )
}

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
      <box class="ags-window-content" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        <label class="qs-title" label="AUDIO" xalign={0} />
        <VolumeRow />
        <MicRow />
        <NetworkRow />
        <PowerProfiles />
        <box class="qs-actions" homogeneous spacing={4}>
          <button tooltipText="Audio settings" onClicked={() => run("pavucontrol")}>
            <image iconName="audio-volume-high-symbolic" />
          </button>
          <button tooltipText="Network" onClicked={() => run("nm-connection-editor")}>
            <image iconName="network-wireless-symbolic" />
          </button>
          <button tooltipText="Bluetooth" onClicked={() => run("blueman-manager")}>
            <image iconName="bluetooth-symbolic" />
          </button>
        </box>
      </box>
    </window>
  )
}
