#!/bin/bash

echo "=== Auto-Detecting Phone ==="

PHONE_IP=$(timeout 2 avahi-browse -t -r _adb._tcp 2>/dev/null | grep "address" | grep -oP '\d+\.\d+\.\d+\.\d+' | head -n1)

if [ -z "$PHONE_IP" ]; then
    echo "❌ Phone not found on network."
    echo "Make sure wireless debugging is ON."
    exit 1
fi

echo "✓ Found phone: $PHONE_IP"
echo ""
echo "Attempting direct connection..."
adb connect "$PHONE_IP:5555" 2>&1

if adb devices | grep "$PHONE_IP" | grep -q "device$"; then
    echo ""
    echo "✓✓✓ Connected! Run 'make client'"
    exit 0
fi

if adb devices | grep "$PHONE_IP" | grep -q "unauthorized"; then
    echo ""
    echo "⚠️  Connection shows as 'unauthorized'"
    echo ""
    echo "Check your phone screen - you should see an authorization dialog."
    echo "Tap 'Allow' or 'Always allow from this computer'"
    echo ""
    read -p "Press Enter after authorizing on phone..."

    if adb devices | grep "$PHONE_IP" | grep -q "device$"; then
        echo "✓✓✓ Connected! Run 'make client'"
        exit 0
    fi
fi

echo ""
echo "Connection requires pairing first."
echo ""
echo "IMPORTANT: Keep this script running, then:"
echo "  1. On phone: Tap 'Pair device with pairing code'"
echo "  2. Phone will show a 6-digit code"
echo ""
echo "Waiting 30 seconds for pairing broadcast..."

for i in {1..30}; do
    PAIR_INFO=$(timeout 1 avahi-browse -t -r _adb-tls-pairing._tcp 2>/dev/null | grep -A 3 "address\|port")

    if [ -n "$PAIR_INFO" ]; then
        PAIR_IP=$(echo "$PAIR_INFO" | grep "address" | head -n1 | grep -oP '\d+\.\d+\.\d+\.\d+')
        PAIR_PORT=$(echo "$PAIR_INFO" | grep "port" | head -n1 | grep -oP '\d+')

        if [ -n "$PAIR_IP" ] && [ -n "$PAIR_PORT" ]; then
            echo ""
            echo "✓ Detected pairing dialog at $PAIR_IP:$PAIR_PORT"
            read -p "Enter the 6-digit code from phone: " PAIR_CODE

            if [ -n "$PAIR_CODE" ]; then
                echo "$PAIR_CODE" | adb pair "$PAIR_IP:$PAIR_PORT" 2>&1

                if [ $? -eq 0 ]; then
                    sleep 1
                    adb connect "$PHONE_IP:5555" >/dev/null 2>&1

                    if adb devices | grep -q "device$"; then
                        echo ""
                        echo "✓✓✓ Paired and connected! Run 'make client'"
                        exit 0
                    fi
                fi
            fi
        fi
    fi

    printf "."
    sleep 1
done

echo ""
echo ""
echo "❌ Timeout. Pairing dialog not detected."
echo "Make sure you tapped 'Pair device with pairing code' on the phone."
exit 1
