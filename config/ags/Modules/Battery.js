import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Battery from 'resource:///com/github/Aylur/ags/service/battery.js';
// import { SecToHourAndMin } from '../Common.js'; 

export function SecToHourAndMin(seconds){
    var minutesRaw = Math.floor(seconds / 60) 
    var minutes = minutesRaw % 60
    var hours = Math.floor(minutesRaw / 60) 
    return `${hours} hours, and ${minutes} minutes`
}

export const BatteryLabel = () => Widget.Box({
    visible: Battery.bind('available'),
    tooltip_text: Battery.bind('time-remaining').as(v => `Time remaining: ${SecToHourAndMin(v)}`),

    hpack: "center",
    children: [
        // Percent
        Widget.Label({
            label: Battery.bind('percent').transform(p => {
                return p.toString() + "% "
            })
        }),

        //Icon
        Widget.Overlay({
            class_name: "battery icon",
            child: Widget.Label({
                class_name: "battery-bg",
                label: Battery.bind('charging').transform(p => {
                    if (p){
                        return ""
                    }
                    return ""
                })
            }),
            overlays: [
                Widget.Label({
                    class_name: "battery-fg"
                }).hook(Battery, label => {
                    print("bat: " + Battery.energy)
                    if (Battery.charging){
                        label.label = ""
                    }
                    else if (Battery.percent > 80){
                        label.label = ""
                    }
                    else if (Battery.percent> 60){
                        label.label = ""
                    }
                    else if (Battery.percent > 40){
                        label.label = ""
                    }
                    else if (Battery.percent > 20){
                        label.label = ""
                    }
                    else{
                        label.label = ""
                    }
                }, 'changed'),
            ]
        }),

    ],
});

export const BatteryCircle = () => Widget.CircularProgress({
    class_name: "battery-circle",
    start_at: 0.25,
    rounded: true,
    value: Battery.bind("percent").transform(p => p / 100),
})

export const BatteryWidget = (w, h) => Widget.Box({ 
    css: `
        min-width: ${w}rem;
        min-height: ${h}rem;
    `,
    class_name: `control-panel-button`,
    children: [
        Widget.Overlay({
            visible: Battery.bind('available'),
            hexpand: true,
            child:
                BatteryCircle(),
            overlays: [
                BatteryLabel(),
            ]
        }),
    ]
})
