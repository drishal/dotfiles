import Bluetooth from 'resource:///com/github/Aylur/ags/service/bluetooth.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { Menu, ArrowToggleButton } from '../ToggleButton.js';

export const BluetoothToggle = () => ArrowToggleButton({
    name: 'bluetooth',
    icon: Widget.Icon({
    }).hook(Bluetooth, icon => {
        icon.icon = Bluetooth.enabled
            ? 'bluetooth-active-symbolic'
            : 'bluetooth-disabled-symbolic';
    }),
    label: Widget.Label({
        truncate: 'end',
    }).hook(Bluetooth, label => {
        if (!Bluetooth.enabled)
            return label.label = 'Disabled';

        if (Bluetooth.connectedDevices.length === 0)
            return label.label = 'Not Connected';

        if (Bluetooth.connectedDevices.length === 1)
            return label.label = Bluetooth.connectedDevices[0].alias;

        label.label = `${Bluetooth.connectedDevices.length} Connected`;
    }),
    connection: [Bluetooth, () => Bluetooth.enabled],
    deactivate: () => Bluetooth.enabled = false,
    activate: () => Bluetooth.enabled = true,
});

const DeviceItem = device => Widget.Box({
    children: [
        Widget.Icon(device.icon_name + '-symbolic'),
        Widget.Label(device.name),
        Widget.Label({
            label: `${device.battery_percentage}%`,
            visible: device.bind('battery-percentage', p => p > 0),
        }),
        Widget.Box({ hexpand: true }),
        Widget.Spinner({
            active: device.bind('connecting'),
            visible: device.bind("connecting")
        }),
        Widget.Switch({
            active: device.connected,
            visible: device.bind('connecting').as(c => !c),
            onActivate: ({ active }) => device.setConnection(active),
        }),
    ],
});

export const BluetoothDevices = () => Menu({
    name: 'bluetooth',
    icon: Widget.Icon('bluetooth-disabled-symbolic'),
    title: Widget.Label('Bluetooth'),
    content: [
        Widget.Box({
            hexpand: true,
            vertical: true,
            children: Bluetooth.bind("devices").as(ds => ds
                .filter(d => d.name).map(DeviceItem)),
        }),
    ],
});