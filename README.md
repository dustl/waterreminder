# macOS Water Reminder — 喝水提醒

A gentle macOS menu bar app that reminds you to drink water regularly, with weather-aware icons.

一个温柔优雅的 macOS 菜单栏喝水提醒工具，图标随天气自动变化。

---

## Features / 功能

- **⏰ Regular Reminders** — Default every 2 hours, fully customizable (10–480 min)
- **🌤️ Weather-Aware Icons** — Menu bar icon changes with local weather using SF Symbols
- **🫧 Gentle Messages** — 41 elegant, heartwarming reminder texts, randomly selected
- **🌍 Auto Location** — IP-based geolocation via ipinfo.io, weather via Open-Meteo (free, no API key)
- **🎨 Elegant Design** — Native macOS menu bar app, dark/light mode adaptive
- **💾 Persistent Settings** — Reminder interval saved in UserDefaults
- **🚀 Auto-Start** — LaunchAgent support for login auto-start
- **🔒 Privacy** — No data collection, no account needed

- **⏰ 定时提醒** — 默认每 2 小时，支持自定义 10–480 分钟
- **🌤️ 天气感知图标** — 菜单栏图标随当地天气自动变换（SF Symbols 系统图标）
- **🫧 温柔文案** — 41 条优雅温馨的提醒语，每次随机抽取
- **🌍 自动定位** — IP 定位（ipinfo.io）+ Open-Meteo 天气（免费，无需 API Key）
- **🎨 精致设计** — 原生 macOS 菜单栏应用，支持深色/浅色模式
- **💾 持久化设置** — 提醒间隔自动保存
- **🚀 开机自启** — 支持 LaunchAgent 登录自启动
- **🔒 隐私安全** — 不收集任何数据，无需注册

---

## Preview / 预览

| Weather | Icon | Description |
|---------|------|-------------|
| ☀️ Clear | `drop.fill` | Elegant water droplet |
| ⛅ Partly Cloudy | `cloud.sun.fill` | Cloud with sun |
| ☁️ Cloudy | `cloud.fill` | Single cloud |
| 🌫️ Fog | `cloud.fog.fill` | Cloud with fog |
| 🌧️ Rain | `cloud.rain.fill` | Cloud with rain |
| ❄️ Snow | `cloud.snow.fill` | Cloud with snow |
| ⛈️ Thunder | `cloud.bolt.fill` | Cloud with lightning |

![App Icon](icon_preview.png)

---

## Quick Start / 快速开始

### Download & Run / 下载运行

```bash
# Open the app
open /Applications/water/WaterReminder.app
```

Or double-click `WaterReminder.app` in Finder.

### Build from Source / 从源码编译

```bash
cd /Applications/water
swiftc -o WaterReminder.app/Contents/MacOS/WaterReminder main.swift \
  -framework Cocoa -framework UserNotifications
open WaterReminder.app
```

### Auto-Start on Login / 开机自启

```bash
cp com.water.reminder.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.water.reminder.plist
```

---

## Usage / 使用方法

Click the icon 🫧 in the menu bar to open the menu:

- **提醒一次 / Remind Now** — Trigger an immediate reminder
- **重置计时 / Reset Timer** — Reset the countdown
- **提醒间隔 / Interval** — Set reminder frequency:
  - Presets: 30, 60, 90, 120 (default), 180 min
  - Custom: 10–480 min
- **查看状态 / Status** — Show time since last reminder
- **刷新天气 / Refresh Weather** — Update weather data manually
- **退出 / Quit** — Exit the app

### Helper Scripts / 辅助脚本

```bash
./start.sh   # Launch the app
./stop.sh    # Kill the app
./status.sh  # Check if running
```

---

## How It Works / 工作原理

1. **Location** — On launch, IP-based geolocation via `ipinfo.io`
2. **Weather** — Fetches forecast from `Open-Meteo` (free, no API key)
3. **Icon** — Updates menu bar icon with matching SF Symbol
4. **Timer** — Counts down your set interval, then fires a system notification
5. **Refresh** — Weather refreshes every hour automatically

---

## Requirements / 系统要求

- macOS 11.0+ (Big Sur or later)
- Internet connection (for weather data)

---

## Files / 文件说明

| File | Purpose |
|------|---------|
| `main.swift` | Source code (Swift) |
| `WaterReminder.app/` | Compiled app bundle |
| `start.sh` / `stop.sh` / `status.sh` | Helper scripts |
| `com.water.reminder.plist` | LaunchAgent for auto-start |
| `gen_icon.py` | App icon generator (Python) |
| `WaterReminder.iconset/` | Generated icon sources |

---

## Tech Stack / 技术栈

- **Language:** Swift 5.7
- **Frameworks:** Cocoa, UserNotifications, Foundation
- **API:** ipinfo.io (geolocation), Open-Meteo (weather)
- **Icons:** Apple SF Symbols
- **Persistence:** UserDefaults

---

## License / 许可证

MIT

---

*Made with 💧 for the desk-bound developer who always forgets to drink water.*
*献给总是忘记喝水的开发者们。*
