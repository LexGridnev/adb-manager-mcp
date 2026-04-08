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
                echo "MockModel"
            elif [[ "$2" == "pm" ]]; then
                echo "package:com.mock.app"
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

testGetPackageList() {
    local list=$(get_package_list)
    assertEquals "com.mock.app" "$list"
}

# Run tests
. "$HOME/shunit2"
