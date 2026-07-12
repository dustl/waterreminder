import Cocoa
import UserNotifications

// MARK: - 自定义下拉提醒面板

class ReminderPanel: NSPanel {
    private var dismissTimer: Timer?
    private var onDismiss: (() -> Void)?
    private var onDrink: ((Double) -> Void)?
    private var onSnooze: ((Int) -> Void)?
    private var retainSelf: ReminderPanel?

    private let panelWidth: CGFloat = 400
    private let panelHeight: CGFloat = 158

    init(
        title: String,
        body: String,
        onDismiss: @escaping () -> Void,
        onDrink: @escaping (Double) -> Void,
        onSnooze: @escaping (Int) -> Void
    ) {
        self.onDismiss = onDismiss
        self.onDrink = onDrink
        self.onSnooze = onSnooze

        guard let screen = NSScreen.main else {
            super.init(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: true)
            return
        }

        let sf = screen.frame
        let vf = screen.visibleFrame
        let menuBarHeight = sf.height - (vf.origin.y + vf.height)
        let padding: CGFloat = 10
        let x = vf.origin.x + (vf.width - panelWidth) / 2
        let visibleY = sf.height - menuBarHeight - panelHeight - padding

        // 从顶部缓缓弹出：初始位置在顶部（高度为0），向下展开
        super.init(
            contentRect: NSRect(x: x, y: visibleY + panelHeight, width: panelWidth, height: 0),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces]
        self.isMovable = false
        self.ignoresMouseEvents = false

        setupContent(title: title, body: body)

        // 从顶部缓缓弹出：高度从 0 展开到 panelHeight
        orderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.45
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().setFrame(
                NSRect(x: x, y: visibleY, width: panelWidth, height: panelHeight),
                display: true
            )
        }

        // 自动消失
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
            self?.hide()
        }

        retainSelf = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var canBecomeKey: Bool { true }

    private func setupContent(title: String, body: String) {
        // 容器 view（负责圆角 + 阴影）
        let container = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        container.wantsLayer = true
        container.layer?.cornerRadius = 16
        container.layer?.masksToBounds = true
        contentView = container

        // 毛玻璃背景
        let blur = NSVisualEffectView(frame: container.bounds)
        blur.autoresizingMask = [.width, .height]
        blur.blendingMode = .withinWindow
        blur.state = .active
        blur.material = .popover
        container.addSubview(blur)

        // 标题
        let tl = NSTextField(labelWithString: title)
        tl.font = .systemFont(ofSize: 15, weight: .semibold)
        tl.textColor = .labelColor
        tl.frame = NSRect(x: 20, y: panelHeight - 42, width: panelWidth - 80, height: 22)
        container.addSubview(tl)

        // 关闭按钮（无边框）
        let cb = NSButton(frame: NSRect(x: panelWidth - 38, y: panelHeight - 34, width: 22, height: 22))
        cb.bezelStyle = .inline
        cb.isBordered = false
        cb.title = "✕"
        cb.font = .systemFont(ofSize: 13, weight: .medium)
        cb.contentTintColor = .secondaryLabelColor
        cb.target = self
        cb.action = #selector(tapClose)
        container.addSubview(cb)

        // 正文
        let bl = NSTextField(wrappingLabelWithString: body)
        bl.font = .systemFont(ofSize: 13)
        bl.textColor = .secondaryLabelColor
        bl.frame = NSRect(x: 20, y: 72, width: panelWidth - 40, height: 40)
        container.addSubview(bl)

        // 分量按钮
        let amounts: [Double] = [50, 100, 250, 500]
        let btnW: CGFloat = 72, btnH: CGFloat = 30, gap: CGFloat = 6
        let totalW = CGFloat(amounts.count) * btnW + CGFloat(amounts.count - 1) * gap
        let startX = (panelWidth - totalW) / 2

        for (i, a) in amounts.enumerated() {
            let b = NSButton(frame: NSRect(
                x: startX + CGFloat(i) * (btnW + gap),
                y: 14, width: btnW, height: btnH
            ))
            b.bezelStyle = .rounded
            b.title = "\(Int(a))ml"
            b.font = .systemFont(ofSize: 12, weight: .medium)
            b.target = self
            b.action = #selector(tapDrink(_:))
            b.tag = Int(a)
            container.addSubview(b)
        }

        // 稍后提醒按钮
        let sb = NSButton(frame: NSRect(
            x: startX + CGFloat(amounts.count) * (btnW + gap),
            y: 14, width: 48, height: btnH
        ))
        sb.bezelStyle = .rounded
        sb.title = "⏰"
        sb.font = .systemFont(ofSize: 14)
        sb.target = self
        sb.action = #selector(tapSnooze)
        container.addSubview(sb)
    }

    @objc private func tapDrink(_ sender: NSButton) {
        onDrink?(Double(sender.tag))
        hide()
    }

    @objc private func tapSnooze() {
        onSnooze?(10)
        hide()
    }

    @objc private func tapClose() {
        onDismiss?()
        hide()
    }

    @objc fileprivate func hide() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        // 收起动画：高度归零，向上折叠
        let endY = self.frame.origin.y + self.frame.height
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().setFrame(
                NSRect(x: self.frame.origin.x, y: endY, width: self.frame.width, height: 0),
                display: true
            )
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
            self?.retainSelf = nil
        }
    }
}

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

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var weatherTimer: Timer?
    private var startTime: Date?
    private var isSnoozing = false
    private var hasNotifiedGoalToday = false
    private var currentPanel: ReminderPanel?
    private var toastPanel: NSPanel?

    // MARK: - 天气

    private var currentWeather: WeatherType = .unknown
    private var temperature: String = ""

    // MARK: - 饮水记录

    private var todayIntake: Double {
        get { UserDefaults.standard.double(forKey: "todayIntake") }
        set { UserDefaults.standard.set(newValue, forKey: "todayIntake") }
    }
    private var drinkLogDate: String {
        get { UserDefaults.standard.string(forKey: "drinkLogDate") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "drinkLogDate") }
    }
    private var dailyGoal: Double {
        get {
            let v = UserDefaults.standard.double(forKey: "dailyGoal")
            return v > 0 ? v : 2000
        }
        set { UserDefaults.standard.set(newValue, forKey: "dailyGoal") }
    }

    // MARK: - 提醒间隔

    private var reminderIntervalMinutes: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "reminderIntervalMinutes")
            return v > 0 ? v : 120
        }
        set { UserDefaults.standard.set(newValue, forKey: "reminderIntervalMinutes") }
    }

    /// 实际生效的间隔（考虑高温自动调整）
    private var effectiveIntervalMinutes: Int {
        if let tempVal = Double(temperature), tempVal >= 30 {
            return max(15, reminderIntervalMinutes / 2)
        }
        return reminderIntervalMinutes
    }

    private var effectiveIntervalSeconds: TimeInterval {
        TimeInterval(effectiveIntervalMinutes * 60)
    }

    // MARK: - 工作时段

    private var workingHoursEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: "workingHoursEnabled") != nil
                ? UserDefaults.standard.bool(forKey: "workingHoursEnabled") : true
        }
        set { UserDefaults.standard.set(newValue, forKey: "workingHoursEnabled") }
    }
    private var workStartHour: Int {
        get {
            UserDefaults.standard.object(forKey: "workStartHour") != nil
                ? UserDefaults.standard.integer(forKey: "workStartHour") : 9
        }
        set { UserDefaults.standard.set(newValue, forKey: "workStartHour") }
    }
    private var workEndHour: Int {
        get {
            UserDefaults.standard.object(forKey: "workEndHour") != nil
                ? UserDefaults.standard.integer(forKey: "workEndHour") : 22
        }
        set { UserDefaults.standard.set(newValue, forKey: "workEndHour") }
    }

    // MARK: - 提醒文案

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
        // 加载缓存的天气
        loadCachedWeather()

        // 校验并重置每日饮水记录
        checkAndResetDailyLog()

        // 状态栏
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenuBarIcon()
        buildMenu()

        // 启动计时器
        startTimer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.sendNotification()
        }

        // 天气
        fetchWeather()
        weatherTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.fetchWeather()
        }

        // 睡眠/唤醒监听
        setupSleepWakeHandling()
    }

    // MARK: - 每日记录

    private func checkAndResetDailyLog() {
        let today = dateString()
        if drinkLogDate != today {
            todayIntake = 0
            drinkLogDate = today
            hasNotifiedGoalToday = false
        }
    }

    private func dateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    // MARK: - 交互式通知

    // MARK: - 饮水记录

    private func logDrink(amount: Double) {
        checkAndResetDailyLog()
        todayIntake += amount
        buildMenu()

        let pct = min(Int(todayIntake / dailyGoal * 100), 100)
        print("💧 Drank \(Int(todayIntake))ml / \(Int(dailyGoal))ml (\(pct)%)")

        if todayIntake >= dailyGoal, !hasNotifiedGoalToday {
            hasNotifiedGoalToday = true
            currentPanel?.hide()
            currentPanel = ReminderPanel(
                title: "🎉 喝水目标达成！",
                body: "今日已喝 \(Int(todayIntake))ml，太棒了！继续保持 💪",
                onDismiss: {},
                onDrink: { [weak self] amount in
                    guard let self = self else { return }
                    self.logDrink(amount: amount)
                    self.startTimer()
                    self.showDrinkConfirmationToast(amount: amount)
                },
                onSnooze: { [weak self] minutes in
                    self?.snoozeReminder(minutes: minutes)
                }
            )
        }
    }

    @objc private func logDrink50() {
        logDrink(amount: 50)
        startTimer()
        showAlert(title: "已记录 👍", body: "+50ml · 今日共 \(Int(todayIntake))ml / \(Int(dailyGoal))ml")
    }

    @objc private func logDrink100() {
        logDrink(amount: 100)
        startTimer()
        showAlert(title: "已记录 👍", body: "+100ml · 今日共 \(Int(todayIntake))ml / \(Int(dailyGoal))ml")
    }

    @objc private func logDrink250() {
        logDrink(amount: 250)
        startTimer()
        showAlert(title: "已记录 👍", body: "+250ml · 今日共 \(Int(todayIntake))ml / \(Int(dailyGoal))ml")
    }

    @objc private func logDrink500() {
        logDrink(amount: 500)
        startTimer()
        showAlert(title: "已记录 👍", body: "+500ml · 今日共 \(Int(todayIntake))ml / \(Int(dailyGoal))ml")
    }

    // MARK: - 菜单

    private var todayProgressBar: String {
        let pct = min(Int(todayIntake / dailyGoal * 100), 100)
        if pct >= 100 { return "🎉 \(Int(todayIntake))ml ✓" }
        let filled = pct / 10
        return "\(Int(todayIntake))/\(Int(dailyGoal))ml " + String(repeating: "█", count: filled)
            + String(repeating: "░", count: 10 - filled)
    }

    private func buildMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "喝水提醒", action: nil, keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // 今日饮水进度
        let progressTitle = "  💧 \(todayProgressBar)"
        let progressItem = NSMenuItem(title: progressTitle, action: nil, keyEquivalent: "")
        progressItem.isEnabled = false
        menu.addItem(progressItem)

        // 快速记录
        menu.addItem(NSMenuItem(title: "喝了一小口 (50ml)", action: #selector(logDrink50), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "喝了一小杯 (100ml)", action: #selector(logDrink100), keyEquivalent: "S"))
        menu.addItem(NSMenuItem(title: "喝了一杯水 (250ml)", action: #selector(logDrink250), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "喝了一大杯 (500ml)", action: #selector(logDrink500), keyEquivalent: "D"))
        menu.addItem(goalMenuItem())

        menu.addItem(NSMenuItem.separator())

        // 天气信息
        menu.addItem(weatherInfoItem())

        // 高温模式提示
        if let tempVal = Double(temperature), tempVal >= 30 {
            let hotItem = NSMenuItem(title: "  🔥 高温模式：间隔缩短至 \(effectiveIntervalMinutes) 分钟", action: nil, keyEquivalent: "")
            hotItem.isEnabled = false
            menu.addItem(hotItem)
        }

        menu.addItem(NSMenuItem.separator())

        // 提醒操作
        menu.addItem(NSMenuItem(title: "提醒一次", action: #selector(remindNow), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "重置计时", action: #selector(resetTimer), keyEquivalent: "t"))
        menu.addItem(intervalMenuItem())
        menu.addItem(workingHoursMenuItem())

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "查看状态", action: #selector(showStatus), keyEquivalent: "s"))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "刷新天气", action: #selector(refreshWeather), keyEquivalent: "w"))
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - 每日目标子菜单

    private func goalMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "每日目标  \(Int(dailyGoal))ml ▸", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        let presets: [Double] = [1000, 1500, 2000, 2500, 3000]
        for p in presets {
            let mi = NSMenuItem(
                title: "\(Int(p))ml" + (p == 2000 ? " (推荐)" : ""),
                action: #selector(setGoalPreset(_:)),
                keyEquivalent: ""
            )
            mi.tag = Int(p)
            mi.state = p == dailyGoal ? .on : .off
            sub.addItem(mi)
        }
        sub.addItem(NSMenuItem.separator())
        sub.addItem(NSMenuItem(title: "自定义...", action: #selector(promptCustomGoal), keyEquivalent: ""))
        item.submenu = sub
        return item
    }

    @objc private func setGoalPreset(_ sender: NSMenuItem) {
        dailyGoal = Double(sender.tag)
        buildMenu()
    }

    @objc private func promptCustomGoal() {
        let alert = NSAlert()
        alert.messageText = "自定义每日目标"
        alert.informativeText = "请输入每日目标饮水量（毫升）："
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")

        let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: 100, height: 24))
        tf.placeholderString = "\(Int(dailyGoal))"
        tf.stringValue = "\(Int(dailyGoal))"
        alert.accessoryView = tf

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let val = Int(tf.stringValue.trimmingCharacters(in: .whitespaces)) ?? 0
        guard val >= 500, val <= 10000 else {
            showAlert(title: "无效输入", body: "请输入 500 ~ 10000 之间的整数。")
            return
        }
        dailyGoal = Double(val)
        buildMenu()
    }

    // MARK: - 工作时段子菜单

    private func workingHoursMenuItem() -> NSMenuItem {
        let status: String
        if workingHoursEnabled {
            status = "\(workStartHour):00-\(workEndHour):00"
        } else {
            status = "全天"
        }
        let item = NSMenuItem(title: "工作时段  \(status) ▸", action: nil, keyEquivalent: "")
        let sub = NSMenu()

        let toggleTitle = workingHoursEnabled ? "关闭时段限制" : "启用时段限制"
        sub.addItem(NSMenuItem(title: toggleTitle, action: #selector(toggleWorkingHours), keyEquivalent: ""))
        sub.addItem(NSMenuItem.separator())

        let presets: [(Int, Int)] = [(9, 22), (8, 22), (9, 23), (10, 22)]
        let labels = ["9:00 - 22:00", "8:00 - 22:00", "9:00 - 23:00", "10:00 - 22:00"]
        for (i, (s, e)) in presets.enumerated() {
            let mi = NSMenuItem(title: labels[i], action: #selector(setWorkHoursPreset(_:)), keyEquivalent: "")
            mi.tag = s * 100 + e
            mi.state = (workingHoursEnabled && s == workStartHour && e == workEndHour) ? .on : .off
            sub.addItem(mi)
        }
        sub.addItem(NSMenuItem.separator())
        sub.addItem(NSMenuItem(title: "自定义...", action: #selector(promptCustomWorkHours), keyEquivalent: ""))
        item.submenu = sub
        return item
    }

    @objc private func toggleWorkingHours() {
        workingHoursEnabled = !workingHoursEnabled
        buildMenu()
        if workingHoursEnabled { rescheduleIfOutsideHours() }
    }

    @objc private func setWorkHoursPreset(_ sender: NSMenuItem) {
        workStartHour = sender.tag / 100
        workEndHour = sender.tag % 100
        workingHoursEnabled = true
        buildMenu()
        rescheduleIfOutsideHours()
    }

    @objc private func promptCustomWorkHours() {
        let alert = NSAlert()
        alert.messageText = "自定义工作时段"
        alert.informativeText = "请输入起始和结束小时（0~23，例如 9 和 22）："
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")

        let view = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 40))
        let startField = NSTextField(frame: NSRect(x: 0, y: 20, width: 80, height: 24))
        startField.placeholderString = "起始"
        startField.stringValue = "\(workStartHour)"
        let endField = NSTextField(frame: NSRect(x: 140, y: 20, width: 80, height: 24))
        endField.placeholderString = "结束"
        endField.stringValue = "\(workEndHour)"
        view.addSubview(startField)
        view.addSubview(endField)
        alert.accessoryView = view

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let s = Int(startField.stringValue.trimmingCharacters(in: .whitespaces)) ?? -1
        let e = Int(endField.stringValue.trimmingCharacters(in: .whitespaces)) ?? -1
        guard s >= 0, s <= 23, e >= 0, e <= 23, s < e else {
            showAlert(title: "无效输入", body: "请输入 0~23 之间的整数，且起始 < 结束。")
            return
        }
        workStartHour = s
        workEndHour = e
        workingHoursEnabled = true
        buildMenu()
        rescheduleIfOutsideHours()
    }

    private func rescheduleIfOutsideHours() {
        guard workingHoursEnabled, let nextStart = nextWorkStartDate() else { return }
        let interval = nextStart.timeIntervalSinceNow
        guard interval > 0 else { return }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.sendNotification()
            self.startTimer()
        }
    }

    private func isWithinWorkingHours() -> Bool {
        guard workingHoursEnabled else { return true }
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= workStartHour && hour < workEndHour
    }

    private func nextWorkStartDate() -> Date? {
        guard workingHoursEnabled else { return nil }
        let now = Date()
        let cal = Calendar.current
        let hour = cal.component(.hour, from: now)

        if hour < workStartHour {
            // 今天的起始时间还没到
            var comps = cal.dateComponents([.year, .month, .day], from: now)
            comps.hour = workStartHour
            comps.minute = 0
            comps.second = 0
            return cal.date(from: comps)
        } else if hour >= workEndHour {
            // 已经过了结束时间 → 明天
            var comps = cal.dateComponents([.year, .month, .day], from: now)
            guard let tomorrow = comps.day.map({ $0 + 1 }) else { return nil }
            comps.day = tomorrow
            comps.hour = workStartHour
            comps.minute = 0
            comps.second = 0
            return cal.date(from: comps)
        }
        return nil // 正在工作时段内
    }

    // MARK: - 天气 (ip-api.com + Open-Meteo)

    private func loadCachedWeather() {
        if UserDefaults.standard.object(forKey: "cachedWeatherCode") != nil {
            let code = UserDefaults.standard.integer(forKey: "cachedWeatherCode")
            currentWeather = WeatherType.from(wmoCode: code)
        }
        temperature = UserDefaults.standard.string(forKey: "cachedTemperature") ?? ""
    }

    private func cacheWeather(code: Int, temp: String) {
        UserDefaults.standard.set(code, forKey: "cachedWeatherCode")
        UserDefaults.standard.set(temp, forKey: "cachedTemperature")
    }

    private func fetchWeather() {
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
                lat = 39.9042
                lon = 116.4074
            }

            let wStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=weather_code,temperature_2m&timezone=auto"
            guard let wURL = URL(string: wStr) else { return }

            URLSession.shared.dataTask(with: wURL) { data, _, error in
                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let current = json["current"] as? [String: Any],
                      let code = current["weather_code"] as? Int,
                      let temp = current["temperature_2m"] as? Double else { return }

                DispatchQueue.main.async {
                    self.currentWeather = WeatherType.from(wmoCode: code)
                    let tempStr = String(format: "%.0f", temp)
                    self.temperature = tempStr
                    self.cacheWeather(code: code, temp: tempStr)
                    self.updateMenuBarIcon()
                    // 天气变化了 → 重新建菜单（高温模式可能开关）
                    self.buildMenu()
                }
            }.resume()
        }
        geoTask.resume()
    }

    @objc private func refreshWeather() {
        fetchWeather()
        showAlert(title: "刷新天气", body: "正在获取最新天气 ...")
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
        isSnoozing = false
        startTime = Date()
        timer = Timer.scheduledTimer(
            timeInterval: effectiveIntervalSeconds,
            target: self,
            selector: #selector(timerFired),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func timerFired() {
        if isWithinWorkingHours() {
            sendNotification()
        } else {
            rescheduleIfOutsideHours()
        }
    }

    // MARK: - 提醒

    private func sendNotification() {
        startTime = Date()
        let (title, body) = nextMessage()
        NSSound(named: "Pop")?.play()

        currentPanel?.hide()
        currentPanel = ReminderPanel(
            title: title,
            body: body,
            onDismiss: {},
            onDrink: { [weak self] amount in
                guard let self = self else { return }
                self.logDrink(amount: amount)
                self.startTimer()
                self.showDrinkConfirmationToast(amount: amount)
            },
            onSnooze: { [weak self] minutes in
                self?.snoozeReminder(minutes: minutes)
            }
        )
    }

    // MARK: - 正反馈 Toast

    private func drinkConfirmationMessage() -> String {
        let pct = Int(todayIntake / dailyGoal * 100)

        if pct >= 100 {
            return ["🎉 今天的目标完成了，真为你高兴！",
                    "🌟 太棒了，你好好照顾了自己呢。",
                    "🏆 今日饮水达标，你很棒！"].randomElement()!
        }
        return ["🌿 每一口水，都在悄悄滋养你。",
                "🌸 嗯，就这样慢慢照顾自己。",
                "💧 水是最好的礼物，你值得。",
                "✨ 小小的坚持，会有大大的不同。",
                "🍃 身体会感谢你的每一杯水。",
                "☀️ 喝下去的不只是水，是一份温柔。",
                "🌊 好习惯，就是这样一点点养成的。",
                "💙 你在好好爱自己，看得见。"].randomElement()!
    }

    private func showDrinkConfirmationToast(amount: Double) {
        let message = drinkConfirmationMessage()
        showToast(message: message)
    }

    private func showToast(message: String) {
        toastPanel?.orderOut(nil)

        let width: CGFloat = 280
        let height: CGFloat = 42

        guard let screen = NSScreen.main else { return }
        let sf = screen.frame
        let vf = screen.visibleFrame
        let menuBarHeight = sf.height - (vf.origin.y + vf.height)
        let x = (sf.width - width) / 2
        let visibleY = sf.height - menuBarHeight - height - 10

        let panel = NSPanel(
            contentRect: NSRect(x: x, y: visibleY + height, width: width, height: 0),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating + 1
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.ignoresMouseEvents = true

        // 容器 view（圆角 + 阴影）
        let container = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        container.wantsLayer = true
        container.layer?.cornerRadius = 12
        container.layer?.masksToBounds = true
        panel.contentView = container

        let blur = NSVisualEffectView(frame: container.bounds)
        blur.autoresizingMask = [.width, .height]
        blur.blendingMode = .withinWindow
        blur.state = .active
        blur.material = .popover
        container.addSubview(blur)

        let label = NSTextField(labelWithString: message)
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .center
        label.frame = NSRect(x: 16, y: 10, width: width - 32, height: 22)
        container.addSubview(label)

        toastPanel = panel
        panel.orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(
                NSRect(x: x, y: visibleY, width: width, height: height),
                display: true
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().setFrame(
                    NSRect(x: x, y: visibleY + height, width: width, height: 0),
                    display: true
                )
            } completionHandler: {
                panel.orderOut(nil)
                if self?.toastPanel === panel { self?.toastPanel = nil }
            }
        }
    }

    private func nextMessage() -> (String, String) {
        quotes.randomElement() ?? ("喝杯水吧 💧", "该喝水了，去倒一杯温水吧。")
    }

    private func snoozeReminder(minutes: Int) {
        isSnoozing = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.isSnoozing = false
            self.sendNotification()
            self.startTimer()
        }
    }

    // MARK: - 睡眠/唤醒

    private func setupSleepWakeHandling() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(onWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func onWake() {
        guard let start = startTime, !isSnoozing else { return }
        let elapsed = -start.timeIntervalSinceNow

        // 如果睡眠时间超过了 1.5 倍间隔，认为错过了提醒
        if elapsed >= effectiveIntervalSeconds * 1.5 {
            if isWithinWorkingHours() {
                print("💤 Woke from sleep, missed reminder (elapsed: \(Int(elapsed/60))min)")
                sendNotification()
            }
            startTimer()
        }
    }

    // MARK: - 菜单操作

    @objc private func remindNow() {
        isSnoozing = false
        sendNotification()
        startTimer()
    }

    @objc private func resetTimer() {
        startTimer()
        showAlert(title: "计时器已重置", body: "从现在开始，每 \(friendlyInterval) 提醒一次。")
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

        var body = "\(elapsed)\n"
        body += "今日饮水  \(Int(todayIntake)) / \(Int(dailyGoal))ml"

        let pct = min(Int(todayIntake / dailyGoal * 100), 100)
        if pct >= 100 {
            body += " 🎉 目标达成！"
        } else {
            body += " (\(pct)%)"
        }

        body += "\n"

        if let tempVal = Double(temperature), tempVal >= 30 {
            body += "🔥 高温模式：间隔缩短至 \(effectiveIntervalMinutes) 分钟\n"
        } else {
            body += "每 \(friendlyInterval) 自动提醒 ✦\n"
        }

        if workingHoursEnabled {
            body += "工作时段：\(workStartHour):00 - \(workEndHour):00"
        } else {
            body += "全天提醒"
        }

        showAlert(title: "喝水状态", body: body)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - 提醒间隔设置

    private func intervalMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "提醒间隔  \(friendlyInterval) ▸", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        let presets = [30, 60, 90, 120, 180]
        for p in presets {
            let label = p >= 60 ? "\(p / 60) 小时" : "\(p) 分钟"
            let mi = NSMenuItem(
                title: label + (p == 120 ? " (默认)" : ""),
                action: #selector(setIntervalPreset(_:)),
                keyEquivalent: ""
            )
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
        buildMenu()
        startTimer()
        showAlert(title: "间隔已设置", body: "每 \(friendlyInterval) 提醒一次。")
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
            showAlert(title: "无效输入", body: "请输入 10 ~ 480 之间的整数。")
            return
        }

        reminderIntervalMinutes = minutes
        buildMenu()
        startTimer()
        showAlert(title: "间隔已设置", body: "每 \(friendlyInterval) 提醒一次。")
    }

    // MARK: - 通用弹窗

    private func showAlert(title: String, body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }

}

// MARK: - 启动

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
