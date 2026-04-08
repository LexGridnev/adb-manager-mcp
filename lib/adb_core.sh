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
        if echo "$RESULT" | grep -q "connected to"; then
            return 0
        fi
    fi

    # Scan common ports
    local common_ports=(5555)
    for p in {37000..44000..1000}; do
        for i in {0..10}; do
            common_ports+=($((p + i)))
        done
    done
    
    for port in "${common_ports[@]}"; do
        dialog --infobox "Scanning localhost:$port..." 3 40
        if (timeout 0.5 adb connect "localhost:$port" | grep -q "connected to") 2>/dev/null; then
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
