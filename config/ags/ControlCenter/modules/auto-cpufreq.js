import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Auto_CPUFreq from '../../services/auto-cpufreq.js';

const GovernorButton = (label, icon) => Widget.Button({
    className: 'governor-button',
    child: Widget.Box({
        hexpand: false,
        children: [
            Widget.Icon(icon),
            Widget.Label({
                label: label
            })
        ]
    }),
    onClicked: (self) => Auto_CPUFreq.governor = (self.className.includes('active')) ? 'Default' : label,
}).hook(Auto_CPUFreq, self => {
    let governor = label.toLowerCase();
    if (governor === Auto_CPUFreq.governor)
        self.toggleClassName('active', true);
    else
        self.toggleClassName('active', false);

}, "notify::governor")

export const Governors = () => Widget.Box({
    className: "toggle-button",
    homogeneous: true,
    children: [
        GovernorButton("Powersave", "power-profile-power-saver-symbolic"),
        GovernorButton("Performance", "power-profile-performance-symbolic"),
    ]
})

