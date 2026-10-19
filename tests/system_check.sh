#!/data/data/com.termux/files/usr/bin/bash
# System Check for ADB Manager v2.0 (Zero-Bloat QuickJS + Python Support)

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "🔍 Starting ADB Manager v2.0 System Check..."
echo "--------------------------------------------"

# 1. Check for adb
if command -v adb >/dev/null 2>&1; then
    echo -e "[${GREEN}OK${NC}] ADB is installed: $(adb --version | head -n 1)"
else
    echo -e "[${RED}FAIL${NC}] ADB is not installed. Run: pkg install android-tools"
fi

# 2. Check for MCP Runtime (QuickJS preferred, Python 3 fallback)
if command -v qjs >/dev/null 2>&1; then
    echo -e "[${GREEN}OK${NC}] QuickJS (Zero-Bloat MCP runtime) is installed: $(command -v qjs)"
elif command -v python3 >/dev/null 2>&1; then
    echo -e "[${GREEN}OK${NC}] Python 3 MCP runtime is installed: $(python3 --version)"
else
    echo -e "[${RED}FAIL${NC}] Neither QuickJS (qjs) nor Python 3 found. Run: pkg install quickjs-ng"
fi

# 3. Check for dialog (Optional TUI requirement)
if command -v dialog >/dev/null 2>&1; then
    echo -e "[${GREEN}OK${NC}] Dialog TUI is installed."
else
    echo -e "[${YELLOW}WARN${NC}] Dialog not installed (headless MCP & CLI work; for TUI run: pkg install dialog)."
fi

# 4. Check file permissions & core files
if [ -x "$REPO_DIR/bin/adb-manager" ] && [ -x "$REPO_DIR/mcp/start-mcp.sh" ]; then
    echo -e "[${GREEN}OK${NC}] Executables have correct permissions."
else
    echo -e "[${RED}FAIL${NC}] Executables missing +x permissions. Run: ./install.sh"
fi

if [ -f "$REPO_DIR/lib/adb_core.sh" ] && [ -f "$REPO_DIR/mcp/server.js" ]; then
    echo -e "[${GREEN}OK${NC}] Core library & QuickJS MCP server found."
else
    echo -e "[${RED}FAIL${NC}] Core library or MCP server missing!"
fi

# 5. Check ADB daemon state
ADB_DEVS=$(adb devices 2>/dev/null | sed '1d' | grep -v '^$' | wc -l)
if [ "$ADB_DEVS" -gt 0 ]; then
    echo -e "[${GREEN}OK${NC}] ADB daemon active with $ADB_DEVS connected device(s)."
else
    echo -e "[${YELLOW}INFO${NC}] ADB daemon ready (0 devices currently connected; run ./adb-activate)."
fi

echo "--------------------------------------------"
echo "Check complete."
