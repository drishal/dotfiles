import { createWeather } from "../lib/system"

// Hardcoded to Ahmedabad (matches the old DMS weather location). Change the
// string below to any city/airport code wttr.in understands.
const LOCATION = "Ahmedabad"

export default function Weather() {
  const weather = createWeather(LOCATION)

  return (
    <box
      class="module weather"
      spacing={6}
      tooltipText={weather((w) => w.cond || "Weather")}
    >
      <label class="nerd icon weather-icon" label={weather((w) => w.icon)} />
      <label class="weather-temp" label={weather((w) => w.temp)} />
    </box>
  )
}
