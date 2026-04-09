#!/bin/bash

# Core functions for ADB Manager

LAST_CONN_FILE="$HOME/.adb_last_conn"

# Open Hotspot/Tethering settings
open_hotspot_settings() {
    am start -a android.settings.TETHER_SETTINGS || am start -a android.settings.WIFI_TETHER_SETTINGS
}

# Open WiFi Direct settings (can sometimes unlock Wireless Debugging toggle)
open_wifi_direct_settings() {
    am start -n com.android.settings/.Settings\$WifiP2pSettingsActivity > /dev/null 2>&1 || am start -a android.net.wifi.p2p.SETTINGS > /dev/null 2>&1
}

# --- Connection Management ---

# Get current WiFi IP
get_wifi_ip() {
    local ip=$(ifconfig wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    [ -z "$ip" ] && ip=$(ifconfig wlan1 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    [ -z "$ip" ] && ip=$(ifconfig p2p-wlan0-0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    # Try generic ifconfig if specific interfaces fail
    [ -z "$ip" ] && ip=$(ifconfig | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
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

# Full Automatic Wireless Debugging Setup
full_auto_setup() {
    local ip=$(get_wifi_ip)
    
    dialog --infobox "Starting Automatic Setup...\nStep 1: Checking for existing connections." 5 60
    if auto_connect; then
        return 0
    fi

    # Step 2: Try root method if available
    dialog --infobox "Step 2: Checking for root access to enable Wireless ADB." 5 60
    if command -v su >/dev/null; then
        if enable_adb_wireless_root 5555; then
            sleep 1
            if adb connect "localhost:5555" | grep -qE "connected to|already connected"; then
                save_conn "localhost:5555"
                return 0
            fi
        fi
    fi

    # Step 3: Guide user through Pairing if above failed
    dialog --title "Pairing Required" --yesno "Could not automatically connect.\n\nDo you want to use the 'Connect to Self' hack to get ADB access without root?\n(Android 11+ Wireless Debugging)" 10 60
    if [ $? -eq 0 ]; then
        setup_self_connection
        return $?
    fi

    return 1
}

# Specific flow for connecting device to itself via Wireless Debugging
setup_self_connection() {
    local ip=$(get_wifi_ip)
    
    open_wireless_debug_settings
    
    dialog --title "Wireless Debugging Hack" --msgbox "Follow these steps strictly:\n\n1. Enable 'Wireless debugging'.\n2. Tap 'Pair device with pairing code'.\n3. Note the IP:Port and 6-digit code.\n4. Come back here." 12 60
    
    local pair_info=$(dialog --title "Step 1: Pairing" --inputbox "Enter Pairing IP:Port (e.g., $ip:42351):" 8 60 "$ip:" 2>&1 >/dev/tty)
    [ -z "$pair_info" ] && return 1
    
    local pair_code=$(dialog --title "Step 2: Pairing Code" --inputbox "Enter the 6-digit pairing code:" 8 60 2>&1 >/dev/tty)
    [ -z "$pair_code" ] && return 1
    
    dialog --infobox "Pairing..." 3 30
    local pair_res=$(adb pair "$pair_info" "$pair_code" 2>&1)
    
    if echo "$pair_res" | grep -q "Successfully paired"; then
        dialog --title "Success" --msgbox "Paired! Now find the 'IP address & Port' on the main 'Wireless debugging' screen (NOT the pairing one)." 10 60
        
        local connect_port=$(dialog --title "Step 3: Connection" --inputbox "Enter the PORT only (from 'IP address & Port'):" 8 40 "" 2>&1 >/dev/tty)
        
        if [ -n "$connect_port" ]; then
            local target="localhost:$connect_port"
            dialog --infobox "Connecting to $target..." 3 40
            if adb connect "$target" | grep -qE "connected to|already connected"; then
                save_conn "$target"
                dialog --title "Hack Successful" --msgbox "Connected to self!\nYou now have 'shell' user privileges via ADB." 8 50
                return 0
            fi
        fi
        
        # If manual port failed, try auto-scanning the IP used for pairing
        local target_ip=$(echo "$pair_info" | cut -d ':' -f 1)
        dialog --infobox "Manual port failed or skipped. Scanning $target_ip for active ADB ports..." 5 60
        if auto_connect_to_ip "$target_ip"; then
            dialog --title "Hack Successful" --msgbox "Connected to self after scanning!\nYou now have 'shell' user privileges via ADB." 8 50
            return 0
        fi
    else
        dialog --title "Pairing Failed" --msgbox "Error: $pair_res" 10 60
    fi
    return 1
}

auto_connect_to_ip() {
    local target_ip="${1:-localhost}"
    
    # Try 5555
    if (timeout 1 adb connect "$target_ip:5555" | grep -qE "connected to|already connected") 2>/dev/null; then
        save_conn "$target_ip:5555"
        return 0
    fi

    # Scan ports
    local scan_ports=()
    for p in {37000..44000..1000}; do
        for i in {0..10}; do
            scan_ports+=($((p + i)))
        done
    done
    
    for port in "${scan_ports[@]}"; do
        dialog --infobox "Scanning $target_ip:$port..." 3 40
        if (timeout 0.5 adb connect "$target_ip:$port" | grep -qE "connected to|already connected") 2>/dev/null; then
            save_conn "$target_ip:$port"
            return 0
        fi
    done
    return 1
}

# Automated Pairing and Connection for non-interactive use
# $1: pair_info (IP:Port), $2: pair_code
pair_and_connect() {
    local pair_info="$1"
    local pair_code="$2"
    
    if [ -z "$pair_info" ] || [ -z "$pair_code" ]; then
        echo "Error: Missing pairing info or code."
        return 1
    fi

    echo "Pairing with $pair_info..."
    local pair_res=$(adb pair "$pair_info" "$pair_code" 2>&1)
    echo "$pair_res"

    if echo "$pair_res" | grep -q "Successfully paired"; then
        local target_ip=$(echo "$pair_info" | cut -d ':' -f 1)
        echo "Pairing successful. Scanning $target_ip for connection port..."
        
        # Give ADB a moment to register the pairing
        sleep 2
        
        if auto_connect_to_ip "$target_ip"; then
            echo "Successfully connected to $target_ip"
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

check_wifi_active() {
    local ip=$(get_wifi_ip)
    if [ "$ip" != "localhost" ] && [ -n "$ip" ]; then
        return 0
    else
        return 1
    fi
}

automate_virtual_wifi_setup() {
    local choice=$(dialog --title "Virtual WiFi Automation" --menu "Choose a trick to unlock Wireless Debugging:" 12 60 2 \
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
    
    # Once the trick is applied, jump to Wireless Debugging
    setup_self_connection
    return $?
}

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
