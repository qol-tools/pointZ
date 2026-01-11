#!/bin/bash

adb_autoconnect() {
    if ! command -v adb &> /dev/null; then
        return 1
    fi

    if adb devices 2>/dev/null | grep -q "device$"; then
        return 0
    fi

    local phone_ip=""

    if command -v avahi-browse &> /dev/null; then
        phone_ip=$(timeout 2 avahi-browse -t -p _adb._tcp 2>/dev/null | grep "^=" | grep IPv4 | head -n1 | cut -d';' -f8)

        if [ -z "$phone_ip" ]; then
            phone_ip=$(adb mdns services 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -n1)
        fi
    else
        phone_ip=$(adb mdns services 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -n1)
    fi

    if [ -n "$phone_ip" ]; then
        adb connect "$phone_ip:5555" >/dev/null 2>&1
        if adb devices 2>/dev/null | grep -q "device$"; then
            return 0
        fi
    fi

    local usb_device=$(adb devices 2>/dev/null | grep -v "List" | grep -E "device$|unauthorized$" | awk '{print $1}' | head -n1)

    if [ -n "$usb_device" ]; then
        adb tcpip 5555 >/dev/null 2>&1
        sleep 2

        phone_ip=$(adb shell ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)

        if [ -n "$phone_ip" ]; then
            adb connect "$phone_ip:5555" >/dev/null 2>&1
            adb devices 2>/dev/null | grep -q "device$" && return 0
        fi
    fi

    return 1
}

adb_autoconnect
