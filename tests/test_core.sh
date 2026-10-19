#!/data/data/com.termux/files/usr/bin/bash
# Self-contained TDD Unit Tests for ADB Manager Core & Distribution (v2.0)
set -e

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
PASS=0
FAIL=0

assertEquals() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-Expected '$expected', got '$actual'}"
    if [ "$expected" = "$actual" ]; then
        echo "✓ PASS: $msg"
        PASS=$((PASS + 1))
    else
        echo "✗ FAIL: $msg"
        FAIL=$((FAIL + 1))
    fi
}

assertNull() {
    local actual="$1"
    local msg="${2:-Expected empty value}"
    if [ -z "$actual" ]; then
        echo "✓ PASS: $msg"
        PASS=$((PASS + 1))
    else
        echo "✗ FAIL: $msg (got '$actual')"
        FAIL=$((FAIL + 1))
    fi
}

assertTrue() {
    local msg="$1"
    local cond="$2"
    if [ -z "$cond" ]; then
        cond="$msg"
        msg="Condition true"
    fi
    if [ "$cond" = "0" ] || eval "$cond"; then
        echo "✓ PASS: $msg"
        PASS=$((PASS + 1))
    else
        echo "✗ FAIL: $msg"
        FAIL=$((FAIL + 1))
    fi
}

# Isolate LAST_CONN_FILE in $TMPDIR
export LAST_CONN_FILE="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/adb_last_conn_test_$$"

# Mocking dialog and adb for testing core logic without hardware interaction
dialog() {
    return 0
}

adb() {
    case "$1" in
        mdns)
            if [ "$2" = "services" ]; then
                echo "List of discovered mdns services"
                echo "adb-TLS-connect	_adb-tls-connect._tcp.	127.0.0.1:39876"
                return 0
            fi
            ;;
        connect)
            if [ "$2" = "localhost:5555" ] || [ "$2" = "127.0.0.1:39876" ]; then
                echo "connected to $2"
                return 0
            else
                echo "failed to connect"
                return 1
            fi
            ;;
        devices)
            echo "List of devices attached"
            echo "127.0.0.1:39876	device"
            return 0
            ;;
        shell)
            shift
            if [ "$1" = "getprop" ]; then
                if [ "$2" = "ro.product.model" ]; then
                    echo "MockModel"
                elif [ "$2" = "ro.build.version.release" ]; then
                    echo "15"
                fi
            elif [ "$1" = "pm" ]; then
                echo "package:com.mock.app1"
                echo "package:com.mock.app2"
            elif [ "$1" = "dumpsys" ]; then
                echo "  level: 100"
            elif echo "$*" | grep -q "max_phantom_processes"; then
                echo "Phantom process limit unlocked: 2147483647"
                return 0
            fi
            return 0
            ;;
        *) return 0 ;;
    esac
}

echo "=== Running ADB Manager v2.0 Core & File Integrity TDD Tests ==="

LIB_PATH="$REPO_DIR/lib/adb_core.sh"
source "$LIB_PATH"
export LAST_CONN_FILE="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/adb_last_conn_test_$$"

# 1. Connection persistence tests
save_conn "localhost:1234"
assertEquals "localhost:1234" "$(get_last_conn)" "save_conn and get_last_conn persist target"

clear_last_conn
assertNull "$(get_last_conn)" "clear_last_conn removes saved connection"

# 2. Auto-connect & mDNS discovery tests
save_conn "localhost:5555"
auto_connect
assertEquals "0" "$?" "auto_connect succeeds on saved localhost:5555"

clear_last_conn
discover_mdns_port() { discover_adb_mdns_target; }
assertTrue "discover_adb_mdns_target function exists in adb_core.sh" "declare -f discover_adb_mdns_target >/dev/null"

# 3. Device info & package list tests
info=$(get_device_info)
assertTrue "get_device_info contains MockModel" "[[ \"$info\" == *\"MockModel\"* ]]"
assertTrue "get_device_info contains 100%" "[[ \"$info\" == *\"100%\"* ]]"

list=$(get_package_list)
expected=$(printf "com.mock.app1\ncom.mock.app2")
assertEquals "$expected" "$list" "get_package_list parses pm list packages"

# 4. Phantom Process Killer unlocker function test
assertTrue "unlock_phantom_processes function exists in adb_core.sh" "declare -f unlock_phantom_processes >/dev/null"
if declare -f unlock_phantom_processes >/dev/null; then
    phantom_out=$(unlock_phantom_processes)
    assertTrue "unlock_phantom_processes configures max_phantom_processes" "[[ \"$phantom_out\" == *\"2147483647\"* ]]"
fi

# 5. Missing helper functions referenced by TUI and MCP
assertTrue "open_developer_options function exists in adb_core.sh" "declare -f open_developer_options >/dev/null"
assertTrue "open_pairing_dialog function exists in adb_core.sh" "declare -f open_pairing_dialog >/dev/null"

# 6. Required distribution files & scripts exist
for req_file in \
    "adb-activate" \
    "bin/adb-manager" \
    "bin/smart-connect.sh" \
    "lib/adb_core.sh" \
    "mcp/start-mcp.sh" \
    "mcp/server.js" \
    "mcp/server.py" \
    "mcp/ai_instructions.md" \
    "mcp/config_helper.sh" \
    "install.sh"; do
    assertTrue "Required file exists: $req_file" "[ -f '$REPO_DIR/$req_file' ]"
done

# 7. Check adb-activate resolves BASE_DIR properly without broken /adb-manager suffix
assertTrue "adb-activate does not hardcode broken /adb-manager suffix" "! grep -q '/adb-manager && pwd' '$REPO_DIR/adb-activate'"

rm -f "$LAST_CONN_FILE"

echo "------------------------------------------------------------"
echo "ADB Manager Core Tests: Passed: $PASS | Failed: $FAIL"
echo "------------------------------------------------------------"
[ "$FAIL" -eq 0 ] || exit 1
