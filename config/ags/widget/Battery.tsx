import AstalBattery from "gi://AstalBattery"
import { createBinding, createComputed } from "ags"

export default function Battery() {
  const bat = AstalBattery.get_default()
  const present = createBinding(bat, "isPresent")
  const percentage = createBinding(bat, "percentage")
  const charging = createBinding(bat, "charging")

  const cls = createComputed([percentage, charging], (p, ch) =>
    !ch && p <= 0.2 ? "module battery bat-low" : "module battery",
  )

  return (
    <box class={cls} visible={present} spacing={5} tooltipText="Battery">
      <image iconName={createBinding(bat, "iconName")} />
      <label label={percentage((p) => `${Math.round(p * 100)}%`)} />
    </box>
  )
}
