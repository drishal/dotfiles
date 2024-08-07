const hyprland = await Service.import("hyprland")
const audio = await Service.import("audio")
const battery = await Service.import("battery")
const systemtray = await Service.import("systemtray")
const network = await Service.import('network')
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
// import controlCenterButton from controlCenterButton;
// import controlCenterButton from './controlCenterButton.js'
import { ControlPanelToggleButton } from './ControlPanel.js';



const dispatch = ws => hyprland.messageAsync(`dispatch workspace ${ws}`);
const Workspaces = () => Widget.EventBox({
	onScrollUp: () => dispatch('+1'),
	onScrollDown: () => dispatch('-1'),
	child: Widget.Box({
		children: Array.from({ length: 10 }, (_, i) => i + 1).map(i => Widget.Button({
			class_name: "workspaces",
			attribute: i,
			label: `${i}`,
			onClicked: () => dispatch(i),
			setup: self => self.hook(Hyprland, () => {
				// The "?" is used here to return "undefined" if the workspace doesn't exist
				self.toggleClassName('ws-inactive', (Hyprland.getWorkspace(i)?.windows || 0) === 0);
				self.toggleClassName('ws-occupied', (Hyprland.getWorkspace(i)?.windows || 0) > 0);
				self.toggleClassName('ws-active', Hyprland.active.workspace.id === i);
				self.toggleClassName('ws-large', (Hyprland.getWorkspace(i)?.windows || 0) > 1);
			}),

		})),

		// remove this setup hook if you want fixed number of buttons
		// setup: self => self.hook(hyprland, () => self.children.forEach(btn => {
		//     btn.visible = hyprland.workspaces.some(ws => ws.id === btn.attribute);
		// })),
	}),
})

function ClientTitle() {
	return Widget.Label({
		class_name: "client-title",
		label: hyprland.active.client.bind("title"),
	})
}


function Clock() {
	const date = Variable("", {
		poll: [1000, 'date "+  %H:%M:%S | %b %e %Y"'],
	})
	return Widget.Label({
		class_name: "clock",
		label: date.bind(),
	})
}

const ram = Variable("", {
	// poll: [1000, 'bash ~/dotfiles/config/ags/scripts/ram.sh'],
	poll: [1000, `bash ${App.configDir}/scripts/ram.sh`],
});

function Ram(){
	return Widget.Label({
		class_name: "ram",
		label: ram.bind(),
	})
}
const cpu= Variable("", {
	// poll: [1000, 'bash ~/dotfiles/config/ags/scripts/cpu.sh'],
	poll: [1000, `bash ${App.configDir}/scripts/cpu.sh`],
});
function Cpu(){
	return Widget.Label({
		class_name: "cpu",
		label: cpu.bind(),
	})
}

function BatteryLabel() {
	const value = battery.bind("percent").as(p => p > 0 ? p / 100 : 0)
	const percent = value.emitter.percent
	const icon = battery.bind("percent").as(p =>
		`battery-level-${Math.floor(p / 10) * 10}-symbolic`)

	return Widget.Box({
		class_name: "battery",
		visible: battery.bind("available"),
		children: [
			Widget.Icon({ icon }),
			Widget.Label({
				// widthRequest: 140,
				// vpack: "center",
				// label: value,
				label: " ".concat(String(percent).concat("%")),
			}),
		],
	})
}

function SysTray() {
	const items = systemtray.bind("items")
		  .as(items => items.map(item => Widget.Button({
			  // class_name: "tray",
			  class_name: "trayicons",
			  child: Widget.Icon({ icon: item.bind("icon") }),
			  on_primary_click: (_, event) => item.activate(event),
			  on_secondary_click: (_, event) => item.openMenu(event),
			  tooltip_markup: item.bind("tooltip_markup"),
		  })))

	return Widget.Box({
		children: items,
		class_name: "tray",
	})
}

const wifiindicator = network.wifi.bind('ssid').as(ssid => ssid || 'Unknown')
const WifiIndicator = () => Widget.Box({
	children: [
		Widget.Icon({
			icon: network.wifi.bind('icon_name'),
		}),
		Widget.Label({
			label: " ".concat(wifiindicator.emitter.ssid),
		}),
	],
})

const WiredIndicator = () => Widget.Box({
	// children: [
	//     Widget.Icon({
	//         icon: network.wired.bind('icon_name'),
	//     }),
	//     Widget.Label({
	//         label: network.wifi.bind('internet'),
	//     }),
	// ],
	label: network.wired.bind('icon_name'),
})

const NetworkIndicator = () => Widget.Stack({
	children: {
		wifi: WifiIndicator(),
		wired: WiredIndicator(),
	},

	class_name: "network",
	shown: network.bind('primary').as(p => p || 'wifi'),
})
// layout of the bar
function Left() {
	return Widget.Box({
		spacing: 8,
		children: [
			Workspaces(),
			ClientTitle(),
		],
	})
}

function Center() {
	return Widget.Box({
		spacing: 8,
		children: [
			// Media(),
			Clock(),
		],
	})
}

// function Right() {
const Right = (monitor) => Widget.Box({
	// return Widget.Box({
		hpack: "end",
		spacing: 8,
		children: [
			Ram(),
			Cpu(),
			BatteryLabel(),
			SysTray(),
			// controlCenterButton(),
			ControlPanelToggleButton(monitor)
		],
	})
// }

export function Bar(monitor = 0) {
	return Widget.Window({
		name: `bar-${monitor}`, // name has to be unique
		class_name: "bar",
		monitor,
		anchor: ["top", "left", "right"],
		exclusivity: "exclusive",
		margins: [6, 6],
		child: Widget.CenterBox({
			start_widget: Left(),
			center_widget: Center(),
			end_widget: Right(),
		}),
	})
}
// function Volume() {
// 	const icons = {
// 		101: "overamplified",
// 		67: "high",
// 		34: "medium",
// 		1: "low",
// 		0: "muted",
// 	}

// 	function getIcon() {
// 		const icon = audio.speaker.is_muted ? 0 : [101, 67, 34, 1, 0].find(
// 			threshold => threshold <= audio.speaker.volume * 100)

// 		return `audio-volume-${icons[icon]}-symbolic`
// 	}

// 	const icon = Widget.Icon({
// 		icon: Utils.watch(getIcon(), audio.speaker, getIcon),
// 	})

// 	const slider = Widget.Slider({
// 		hexpand: true,
// 		draw_value: false,
// 		on_change: ({ value }) => audio.speaker.volume = value,
// 		setup: self => self.hook(audio.speaker, () => {
// 			self.value = audio.speaker.volume || 0
// 		}),
// 	})

// 	return Widget.Box({
// 		class_name: "volume",
// 		children: [icon, slider],
// 	})
// }
// const VolumeSlider = (type = 'speaker') => Widget.Slider({
// 	hexpand: true,
// 	drawValue: false,
// 	onChange: ({ value }) => audio[type].volume = value,
// 	value: audio[type].bind('volume'),
// })

// const divide = ([total, free]) => free / total

