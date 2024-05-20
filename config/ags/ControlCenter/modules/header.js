import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Battery from 'resource:///com/github/Aylur/ags/service/battery.js';
import { uptime } from '../../variables.js';
import { execAsync } from 'resource:///com/github/Aylur/ags/utils.js';

export const BatteryProgress = () => Widget.Box({
    class_name: 'battery-progress',
    vexpand: true,
    hexpand: true,
    visible: Battery.bind('available'),
    // connections: [[Battery, w => {
    //     w.toggleClassName('charging', Battery.charging || Battery.charged);
    //     w.toggleClassName('medium', Battery.percent < options.battery.medium.value);
    //     w.toggleClassName('low', Battery.percent < options.battery.low.value);
    //     w.toggleClassName('half', Battery.percent < 48);
    // }]],
    child: Widget.Overlay({
        vexpand: true,
        child: Widget.ProgressBar({
            hexpand: true,
            vexpand: true,
        }).hook(Battery, progress => progress.fraction = Battery.percent / 100),
        overlays: [Widget.Label({
            label: Battery.bind('percent').as(p => `${p}%`),
        })],
    }),
});

export default () => Widget.Box({
    class_name: 'header horizontal',
    children: [
        Widget.Box({
            class_name: 'system-box',
            vertical: true,
            hexpand: true,
            children: [
                Widget.Box({
                    children: [
                        Widget.Label({
                            class_name: 'uptime',
                            hexpand: false,
                            vpack: 'center',
                        }).hook(uptime, label => label.label = `uptime: ${uptime.value}`),
                        Widget.Button({
                            vpack: 'center',
                            on_clicked: () => Lockscreen.lockscreen(),
                            child: Widget.Icon('system-lock-screen-symbolic'),
                        }),
                        Widget.Button({
                            vpack: 'center',
                            on_clicked: () => execAsync(['adios', '--systemd']),
                            child: Widget.Icon('system-shutdown-symbolic'),
                        }),
                    ],
                }),
                BatteryProgress(),
            ],
        }),
    ],
});