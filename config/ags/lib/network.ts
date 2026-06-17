import AstalNetwork from "gi://AstalNetwork"
import { createBinding, createComputed, type Accessor } from "ags"

export type NetState = {
  icon: Accessor<string> // nerd-font glyph
  label: Accessor<string> // interface name / ssid / status
  active: Accessor<boolean> // is a connection actually up
}

// Smart network readout shared by the bar module and the dashboard tile.
//
// Keys off NetworkManager's *primary* connection (via Astal): when ethernet is
// the active link we show its interface name (e.g. eno1) with the wired glyph;
// on wifi we show the SSID; otherwise the radio state.
export function networkState(): NetState {
  const net = AstalNetwork.get_default()
  const wired = net.wired
  const wifi = net.wifi

  const primary = createBinding(net, "primary")
  const iface = wired
    ? createBinding(wired, "device")((d) => (d ? d.get_iface() ?? "" : ""))
    : createComputed([], () => "")
  const enabled = wifi ? createBinding(wifi, "enabled") : createComputed([], () => false)
  const ssid = wifi ? createBinding(wifi, "ssid") : createComputed([], () => "")

  const { WIRED, WIFI } = AstalNetwork.Primary

  const label = createComputed([primary, iface, ssid, enabled], (p, ifc, s, en) => {
    if (p === WIRED) return ifc || "Wired"
    if (p === WIFI) return s || "Wi-Fi"
    return en ? "Disconnected" : "Off"
  })

  const icon = createComputed([primary, enabled], (p, en) => {
    if (p === WIRED) return "󰈁" // nf-md-ethernet
    if (p === WIFI) return "" // nf-md-wifi
    return en ? "󰤭" : "󰖪" // wifi: disconnected / off
  })

  const active = primary((p) => p === WIRED || p === WIFI)

  return { icon, label, active }
}
