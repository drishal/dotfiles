import { NotificationPopups } from "./windows/notificationPopups.js"
// import from './';
import { ControlPanel } from './windows/ControlPanel.js';
import { Bar } from "./windows/bar.js"

App.config({
	style: "./style/style.scss",
	windows: [
		Bar(0),
		Bar(1),
		ControlPanel,
		NotificationPopups(),
	],
})

export { }
