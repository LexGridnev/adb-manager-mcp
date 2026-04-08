#!/bin/bash

# Unit tests for ADB Manager Unified
# Requires shunit2

# Mocking dialog and adb for testing core logic
dialog() {
    return 0
}

adb() {
    case "$1" in
        connect)
            if [[ "$2" == "localhost:5555" ]]; then
                echo "connected to localhost:5555"
                return 0
            else
                echo "failed to connect"
                return 1
            fi
            ;;
        shell)
            if [[ "$2" == "getprop" ]]; then
                if [[ "$3" == "ro.product.model" ]]; then
                    echo "MockModel"
                elif [[ "$3" == "ro.build.version.release" ]]; then
                    echo "13"
                fi
            elif [[ "$2" == "pm" ]]; then
                echo "package:com.mock.app1"
                echo "package:com.mock.app2"
            elif [[ "$2" == "dumpsys" ]]; then
                echo "  level: 100"
            fi
            return 0
            ;;
        *) return 0 ;;
    esac
}

# Source the library
LIB_PATH="$(dirname "$(readlink -f "$0")")/../lib/adb_core.sh"
source "$LIB_PATH"

testSaveAndGetLastConn() {
    save_conn "localhost:1234"
    assertEquals "localhost:1234" "$(get_last_conn)"
}

testClearLastConn() {
    save_conn "localhost:1234"
    clear_last_conn
    assertNull "$(get_last_conn)"
}

testAutoConnectSuccess() {
    save_conn "localhost:5555"
    auto_connect
    assertTrue "Should return 0 on success" $?
}

testGetDeviceInfo() {
    local info=$(get_device_info)
    # Based on mocks: model is MockModel, battery level is 100
    assertTrue "Info should contain model" "[[ \"$info\" == *\"MockModel\"* ]]"
    assertTrue "Info should contain battery" "[[ \"$info\" == *\"100%\"* ]]"
}

testGetPackageList() {
    local list=$(get_package_list)
    local expected=$(echo -e "com.mock.app1\ncom.mock.app2")
    assertEquals "$expected" "$list"
}

# Run tests
. "$HOME/shunit2"
