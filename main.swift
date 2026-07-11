import Cocoa
import UserNotifications

// MARK: - 天气类型

enum WeatherType: String {
    case clear
    case partlyCloudy
    case cloudy
    case fog
    case rain
    case snow
    case thunder
    case unknown

    // WMO weather codes from Open-Meteo
    static func from(wmoCode: Int) -> WeatherType {
        switch wmoCode {
        case 0:             return .clear
        case 1, 2, 3:       return .partlyCloudy
        case 45, 48:        return .fog
        case 51...57:       return .rain       // drizzle
        case 61...67:       return .rain
        case 71...77:       return .snow
        case 80...82:       return .rain       // rain showers
        case 85, 86:        return .snow       // snow showers
        case 95...99:       return .thunder
        default:            return .unknown
        }
    }

    var displayName: String {
        switch self {
        case .clear:        return "晴"
        case .partlyCloudy: return "多云"
        case .cloudy:       return "阴天"
        case .fog:          return "雾"
        case .rain:         return "雨"
        case .snow:         return "雪"
        case .thunder:      return "雷暴"
        case .unknown:      return "未知"
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var weatherTimer: Timer?
    private var startTime: Date?

    private var currentWeather: WeatherType = .unknown
    private var temperature: String = ""

    private var reminderIntervalMinutes: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "reminderIntervalMinutes")
            return v > 0 ? v : 120
        }
        set { UserDefaults.standard.set(newValue, forKey: "reminderIntervalMinutes") }
    }
    private var reminderIntervalSeconds: TimeInterval { TimeInterval(reminderIntervalMinutes * 60) }

    private let quotes: [(String, String)] = [
        ("喝杯水吧 🌿", "忙碌的你，记得让身体也喘口气。温水已备好，歇一歇再继续。"),
        ("该喝水了 ☕️", "不知不觉专注了这么久，杯子是不是也空了？去接杯温水吧。"),
        ("温柔提醒 💧", "再忙也别忘记喝水。起身走走，让眼睛和身体都放松一下。"),
        ("饮一杯水 🫖", "身体在悄悄呼唤水分——去倒一杯温度刚好的水，慢慢喝完。"),
        ("叮咚 💙", "两小时了。放下手上的事，喝口水，深呼吸，再回来。"),
        ("休息信号 ✨", "一直坐着容易累。起来接杯水，看看窗外，照顾好自己。"),
        ("给身体加点水 🌊", "水是温柔的燃料。喝一杯，让思路和心情都更舒展。"),
        ("小提醒 🫧", "专注很好，但身体也需要关照。去喝杯温水，活动一下肩膀。"),
        ("润一口 ☁️", "温水润喉，也润心。休息两分钟，什么都不想，只慢慢喝一杯水。"),
        ("歇一歇 🍃", "有时候最好的效率，是停下来喝杯水。休息片刻，思路会更清晰。"),
        ("爱护自己 🌸", "喝水这件小事，是对自己最温柔的照顾。记得喝一杯。"),
        ("生命之源 🌊", "每一口水，都在悄悄滋养你的身体。去补一补水吧。"),
        ("自在如风 🍵", "不赶时间，只喝杯水。让节奏慢下来，让心情静下来。"),
        ("温暖片刻 ☀️", "一杯温水入喉，像一个小小的拥抱。去给自己倒一杯吧。"),
        ("关照身心 💚", "眼睛累了要休息，身体渴了要喝水。趁现在，去接杯水。"),
        ("静心一刻 🎐", "暂停一下，喝口水，深呼吸。让忙碌的心也歇一歇。"),
        ("水润时光 🌙", "水是身体最温柔的养分。定时补充，比任何保养都重要。"),
        ("小小的仪式 🕊️", "接一杯水，慢慢喝完——这是属于你的片刻安宁。"),
        ("清凉时刻 ❄️", "再投入工作之前，先喝一杯水。让身体和大脑都醒过来。"),
        ("陪你一会儿 🫂", "不知道说什么，只想提醒你：该喝水了，照顾好自己。"),
        ("慢下来 🌱", "生活不需要一直冲刺。喝杯水，喘口气，再出发。"),
        ("身体在说话 💬", "它说：我想要一杯温水。现在就满足它吧。"),
        ("给细胞加油 ⚡", "每一杯水，都是给全身细胞最好的礼物。"),
        ("中途站 🚃", "工作的旅途中，别忘了在「喝水」这一站停一停。"),
        ("温柔待己 🌷", "如果今天没人提醒你照顾自己，那就我来吧——该喝水了。"),
        ("一杯的时间 ⏳", "只需要一分钟，喝杯水，让身心同步 refresh。"),
        ("澄澈 moment ✨", "水是干净的、透明的。喝一杯，让心情也变得澄澈起来。"),
        ("深呼吸，喝口水 🌬️", "先深呼吸，再喝一口水。简单的动作，却能带来片刻宁静。"),
        ("关心里 ⛲", "源源不断的关心，就像这杯水一样。喝了吧，别让它凉了。"),
        ("元气补给 🎀", "水是最好的元气补给站。不用排队，只需要走到饮水机前。"),
        ("悄悄话 🤫", "偷偷告诉你：你已经很久没喝水了。快去喝一杯，我不告诉别人。"),
        ("停一停 🚥", "人生不是一场冲刺，喝口水再走也不迟。"),
        ("像植物一样 🌱", "植物需要浇水，你也一样。去给自己补充一点能量吧。"),
        ("温柔提醒 🩵", "你的身体比你想的更爱你，别让它渴着了。"),
        ("泡杯茶也好 🫖", "不一定要喝白水，泡杯热茶也一样。重要的是，让自己停下来喝一口。"),
        ("水的声音 🎵", "倒水的声音很好听，喝水的滋味很舒服。去试试吧。"),
        ("治愈一口 🫧", "水能治愈很多事——干渴、疲惫、烦躁。去接一杯吧。"),
        ("长跑中的补给 🏃", "工作是一场长跑，水就是你最好的补给。别忘了喝。"),
        ("最好的习惯 ✅", "定时喝水是件小事，却是你能给自己最好的习惯之一。"),
        ("夜也温柔 🌙", "如果还在熬夜，别忘了手边放杯水。慢慢喝完，再继续。"),
        ("晨间仪式 ☀️", "新的一天，从一杯温水开始。唤醒身体，也唤醒心情。"),
    ]

    // MARK: - 启动

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenuBarIcon()

        // 菜单
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "喝水提醒", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(weatherInfoItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "提醒一次", action: #selector(remindNow), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "重置计时", action: #selector(resetTimer), keyEquivalent: "t"))
        menu.addItem(intervalMenuItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "查看状态", action: #selector(showStatus), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "刷新天气", action: #selector(refreshWeather), keyEquivalent: "w"))
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu

        // 通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            DispatchQueue.main.async {
                self.startTimer()
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    self.sendNotification()
                }
            }
        }

        // 获取天气
        fetchWeather()
        weatherTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.fetchWeather()
        }
    }

    // MARK: - 天气 (ip-api.com + Open-Meteo)

    private func fetchWeather() {
        // Step 1: IP 定位（ipinfo.io，免费 HTTPS，无需 key）
        let geoURL = URL(string: "https://ipinfo.io/json")!

        let geoTask = URLSession.shared.dataTask(with: geoURL) { [weak self] data, _, error in
            guard let self = self else { return }

            let lat: Double
            let lon: Double

            if error == nil, let data = data,
               let geo = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let locStr = geo["loc"] as? String {
                let parts = locStr.split(separator: ",").compactMap { Double($0) }
                lat = parts.first ?? 39.9042
                lon = parts.count > 1 ? parts[1] : 116.4074
            } else {
                // 定位失败 → 默认北京
                lat = 39.9042
                lon = 116.4074
            }

            // Step 2: Open-Meteo 天气
            let wStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=weather_code,temperature_2m&timezone=auto"
            guard let wURL = URL(string: wStr) else { return }

            URLSession.shared.dataTask(with: wURL) { data, _, error in
                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let current = json["current"] as? [String: Any],
                      let code = current["weather_code"] as? Int,
                      let temp = current["temperature_2m"] as? Double else {
                    return
                }

                DispatchQueue.main.async {
                    self.currentWeather = WeatherType.from(wmoCode: code)
                    self.temperature = String(format: "%.0f", temp)
                    self.updateMenuBarIcon()
                    self.updateWeatherInfo()
                }
            }.resume()
        }
        geoTask.resume()
    }

    @objc private func refreshWeather() {
        fetchWeather()
        showInfoAlert(title: "刷新天气", body: "正在获取最新天气 ...")
    }

    private func updateWeatherInfo() {
        guard let menu = statusItem?.menu, menu.items.count > 2 else { return }
        let newItem = weatherInfoItem()
        if let old = menu.item(at: 2) {
            menu.insertItem(newItem, at: 2)
            menu.removeItem(old)
        }
    }

    private func weatherInfoItem() -> NSMenuItem {
        let display: String
        if temperature.isEmpty {
            display = "  ☁️ 获取天气中 ..."
        } else {
            let emoji: String
            switch currentWeather {
            case .clear:        emoji = "☀️"
            case .partlyCloudy: emoji = "⛅"
            case .cloudy:       emoji = "☁️"
            case .fog:          emoji = "🌫️"
            case .rain:         emoji = "🌧️"
            case .snow:         emoji = "❄️"
            case .thunder:      emoji = "⛈️"
            case .unknown:      emoji = "☁️"
            }
            display = "\(emoji) \(currentWeather.displayName) · \(temperature)°C"
        }
        let item = NSMenuItem(title: "  " + display, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    // MARK: - 提醒间隔设置

    private func intervalMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "提醒间隔   \(friendlyInterval) ▸", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        let presets = [30, 60, 90, 120, 180]
        for p in presets {
            let label = p >= 60 ? "\(p / 60) 小时" : "\(p) 分钟"
            let mi = NSMenuItem(title: label + (p == 120 ? " (默认)" : ""),
                                action: #selector(setIntervalPreset(_:)),
                                keyEquivalent: "")
            mi.tag = p
            mi.state = p == reminderIntervalMinutes ? .on : .off
            sub.addItem(mi)
        }
        sub.addItem(NSMenuItem.separator())
        sub.addItem(NSMenuItem(title: "自定义...", action: #selector(promptCustomInterval), keyEquivalent: ""))
        item.submenu = sub
        return item
    }

    @objc private func setIntervalPreset(_ sender: NSMenuItem) {
        let minutes = sender.tag
        guard minutes > 0 else { return }
        reminderIntervalMinutes = minutes
        rebuildMenu()
        startTimer()
        showInfoAlert(title: "间隔已设置", body: "每 \(friendlyInterval) 提醒一次。")
    }

    @objc private func promptCustomInterval() {
        let alert = NSAlert()
        alert.messageText = "自定义提醒间隔"
        alert.informativeText = "请输入间隔分钟数（10 ~ 480）："
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")

        let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: 100, height: 24))
        tf.placeholderString = "\(reminderIntervalMinutes)"
        tf.stringValue = "\(reminderIntervalMinutes)"
        alert.accessoryView = tf

        let resp = alert.runModal()
        guard resp == .alertFirstButtonReturn else { return }

        let minutes = Int(tf.stringValue.trimmingCharacters(in: .whitespaces)) ?? 0
        guard minutes >= 10, minutes <= 480 else {
            showInfoAlert(title: "无效输入", body: "请输入 10 ~ 480 之间的整数。")
            return
        }

        reminderIntervalMinutes = minutes
        rebuildMenu()
        startTimer()
        showInfoAlert(title: "间隔已设置", body: "每 \(friendlyInterval) 提醒一次。")
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "喝水提醒", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(weatherInfoItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "提醒一次", action: #selector(remindNow), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "重置计时", action: #selector(resetTimer), keyEquivalent: "t"))
        menu.addItem(intervalMenuItem())
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "查看状态", action: #selector(showStatus), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "刷新天气", action: #selector(refreshWeather), keyEquivalent: "w"))
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    // MARK: - 图标（SF Symbols）

    private func updateMenuBarIcon() {
        let name: String
        switch currentWeather {
        case .clear:        name = "drop.fill"
        case .partlyCloudy: name = "cloud.sun.fill"
        case .cloudy:       name = "cloud.fill"
        case .fog:          name = "cloud.fog.fill"
        case .rain:         name = "cloud.rain.fill"
        case .snow:         name = "cloud.snow.fill"
        case .thunder:      name = "cloud.bolt.fill"
        case .unknown:      name = "drop.fill"
        }

        let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)
            ?? drawFallbackIcon()
        img.isTemplate = true

        if let button = statusItem?.button {
            button.image = img
        }
    }

    private func drawFallbackIcon() -> NSImage {
        let s: CGFloat = 18
        return NSImage(size: NSSize(width: s, height: s), flipped: false) { _ in
            let cx = s / 2, cy = s / 2 + 0.5
            let r = s * 0.35
            let path = NSBezierPath()
            let topY = cy - r * 0.75, botY = cy + r * 0.55
            path.move(to: NSPoint(x: cx, y: topY))
            path.curve(to: NSPoint(x: cx + r * 0.75, y: botY - r * 0.15),
                       controlPoint1: NSPoint(x: cx, y: topY + r * 0.4),
                       controlPoint2: NSPoint(x: cx + r * 0.75, y: topY + r * 0.4))
            path.curve(to: NSPoint(x: cx, y: botY),
                       controlPoint1: NSPoint(x: cx + r * 0.85, y: botY - r * 0.1),
                       controlPoint2: NSPoint(x: cx + r * 0.3, y: botY + r * 0.05))
            path.curve(to: NSPoint(x: cx - r * 0.75, y: botY - r * 0.15),
                       controlPoint1: NSPoint(x: cx - r * 0.3, y: botY + r * 0.05),
                       controlPoint2: NSPoint(x: cx - r * 0.85, y: botY - r * 0.1))
            path.curve(to: NSPoint(x: cx, y: topY),
                       controlPoint1: NSPoint(x: cx - r * 0.75, y: topY + r * 0.4),
                       controlPoint2: NSPoint(x: cx, y: topY + r * 0.4))
            path.close()
            NSColor.black.withAlphaComponent(0.85).setFill()
            path.fill()
            return true
        }
    }

    // MARK: - 计时器

    private func startTimer() {
        timer?.invalidate()
        startTime = Date()
        timer = Timer.scheduledTimer(timeInterval: reminderIntervalSeconds, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    }

    @objc private func timerFired() {
        sendNotification()
    }

    // MARK: - 通知

    private func sendNotification() {
        let (title, body) = nextMessage()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showAlertFallback(title: title, body: body)
                }
            }
        }
    }

    private func nextMessage() -> (String, String) {
        quotes.randomElement() ?? ("喝杯水吧 💧", "该喝水了，去倒一杯温水吧。")
    }

    private func showAlertFallback(title: String, body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }

    // MARK: - 菜单操作

    @objc private func remindNow() {
        sendNotification()
        startTimer()
    }

    @objc private func resetTimer() {
        startTimer()
        showInfoAlert(title: "计时器已重置", body: "从现在开始，每 \(friendlyInterval) 提醒一次。")
    }

    private var friendlyInterval: String {
        let m = reminderIntervalMinutes
        if m >= 60 { return "\(m / 60) 小时" + (m % 60 > 0 ? " \(m % 60) 分钟" : "") }
        return "\(m) 分钟"
    }

    @objc private func showStatus() {
        let elapsed: String
        if let start = startTime {
            let diff = Int(-start.timeIntervalSinceNow)
            let h = diff / 3600
            let m = (diff % 3600) / 60
            if h > 0 {
                elapsed = "距上次提醒已过 \(h) 小时 \(m) 分钟"
            } else {
                elapsed = "距上次提醒已过 \(m) 分钟"
            }
        } else {
            elapsed = "尚未提醒"
        }
        showInfoAlert(title: "喝水状态", body: "\(elapsed)\n每 \(friendlyInterval) 自动提醒 ✦")
    }

    private func showInfoAlert(title: String, body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - 启动

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
