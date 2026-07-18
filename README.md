WaterReminder — 喝水提醒
一个温柔优雅的 macOS 菜单栏喝水提醒工具，支持天气图标、饮水记录、日历热力图和 iCloud 同步。

功能
⏰ 定时提醒 — 默认每 2 小时提醒一次，支持自定义 10–480 分钟
💧 饮水记录 — 菜单栏快速记录 50/100/250/500ml，或从提醒面板选择分量
🎯 每日目标 — 菜单栏显示渐变彩色进度条，实时追踪完成百分比
📊 日历热力图 — 月视图，颜色标记每日完成度，支持月份切换和统计（日均、达标天数）
📋 日报/周报 — 每晚 21:00 自动弹出报告，周日展示本周汇总
☁️ iCloud 同步 — 饮水记录和设置通过 iCloud 跨设备自动同步
🌤️ 天气图标 — 菜单栏图标随当地天气自动变化（SF Symbols）
🫧 温柔文案 — 41 条提醒语 + 20 条日常鼓励 + 12 条达标庆祝语
🪟 滑动面板 — 毛玻璃效果提醒面板、饮水确认浮层、状态面板，均从顶部优雅滑入
🔘 面板交互 — 提醒面板上直接选择 50/100/250/500ml 或稍后提醒
⏳ 工作时段 — 仅在设定时段内提醒（默认 9:00–22:00），支持预设和自定义
💤 唤醒感知 — Mac 从睡眠唤醒后检测并补发错过的提醒
🌍 自动天气 — IP 定位获取坐标，Open-Meteo 免费天气接口
🎨 精致设计 — 毛玻璃效果（NSVisualEffectView）、圆角面板、自适应深色/浅色模式
💾 持久化存储 — 所有偏好设置自动保存在 UserDefaults，同时同步至 iCloud
🚀 无 Dock 图标 — 纯菜单栏应用（LSUIElement），不干扰工作
快速开始
bash

# 直接运行
open /Applications/water/waterreminder/WaterReminder.app
从源码编译
bash

cd /Applications/water/waterreminder
swiftc -o WaterReminder.app/Contents/MacOS/WaterReminder main.swift \
  -framework Cocoa -framework UserNotifications
open WaterReminder.app
使用方法
点击菜单栏水杯图标：


喝水提醒
---
💧 1200 / 2000ml  60%         ← 渐变进度条（蓝色<100% / 绿色=100%）
喝了一小口 (50ml)    ⌘S        ← 快速记录，带鼓励浮层
喝了一小杯 (100ml)   ⌘⇧S
喝了一杯水 (250ml)   ⌘D
喝了一大杯 (500ml)   ⌘⇧D
每日目标  2000ml ▸             ← 设置每日目标
---
⛅ 多云 · 24°C               ← 实时天气
---
提醒一次          ⌘R            ← 立即弹出提醒面板
重置计时          ⌘T            ← 重置倒计时
提醒间隔    2 小时 ▸             ← 设置提醒频率
工作时段    9:00-22:00 ▸         ← 设置工作时段
---
查看状态          ⌘V            ← 滑动面板显示详细状态
---
📊 喝水记录 ▸                   ← 最近 7 天进度 + 日历热力图
刷新天气          ⌘W            ← 手动刷新天气
退出              ⌘Q
菜单项说明
菜单项	快捷键	说明
喝了一小口 (50ml)	⌘S	记录 50ml，弹出鼓励浮层
喝了一小杯 (100ml)	⌘⇧S	记录 100ml，弹出鼓励浮层
喝了一杯水 (250ml)	⌘D	记录 250ml，弹出鼓励浮层
喝了一大杯 (500ml)	⌘⇧D	记录 500ml，弹出鼓励浮层
每日目标	—	设置每日饮水目标（1000–3000ml 预设或 500–10000ml 自定义）
提醒一次	⌘R	立即弹出提醒面板
重置计时	⌘T	重置倒计时
提醒间隔	—	设置提醒频率（30/60/90/120/180 分钟预设或 10–480 自定义）
工作时段	—	设置工作时段或关闭（全天提醒）
查看状态	⌘V	滑动面板显示距上次提醒时间、饮水量、间隔、时段
喝水记录	—	子菜单显示最近 7 天带彩色进度条 + 点击进入日历热力图
刷新天气	⌘W	手动更新天气数据
退出	⌘Q	退出应用
提醒面板
提醒触发时，毛玻璃面板从屏幕顶部滑入：

随机显示 1 条提醒文案（共 41 条）
50ml · 100ml · 250ml · 500ml 四个按钮 — 点击后记录并弹出鼓励浮层
⏰ 稍后提醒 — 推迟 10 分钟
✕ 关闭 — 取消本次提醒
8 秒无操作自动收起
每次喝水后弹出温柔鼓励语句，如"每一口水，都在悄悄滋养你"或"你在好好爱自己，看得见"。

日历热力图
点击「喝水记录 → 查看月历…」打开日历面板：

月视图 数字格，按每日完成百分比着色
← → 按钮 切换月份
统计行 日均饮水量 + 达标天数
图例 0% 灰 → 25% 浅蓝 → 50% 中蓝 → 75% 蓝 → 100% 深蓝 → >100% 绿
悬停提示 鼠标悬停任意日期显示具体毫升数
每日/每周报告
每天 21:00 自动弹出：

今日饮水量 vs 目标
与昨日对比
周日额外显示本周日均和总饮水量
iCloud 同步
饮水历史记录和设置通过 NSUbiquitousKeyValueStore 自动同步
使用当前 iCloud 账户，无需额外登录
外部变更自动检测合并（按天取较大值）
工作原理
定位 — 启动时通过 ipinfo.io 获取 IP 地理位置 → 经纬度
天气 — 调用 Open-Meteo 免费天气 API，缓存到 UserDefaults，每小时刷新
图标 — 菜单栏图标根据天气切换对应 SF Symbol
计时 — 按设定间隔倒计时（遵守工作时段），到点时弹出自定义面板
面板 — 无边框 NSPanel + NSVisualEffectView（popover 材质），从顶部 ease-out 滑入
浮层 — 喝水后小面板显示鼓励语，2 秒自动收起
状态 — 同样滑动画风，显示距上次提醒时间、饮水量、间隔、工作时段
记录 — 饮水历史以 [日期: 毫升] 字典存入 UserDefaults
午夜重置 — 00:00 保存当天数据到历史记录，重置计数器
iCloud — 通过 NSUbiquitousKeyValueStore 跨设备同步历史 + 设置
日历 — HistoryPanel 读取 drinkHistory，渲染带颜色的月网格
设计细节
毛玻璃: NSVisualEffectView .popover 材质，active 状态
圆角: 容器 16px，masksToBounds 确保阴影正确
滑入动画: 0.35s ease-out 展开，0.25s ease-in 收起
进度条: 自定义 NSView + Core Graphics 绘制，蓝色渐变填充，100% 变绿
鼓励浮层: 280×42px，.nonactivatingPanel，鼠标穿透
状态面板: 300×110px，多行文本，4 秒自动关闭
日历面板: 310×340px，26px 单元格，3px 间距，带 tooltip
无 Dock 图标: LSUIElement = true
无需通知权限: 全部自定义 UI
系统要求
macOS 11.0+（Big Sur 或更高）
网络连接（天气数据 + iCloud 同步）
文件说明
文件	说明
main.swift	单文件 Swift 源码（约 1560 行）
WaterReminder.app/	编译后的应用包
start.sh	启动辅助脚本
WaterReminder-v1.0.dmg	分发磁盘映像
技术栈
语言: Swift 5.7
框架: Cocoa, Foundation, UserNotifications
UI: NSPanel, NSVisualEffectView, NSBezierPath, SF Symbols
API: ipinfo.io（定位）, Open-Meteo（天气）
存储: UserDefaults + NSUbiquitousKeyValueStore（iCloud）
License
MIT

献给总是忘记喝水的开发者们。
