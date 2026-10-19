#!/data/data/com.termux/files/usr/bin/bash
# Smart Orchestrator for AI-driven ADB Wireless Debugging & Phantom Killer Unlocking (v2.0)
set -e

SCRIPT_PATH="$(readlink -f "$0")"
BASE_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
source "$BASE_DIR/lib/adb_core.sh"

MODE="${1:-status}"
ARG1="${2:-}"
ARG2="${3:-}"

case "$MODE" in
    status)
        IP=$(get_wifi_ip)
        MDNS_CONN=$(discover_adb_mdns_target)
        MDNS_PAIR=$(discover_adb_mdns_pairing)
        echo "WiFi IP: $IP"
        echo "mDNS Connect Target: ${MDNS_CONN:-none}"
        echo "mDNS Pairing Target: ${MDNS_PAIR:-none}"
        echo "Last Saved Target: $(get_last_conn)"
        adb devices -l
        ;;
    prepare-hotspot)
        open_hotspot_settings
        echo "Opened Hotspot settings."
        ;;
    prepare-wifi-direct)
        open_wifi_direct_settings
        echo "Opened WiFi Direct settings."
        ;;
    open-wireless)
        open_wireless_debug_settings
        echo "Opened Wireless Debugging settings."
        ;;
    connect)
        if [ -n "$ARG1" ] && [ -n "$ARG2" ]; then
            pair_and_connect "$ARG1" "$ARG2"
        else
            auto_connect
        fi
        ;;
    unlock-phantom)
        unlock_phantom_processes
        ;;
    *)
        echo "Usage: smart-connect.sh <status|prepare-hotspot|prepare-wifi-direct|open-wireless|connect|unlock-phantom> [pair_ip:port] [pair_code]"
        exit 1
        ;;
esac
