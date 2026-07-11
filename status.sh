#!/bin/bash
# Check if WaterReminder is running
if pgrep -x WaterReminder > /dev/null; then
    echo "💧 WaterReminder 正在运行"
    ps aux | grep -v grep | grep WaterReminder
else
    echo "💧 WaterReminder 未运行"
fi
