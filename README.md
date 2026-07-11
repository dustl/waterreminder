# macOS Water Reminder — 喝水提醒

A gentle macOS menu bar app that reminds you to drink water regularly, with weather-aware icons and daily intake tracking.

一个温柔优雅的 macOS 菜单栏喝水提醒工具，图标随天气自动变化，支持饮水记录。

---

## Features / 功能

- **⏰ Regular Reminders** — Default every 2 hours, customizable (10–480 min)
  
- **💧 Drink Logging** — Log each glass (250ml / 500ml) from menu or notification
  
- **🎯 Daily Goal** — Track your daily water intake with a visual progress bar
  
- **🌤️ Weather-Aware Icons** — Menu bar icon changes with local weather using SF Symbols
  
- **🔥 Smart Adjustments** — Automatically halves reminder interval when ≥30°C
  
- **🫧 Gentle Messages** — 41 elegant, heartwarming reminder texts, randomly selected
  
- **🔔 Interactive Notifications** — Log drinks or snooze directly from the notification
  
- **⏳ Working Hours** — Only reminds during your active hours (default 9:00–22:00)
  
- **💤 Sleep-Aware** — Detects Mac wake and sends a missed reminder if needed
  
- **🌍 Auto Location** — IP-based geolocation via ipinfo.io, weather via Open-Meteo (free, no API key)
  
- **🎨 Elegant Design** — Native macOS menu bar app, dark/light mode adaptive
  
- **💾 Persistent Settings** — All preferences (interval, goal, hours) saved in UserDefaults
  
- **🌤️ Weather Caching** — Shows cached weather instantly on startup
  
- **🚀 Auto-Start** — LaunchAgent support for login auto-start
  
- **🔒 Privacy** — No data collection, no account needed
  
- **⏰ 定时提醒** — 默认每 2 小时，支持自定义 10–480 分钟
  
- **💧 饮水记录** — 每次喝水后在菜单或通知中记录（250ml / 500ml）
  
- **🎯 每日目标** — 设置每日饮水量目标，菜单栏显示进度条
  
- **🌤️ 天气感知图标** — 菜单栏图标随当地天气自动变换（SF Symbols 系统图标）
  
- **🔥 智能调整** — 气温 ≥30°C 时自动缩短提醒间隔
  
- **🫧 温柔文案** — 41 条优雅温馨的提醒语，每次随机抽取
  
- **🔔 交互式通知** — 通知上可直接记录饮水或稍后提醒
  
- **⏳ 工作时段** — 仅在设定时段内提醒（默认 9:00–22:00）
  
- **💤 唤醒感知** — Mac 从睡眠唤醒后检测并补发错过的提醒
  
- **🌍 自动定位** — IP 定位（ipinfo.io）+ Open-Meteo 天气（免费，无需 API Key）
  
- **🎨 精致设计** — 原生 macOS 菜单栏应用，支持深色/浅色模式
  
- **💾 持久化设置** — 所有偏好设置（间隔、目标、时段）自动保存
  
- **🌤️ 天气缓存** — 启动时立即显示上次天气，无需等待网络
  
- **🚀 开机自启** — 支持 LaunchAgent 登录自启动
  
- **🔒 隐私安全** — 不收集任何数据，无需注册
  

---

## Preview / 预览

| Weather | Icon | Description |
| --- | --- | --- |
| ☀️ Clear | `drop.fill` | Elegant water droplet |
| ⛅ Partly Cloudy | `cloud.sun.fill` | Cloud with sun |
| ☁️ Cloudy | `cloud.fill` | Single cloud |
| 🌫️ Fog | `cloud.fog.fill` | Cloud with fog |
| 🌧️ Rain | `cloud.rain.fill` | Cloud with rain |
| ❄️ Snow | `cloud.snow.fill` | Cloud with snow |
| ⛈️ Thunder | `cloud.bolt.fill` | Cloud with lightning |

![App Icon](file:///Applications/water/waterreminder/icon_preview.png)

---

## Quick Start / 快速开始

### Download & Run / 下载运行

```bash
# Open the app
open /Applications/water/waterreminder/WaterReminder.app
```

Or double-click `WaterReminder.app` in Finder.

### Build from Source / 从源码编译

```bash
cd /Applications/water/waterreminder
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

Click the icon in the menu bar to open the menu:

```
喝水提醒
---
💧 800/2000ml ████░░░░░░ 40%    ← 今日饮水进度
喝了一杯水 (250ml)   ⌘D          ← 快速记录
喝了一大杯 (500ml)   ⌘⇧D
每日目标  2000ml ▸                ← 设置每日目标
---
⛅ 多云 · 24°C                   ← 实时天气
---
提醒一次          ⌘R              ← 立即提醒
重置计时          ⌘T              ← 重置倒计时
提醒间隔    2 小时 ▸               ← 设置提醒频率
工作时段    9:00-22:00 ▸           ← 设置工作时段
---
查看状态          ⌘S              ← 查看详情
---
刷新天气          ⌘W              ← 手动刷新天气
退出              ⌘Q
```

### Menu Items / 菜单项

| Item | Shortcut | Description |
| --- | --- | --- |
| **喝了一杯水 (250ml)** | `⌘D` | Log 250ml drink, resets timer |
| **喝了一大杯 (500ml)** | `⌘⇧D` | Log 500ml drink, resets timer |
| **每日目标** | —   | Set daily goal (1000–3000ml presets, or custom 500–10000ml) |
| **提醒一次 / Remind Now** | `⌘R` | Trigger an immediate reminder |
| **重置计时 / Reset Timer** | `⌘T` | Reset the countdown |
| **提醒间隔 / Interval** | —   | Set reminder frequency: presets (30/60/90/120/180 min) or custom (10–480 min) |
| **工作时段 / Working Hours** | —   | Set active hours: presets or custom, or disable (24h) |
| **查看状态 / Status** | `⌘S` | Show time since last reminder, today's intake %, hot mode status |
| **刷新天气 / Refresh Weather** | `⌘W` | Update weather data manually |
| **退出 / Quit** | `⌘Q` | Exit the app |

### Interactive Notifications / 交互式通知

When a reminder appears, you can interact directly:

- **✅ 喝了 250ml** — Logs a glass and resets the timer
- **✅ 喝了 500ml** — Logs a big glass and resets the timer
- **⏰ 10 分钟后** — Snooze for 10 minutes
- **⏰ 30 分钟后** — Snooze for 30 minutes

When you reach your daily goal, a congratulatory notification is automatically sent 🎉

### Helper Scripts / 辅助脚本

```bash
./start.sh   # Launch the app
./stop.sh    # Kill the app
./status.sh  # Check if running
```

---

## How It Works / 工作原理

1. **Location** — On launch, IP-based geolocation via `ipinfo.io`
2. **Weather** — Fetches forecast from `Open-Meteo` (free, no API key); caches on disk
3. **Icon** — Updates menu bar icon with matching SF Symbol
4. **Timer** — Counts down your set interval (halved if ≥30°C), then fires a system notification with interactive buttons
5. **Logging** — Each drink log persists to `UserDefaults`, auto-resets daily
6. **Working Hours** — Outside set hours, timer skips to next start time
7. **Refresh** — Weather refreshes every hour automatically

---

## Requirements / 系统要求

- macOS 11.0+ (Big Sur or later)
- Internet connection (for weather data)

---

## Files / 文件说明

| File | Purpose |
| --- | --- |
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
