pragma Singleton

// Weather via Open-Meteo (mirrors ags lib/weather.ts). curl the forecast every
// 15 min; expose current conditions + a 5-hour strip. Icons are Nerd Font
// glyphs (Maple Mono NF). Location: Ahmedabad, Gujarat.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property real lat: 23.0225
    readonly property real lon: 72.5714
    readonly property string locationName: "Ahmedabad"

    property string status: "loading" // "loading" | "ready" | "error"
    property var current: null
    property var hourly: []

    readonly property var wmoDay: ({
            "0": {
                icon: "󰖙",
                desc: "Clear sky"
            },
            "1": {
                icon: "󰖙",
                desc: "Mainly clear"
            },
            "2": {
                icon: "󰼰",
                desc: "Partly cloudy"
            },
            "3": {
                icon: "󰖕",
                desc: "Overcast"
            },
            "45": {
                icon: "󰖑",
                desc: "Fog"
            },
            "48": {
                icon: "󰖑",
                desc: "Depositing rime fog"
            },
            "51": {
                icon: "󰼰",
                desc: "Light drizzle"
            },
            "53": {
                icon: "󰼰",
                desc: "Moderate drizzle"
            },
            "55": {
                icon: "󰖗",
                desc: "Dense drizzle"
            },
            "56": {
                icon: "󰖗",
                desc: "Freezing drizzle"
            },
            "57": {
                icon: "󰖗",
                desc: "Dense freezing drizzle"
            },
            "61": {
                icon: "󰖖",
                desc: "Slight rain"
            },
            "63": {
                icon: "󰖖",
                desc: "Moderate rain"
            },
            "65": {
                icon: "󰖖",
                desc: "Heavy rain"
            },
            "66": {
                icon: "󰖖",
                desc: "Freezing rain"
            },
            "67": {
                icon: "󰖖",
                desc: "Heavy freezing rain"
            },
            "71": {
                icon: "󰖘",
                desc: "Slight snow"
            },
            "73": {
                icon: "󰖘",
                desc: "Moderate snow"
            },
            "75": {
                icon: "󰖘",
                desc: "Heavy snow"
            },
            "77": {
                icon: "󰖘",
                desc: "Snow grains"
            },
            "80": {
                icon: "󰖖",
                desc: "Slight rain showers"
            },
            "81": {
                icon: "󰖖",
                desc: "Moderate rain showers"
            },
            "82": {
                icon: "󰖖",
                desc: "Violent rain showers"
            },
            "85": {
                icon: "󰖘",
                desc: "Slight snow showers"
            },
            "86": {
                icon: "󰖘",
                desc: "Heavy snow showers"
            },
            "95": {
                icon: "󰖞",
                desc: "Thunderstorm"
            },
            "96": {
                icon: "󰖞",
                desc: "Thunderstorm with hail"
            },
            "99": {
                icon: "󰖞",
                desc: "Severe thunderstorm"
            }
        })
    readonly property var wmoNight: ({
            "0": {
                icon: "󰖜",
                desc: "Clear sky"
            },
            "1": {
                icon: "󰖜",
                desc: "Mainly clear"
            },
            "2": {
                icon: "󰼱",
                desc: "Partly cloudy"
            },
            "3": {
                icon: "󰖕",
                desc: "Overcast"
            },
            "45": {
                icon: "󰖑",
                desc: "Fog"
            },
            "48": {
                icon: "󰖑",
                desc: "Depositing rime fog"
            },
            "51": {
                icon: "󰼱",
                desc: "Light drizzle"
            },
            "53": {
                icon: "󰼱",
                desc: "Moderate drizzle"
            },
            "55": {
                icon: "󰖗",
                desc: "Dense drizzle"
            },
            "56": {
                icon: "󰖗",
                desc: "Freezing drizzle"
            },
            "57": {
                icon: "󰖗",
                desc: "Dense freezing drizzle"
            },
            "61": {
                icon: "󰖖",
                desc: "Slight rain"
            },
            "63": {
                icon: "󰖖",
                desc: "Moderate rain"
            },
            "65": {
                icon: "󰖖",
                desc: "Heavy rain"
            },
            "66": {
                icon: "󰖖",
                desc: "Freezing rain"
            },
            "67": {
                icon: "󰖖",
                desc: "Heavy freezing rain"
            },
            "71": {
                icon: "󰖘",
                desc: "Slight snow"
            },
            "73": {
                icon: "󰖘",
                desc: "Moderate snow"
            },
            "75": {
                icon: "󰖘",
                desc: "Heavy snow"
            },
            "77": {
                icon: "󰖘",
                desc: "Snow grains"
            },
            "80": {
                icon: "󰖖",
                desc: "Slight rain showers"
            },
            "81": {
                icon: "󰖖",
                desc: "Moderate rain showers"
            },
            "82": {
                icon: "󰖖",
                desc: "Violent rain showers"
            },
            "85": {
                icon: "󰖘",
                desc: "Slight snow showers"
            },
            "86": {
                icon: "󰖘",
                desc: "Heavy snow showers"
            },
            "95": {
                icon: "󰖞",
                desc: "Thunderstorm"
            },
            "96": {
                icon: "󰖞",
                desc: "Thunderstorm with hail"
            },
            "99": {
                icon: "󰖞",
                desc: "Severe thunderstorm"
            }
        })

    function wmoInfo(code, isDay) {
        const k = String(code);
        const day = wmoDay[k];
        if (isDay)
            return day || {
                icon: "󰼳",
                desc: "Unknown"
            };
        return wmoNight[k] || day || {
            icon: "󰼳",
            desc: "Unknown"
        };
    }

    function windDirToCompass(deg) {
        const dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
        return dirs[Math.round(deg / 45) % 8];
    }

    function fetchNow() {
        proc.running = true;
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchNow()
    }

    Process {
        id: proc
        command: {
            const cur = ["temperature_2m", "apparent_temperature", "relative_humidity_2m", "weathercode", "windspeed_10m", "winddirection_10m", "precipitation", "is_day", "uv_index"].join(",");
            const hr = ["temperature_2m", "weathercode", "precipitation_probability"].join(",");
            const url = "https://api.open-meteo.com/v1/forecast" + "?latitude=" + root.lat + "&longitude=" + root.lon + "&current=" + cur + "&hourly=" + hr + "&forecast_days=2&timezone=auto";
            return ["bash", "-c", "curl -s '" + url + "'"];
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (!this.text) {
                        root.status = "error";
                        return;
                    }
                    const j = JSON.parse(this.text);
                    const c = j.current;
                    root.current = {
                        temp: Math.round(c.temperature_2m),
                        feelsLike: Math.round(c.apparent_temperature),
                        humidity: c.relative_humidity_2m,
                        windSpeed: Math.round(c.windspeed_10m),
                        windDir: c.winddirection_10m,
                        precipitation: c.precipitation,
                        weatherCode: c.weathercode,
                        isDay: c.is_day === 1,
                        uvIndex: c.uv_index || 0
                    };
                    const nowIso = c.time.slice(0, 13);
                    let startIdx = j.hourly.time.findIndex(t => t.startsWith(nowIso));
                    const safeStart = Math.max(0, startIdx) + 1;
                    const out = [];
                    for (let i = safeStart; i < safeStart + 5 && i < j.hourly.time.length; i++)
                        out.push({
                            time: j.hourly.time[i],
                            temp: Math.round(j.hourly.temperature_2m[i]),
                            weatherCode: j.hourly.weathercode[i],
                            precipProb: (j.hourly.precipitation_probability || [])[i] || 0
                        });
                    root.hourly = out;
                    root.status = "ready";
                } catch (e) {
                    root.status = "error";
                }
            }
        }
    }
}
