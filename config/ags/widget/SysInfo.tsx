import { cpuUsage, memUsage } from "../lib/system"

export default function SysInfo() {
  return (
    <box class="module sysinfo" spacing={12}>
      <box spacing={5} tooltipText="CPU usage">
        {/* nf-md-cpu_64_bit */}
        <label class="nerd icon" label="󰻠" />
        <label
          class={cpuUsage((v) => (v >= 85 ? "si-warn" : ""))}
          label={cpuUsage((v) => `${v}%`)}
        />
      </box>
      <box spacing={5} tooltipText="Memory used">
        {/* nf-md-memory */}
        <label class="nerd icon" label="󰍛" />
        <label
          class={memUsage((m) => (m.percent >= 90 ? "si-warn" : ""))}
          label={memUsage((m) => `${m.usedGb.toFixed(1)}G`)}
        />
      </box>
    </box>
  )
}
