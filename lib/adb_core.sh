#!/data/data/com.termux/files/usr/bin/bash
# Core functions for ADB Manager v2.0 (Termux + ZeroG Compatible)

LAST_CONN_FILE="${LAST_CONN_FILE:-$HOME/.adb_last_conn}"

# Safe wrapper for dialog when running headless (e.g. inside MCP server)
ui_dialog() {
    if [ -t 1 ] && command -v dialog >/dev/null 2>&1; then
        dialog "$@"
    else
        return 0
    fi
}

# Open Hotspot/Tethering settings
open_hotspot_settings() {
    am start -a android.settings.TETHER_SETTINGS >/dev/null 2>&1 || \
    am start -a android.settings.WIFI_TETHER_SETTINGS >/dev/null 2>&1
}

# Open WiFi Direct settings (can unlock Wireless Debugging toggle on HyperOS/MIUI)
open_wifi_direct_settings() {
    am start -n com.android.settings/.Settings\$WifiP2pSettingsActivity >/dev/null 2>&1 || \
    am start -a android.net.wifi.p2p.SETTINGS >/dev/null 2>&1
}

# Open Developer Options
open_developer_options() {
    am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS >/dev/null 2>&1 || \
    am start -n com.android.settings/.Settings\$DevelopmentSettingsDashboardActivity >/dev/null 2>&1
}

# Open Wireless Debugging settings
open_wireless_debug_settings() {
    am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS >/dev/null 2>&1 || \
    am start -n com.android.settings/.Settings\$DevelopmentSettingsDashboardActivity >/dev/null 2>&1 || \
    am start -a android.settings.WIFI_IP_SETTINGS >/dev/null 2>&1
}

# Alias used by MCP trigger pairing flow
open_pairing_dialog() {
    open_wireless_debug_settings
}

# --- Connection Management ---

# Get current WiFi IP
get_wifi_ip() {
    local ip=""
    if command -v ifconfig >/dev/null 2>&1; then
        ip=$(ifconfig wlan0 2>/dev/null | grep -oE 'inet [0-9]+(\.[0-9]+){3}' | awk '{print $2}' | head -n 1)
        [ -z "$ip" ] && ip=$(ifconfig wlan1 2>/dev/null | grep -oE 'inet [0-9]+(\.[0-9]+){3}' | awk '{print $2}' | head -n 1)
        [ -z "$ip" ] && ip=$(ifconfig 2>/dev/null | grep -oE 'inet [0-9]+(\.[0-9]+){3}' | awk '{print $2}' | grep -v '127.0.0.1' | head -n 1)
    fi
    if [ -z "$ip" ] && command -v ip >/dev/null 2>&1; then
        ip=$(ip -4 addr show wlan0 2>/dev/null | grep -oE 'inet [0-9]+(\.[0-9]+){3}' | awk '{print $2}' | head -n 1)
    fi
    [ -z "$ip" ] && ip="localhost"
    echo "$ip"
}

get_last_conn() {
    if [ -f "$LAST_CONN_FILE" ]; then
        cat "$LAST_CONN_FILE"
    fi
}

save_conn() {
    echo "$1" > "$LAST_CONN_FILE"
}

clear_last_conn() {
    rm -f "$LAST_CONN_FILE"
}

# Fast Android 11-15 Wireless Debugging discovery via ADB mDNS
discover_adb_mdns_target() {
    local target=""
    target=$(adb mdns services 2>/dev/null | awk '/_adb-tls-connect\._tcp/{print $NF}' | head -n 1)
    echo "$target"
}

# Discover pairing service target via ADB mDNS
discover_adb_mdns_pairing() {
    local target=""
    target=$(adb mdns services 2>/dev/null | awk '/_adb-tls-pairing\._tcp/{print $NF}' | head -n 1)
    echo "$target"
}

auto_connect() {
    local last_conn
    last_conn=$(get_last_conn)
    if [ -n "$last_conn" ]; then
        ui_dialog --infobox "Attempting to reconnect to $last_conn..." 5 50
        RESULT=$(adb connect "$last_conn" 2>&1)
        if echo "$RESULT" | grep -qE "connected to|already connected"; then
            return 0
        fi
    fi

    # 1. Try mDNS auto-discovery (instant on Android 11-15 Wireless Debugging)
    local mdns_target
    mdns_target=$(discover_adb_mdns_target)
    if [ -n "$mdns_target" ]; then
        ui_dialog --infobox "Discovered Wireless ADB via mDNS: $mdns_target..." 4 50
        if adb connect "$mdns_target" 2>&1 | grep -qE "connected to|already connected"; then
            save_conn "$mdns_target"
            return 0
        fi
    fi

    # 2. Try localhost:5555 (classic TCP ADB)
    if (timeout 1 adb connect "localhost:5555" 2>&1 | grep -qE "connected to|already connected") 2>/dev/null; then
        save_conn "localhost:5555"
        return 0
    fi

    # 3. Scan active local listening sockets via ss/netstat
    local active_ports=()
    if command -v ss >/dev/null 2>&1; then
        active_ports=($(ss -tln 2>/dev/null | awk '{print $4}' | grep -oE '[0-9]+$' | awk '$1 >= 30000 && $1 <= 50000' | sort -u))
    elif command -v netstat >/dev/null 2>&1; then
        active_ports=($(netstat -tln 2>/dev/null | awk '{print $4}' | grep -oE '[0-9]+$' | awk '$1 >= 30000 && $1 <= 50000' | sort -u))
    fi

    for port in "${active_ports[@]}"; do
        ui_dialog --infobox "Checking active local port $port..." 3 40
        if (timeout 0.5 adb connect "localhost:$port" 2>&1 | grep -qE "connected to|already connected") 2>/dev/null; then
            save_conn "localhost:$port"
            return 0
        fi
    done

    return 1
}

# Unlock Android 12-15 Phantom Process Killer (32 child process ceiling) without Root via ADB shell
unlock_phantom_processes() {
    local out
    out=$(adb shell "/system/bin/device_config set_sync_disabled_for_tests persistent && /system/bin/device_config put activity_manager max_phantom_processes 2147483647 && /system/bin/settings put global settings_enable_monitor_phantom_procs false && echo 'Phantom process limit unlocked: 2147483647'" 2>&1)
    echo "$out"
    echo "$out" | grep -q "2147483647"
}

# Full Automatic Wireless Debugging Setup
full_auto_setup() {
    ui_dialog --infobox "Starting Automatic Setup...\nStep 1: Checking for existing/mDNS connections." 5 60
    if auto_connect; then
        return 0
    fi

    # Step 2: Try root method if available
    ui_dialog --infobox "Step 2: Checking for root access to enable Wireless ADB." 5 60
    if command -v su >/dev/null 2>&1; then
        if enable_adb_wireless_root 5555; then
            sleep 1
            if adb connect "localhost:5555" 2>&1 | grep -qE "connected to|already connected"; then
                save_conn "localhost:5555"
                return 0
            fi
        fi
    fi

    # Step 3: Guide user through Pairing if interactive
    if [ -t 1 ] && command -v dialog >/dev/null 2>&1; then
        dialog --title "Pairing Required" --yesno "Could not automatically connect.\n\nDo you want to use the 'Connect to Self' hack to get ADB access without root?\n(Android 11+ Wireless Debugging)" 10 60
        if [ $? -eq 0 ]; then
            setup_self_connection
            return $?
        fi
    fi

    return 1
}

# Specific flow for connecting device to itself via Wireless Debugging
setup_self_connection() {
    local ip
    ip=$(get_wifi_ip)
    open_wireless_debug_settings

    dialog --title "Wireless Debugging Hack" --msgbox "Follow these steps strictly:\n\n1. Enable 'Wireless debugging'.\n2. Tap 'Pair device with pairing code'.\n3. Note the IP:Port and 6-digit code.\n4. Come back here." 12 60

    local default_pair="$ip:"
    local mdns_pair
    mdns_pair=$(discover_adb_mdns_pairing)
    [ -n "$mdns_pair" ] && default_pair="$mdns_pair"

    local pair_info
    pair_info=$(dialog --title "Step 1: Pairing" --inputbox "Enter Pairing IP:Port (e.g., $ip:42351):" 8 60 "$default_pair" 2>&1 >/dev/tty)
    [ -z "$pair_info" ] && return 1

    local pair_code
    pair_code=$(dialog --title "Step 2: Pairing Code" --inputbox "Enter the 6-digit pairing code:" 8 60 2>&1 >/dev/tty)
    [ -z "$pair_code" ] && return 1

    dialog --infobox "Pairing..." 3 30
    local pair_res
    pair_res=$(adb pair "$pair_info" "$pair_code" 2>&1)

    if echo "$pair_res" | grep -q "Successfully paired"; then
        sleep 1
        if auto_connect; then
            dialog --title "Hack Successful" --msgbox "Connected to self via mDNS/AutoScan!\nYou now have 'shell' user privileges via ADB." 8 50
            return 0
        fi

        local connect_port
        connect_port=$(dialog --title "Step 3: Connection" --inputbox "Enter the PORT only (from main 'Wireless debugging' screen):" 8 50 "" 2>&1 >/dev/tty)
        if [ -n "$connect_port" ]; then
            local target="localhost:$connect_port"
            dialog --infobox "Connecting to $target..." 3 40
            if adb connect "$target" 2>&1 | grep -qE "connected to|already connected"; then
                save_conn "$target"
                dialog --title "Hack Successful" --msgbox "Connected to self!\nYou now have 'shell' user privileges via ADB." 8 50
                return 0
            fi
        fi
    else
        dialog --title "Pairing Failed" --msgbox "Error: $pair_res" 10 60
    fi
    return 1
}

auto_connect_to_ip() {
    local target_ip="${1:-localhost}"

    local mdns_target
    mdns_target=$(discover_adb_mdns_target)
    if [ -n "$mdns_target" ]; then
        if (timeout 1 adb connect "$mdns_target" 2>&1 | grep -qE "connected to|already connected") 2>/dev/null; then
            save_conn "$mdns_target"
            return 0
        fi
    fi

    if (timeout 1 adb connect "$target_ip:5555" 2>&1 | grep -qE "connected to|already connected") 2>/dev/null; then
        save_conn "$target_ip:5555"
        return 0
    fi

    return 1
}

# Automated Pairing and Connection for non-interactive use
pair_and_connect() {
    local pair_info="$1"
    local pair_code="$2"

    if [ -z "$pair_info" ] || [ -z "$pair_code" ]; then
        echo "Error: Missing pairing info or code."
        return 1
    fi

    echo "Pairing with $pair_info..."
    local pair_res
    pair_res=$(adb pair "$pair_info" "$pair_code" 2>&1)
    echo "$pair_res"

    if echo "$pair_res" | grep -q "Successfully paired"; then
        local target_ip
        target_ip=$(echo "$pair_info" | cut -d ':' -f 1)
        echo "Pairing successful. Discovering connection port..."
        sleep 2
        if auto_connect || auto_connect_to_ip "$target_ip"; then
            echo "Successfully connected to $(get_last_conn)"
            return 0
        else
            echo "Failed to find connection port automatically."
            return 1
        fi
    else
        return 1
    fi
}

# --- Package Management ---

get_package_list() {
    adb shell pm list packages | cut -d ':' -f 2 | tr -d '\r'
}

select_package() {
    local title="$1"
    local menu_text="$2"
    local packages_temp
    packages_temp=$(mktemp "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/adb_pkgs.XXXXXX")

    get_package_list > "$packages_temp"

    if [ -s "$packages_temp" ]; then
        local MENU_LIST=()
        while IFS= read -r line; do
            MENU_LIST+=("$line" "")
        done < "$packages_temp"

        local selected
        selected=$(dialog --title "$title" --menu "$menu_text" 20 60 12 "${MENU_LIST[@]}" 2>&1 >/dev/tty)
        echo "$selected"
    else
        echo ""
    fi
    rm -f "$packages_temp"
}

# --- Device Info ---

get_device_info() {
    local model version battery
    model=$(adb shell getprop ro.product.model | tr -d '\r')
    version=$(adb shell getprop ro.build.version.release | tr -d '\r')
    battery=$(adb shell dumpsys battery | grep level | cut -d ':' -f 2 | tr -d ' \r')
    echo -e "Model: $model\nAndroid Version: $version\nBattery Level: $battery%"
}

# --- Helper Utilities ---

check_wifi_active() {
    local ip
    ip=$(get_wifi_ip)
    if [ "$ip" != "localhost" ] && [ -n "$ip" ]; then
        return 0
    else
        return 1
    fi
}

automate_virtual_wifi_setup() {
    local choice
    choice=$(dialog --title "Virtual WiFi Automation" --menu "Choose a trick to unlock Wireless Debugging:" 12 60 2 \
        1 "Hotspot Method (Standard)" \
        2 "WiFi Direct Method (Force Unlock Trick)" 2>&1 >/dev/tty)

    [ -z "$choice" ] && return 1

    case "$choice" in
        1)
            dialog --title "Hotspot Method" --infobox "Checking WiFi/Hotspot status..." 3 40
            if ! check_wifi_active; then
                dialog --title "Hotspot Method" --yesno "WiFi is not active. I will now open the Hotspot settings.\n\nPlease:\n1. Turn ON the 'Portable hotspot'.\n2. Come back to Termux." 10 60
                if [ $? -eq 0 ]; then
                    open_hotspot_settings
                    while ! check_wifi_active; do
                        dialog --title "Waiting for Hotspot" --yesno "Still waiting for Hotspot/WiFi to activate...\n\nDid you turn it on?" 8 50
                        [ $? -ne 0 ] && return 1
                        sleep 1
                    done
                else
                    return 1
                fi
            fi
            ;;
        2)
            dialog --title "WiFi Direct Trick" --msgbox "I will open WiFi Direct settings.\n\nInstructions:\n1. Ensure WiFi is ON (even if not connected).\n2. Tap 'WiFi Direct' or similar if it doesn't open directly.\n3. This often 'tricks' the system into allowing Wireless Debugging.\n4. Come back to Termux." 12 60
            open_wifi_direct_settings
            dialog --title "WiFi Direct Trick" --yesno "Did you access WiFi Direct settings?\nProceeding to Wireless Debugging setup..." 8 50
            [ $? -ne 0 ] && return 1
            ;;
    esac

    open_wireless_debug_settings
}

enable_adb_wireless_root() {
    local port="${1:-5555}"
    if command -v su >/dev/null 2>&1; then
        su -c "setprop service.adb.tcp.port $port && stop adbd && start adbd"
        return $?
    else
        return 1
    fi
}
