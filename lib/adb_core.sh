#!/bin/bash

# Core functions for ADB Manager

LAST_CONN_FILE="$HOME/.adb_last_conn"

# --- Connection Management ---

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

auto_connect() {
    local last_conn=$(get_last_conn)
    if [ -n "$last_conn" ]; then
        dialog --infobox "Attempting to reconnect to $last_conn..." 5 50
        RESULT=$(adb connect "$last_conn" 2>&1)
        if echo "$RESULT" | grep -qE "connected to|already connected"; then
            return 0
        fi
    fi

    # Try 5555 first as it's the most common
    if (timeout 0.5 adb connect "localhost:5555" | grep -qE "connected to|already connected") 2>/dev/null; then
        save_conn "localhost:5555"
        return 0
    fi

    # Scan active ports using netstat/ss if available to be faster than brute force
    local active_ports=()
    if command -v ss >/dev/null; then
        active_ports=($(ss -tlnp | grep -oP '127.0.0.1:\K\d+' | sort -u))
    elif command -v netstat >/dev/null; then
        active_ports=($(netstat -tln | grep -oP '127.0.0.1:\K\d+' | sort -u))
    fi

    for port in "${active_ports[@]}"; do
        # Skip common non-ADB ports if known, but for now just try all active locals
        dialog --infobox "Checking active local port $port..." 3 40
        if (timeout 0.5 adb connect "localhost:$port" | grep -qE "connected to|already connected") 2>/dev/null; then
            save_conn "localhost:$port"
            return 0
        fi
    done

    # Fallback to brute force scan if no active ports found or connection failed
    local scan_ports=()
    for p in {37000..44000..1000}; do
        for i in {0..10}; do
            scan_ports+=($((p + i)))
        done
    done
    
    for port in "${scan_ports[@]}"; do
        dialog --infobox "Scanning localhost:$port..." 3 40
        if (timeout 0.5 adb connect "localhost:$port" | grep -qE "connected to|already connected") 2>/dev/null; then
            save_conn "localhost:$port"
            return 0
        fi
    done
    return 1
}

# --- Package Management ---

get_package_list() {
    adb shell pm list packages | cut -d ':' -f 2
}

select_package() {
    local title="$1"
    local menu_text="$2"
    local packages_temp=$(mktemp)
    
    get_package_list > "$packages_temp"
    
    if [ -s "$packages_temp" ]; then
        local MENU_LIST=()
        while IFS= read -r line; do
            MENU_LIST+=("$line" "")
        done < "$packages_temp"
        
        local selected=$(dialog --title "$title" --menu "$menu_text" 20 60 12 "${MENU_LIST[@]}" 2>&1 >/dev/tty)
        echo "$selected"
    else
        echo ""
    fi
    rm "$packages_temp"
}

# --- Device Info ---

get_device_info() {
    local model=$(adb shell getprop ro.product.model)
    local version=$(adb shell getprop ro.build.version.release)
    local battery=$(adb shell dumpsys battery | grep level | cut -d ':' -f 2 | tr -d ' ')
    echo -e "Model: $model\nAndroid Version: $version\nBattery Level: $battery%"
}

# --- Helper Utilities ---

open_developer_options() {
    am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS > /dev/null 2>&1
    return $?
}

open_wireless_debug_settings() {
    am start -a android.settings.WIFI_ADB_SETTINGS > /dev/null 2>&1 || am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS > /dev/null 2>&1
    return $?
}

enable_adb_wireless_root() {
    local port="${1:-5555}"
    if command -v su >/dev/null; then
        su -c "setprop service.adb.tcp.port $port && stop adbd && start adbd"
        return $?
    else
        return 1
    fi
}
