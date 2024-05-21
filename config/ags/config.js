import { NotificationPopups } from "./notificationPopups.js"
import ControlCenter from './ControlCenter/ControlCenter.js';
import { Bar } from "./bar.js"

App.config({
    style: "./style.css",
    windows: [
        Bar(0),
        Bar(1),
        ControlCenter(),
        NotificationPopups(),
    ],
})

export { }
