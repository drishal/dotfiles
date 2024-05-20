import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Brightness from '../../services/brightness.js';

const BrightnessSlider = () => Widget.Slider({
    draw_value: false,
    hexpand: true,
    value: Brightness.bind('screen'),
    on_change: ({ value }) => Brightness.screen = value,
});

export default () => Widget.Box({
    children: [
        Widget.Button({
            child: Widget.Icon('display-brightness-symbolic'),
            tooltipText: Brightness.bind('screen').as(v =>
                `Screen Brightness: ${Math.floor(v * 100)}%`),
        }),
        BrightnessSlider(),
    ],
});