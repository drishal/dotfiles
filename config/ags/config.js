import { NotificationPopups } from "./notificationPopups.js"
// import from './';
import { ControlPanel } from './ControlPanel.js';
import { Bar } from "./bar.js"

App.config({
    style: "./style.css",
    windows: [
        Bar(0),
        Bar(1),
		ControlPanel,
        NotificationPopups(),
    ],
})

export { }
