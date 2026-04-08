#!/bin/bash

# System Check for ADB Manager
# Verifies that the environment is correctly set up for the project to run.

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 Starting ADB Manager System Check..."
echo "---------------------------------------"

# 1. Check for adb
if command -v adb >/dev/null; then
    echo -e "[${GREEN}OK${NC}] ADB is installed: $(adb --version | head -n 1)"
else
    echo -e "[${RED}FAIL${NC}] ADB is not installed. Please run 'pkg install android-tools'."
fi

# 2. Check for dialog (CLI requirement)
if command -v dialog >/dev/null; then
    echo -e "[${GREEN}OK${NC}] Dialog is installed."
else
    echo -e "[${RED}FAIL${NC}] Dialog is not installed. CLI manager will not work. Run 'pkg install dialog'."
fi

# 3. Check for python3 (MCP requirement)
if command -v python3 >/dev/null; then
    echo -e "[${GREEN}OK${NC}] Python 3 is installed: $(python3 --version)"
else
    echo -e "[${RED}FAIL${NC}] Python 3 is not installed. MCP server will not work."
fi

# 4. Check file permissions
if [ -x "bin/adb-manager" ]; then
    echo -e "[${GREEN}OK${NC}] Main executable has correct permissions."
else
    echo -e "[${RED}FAIL${NC}] bin/adb-manager is not executable. Run 'chmod +x bin/adb-manager'."
fi

# 5. Check library existence
if [ -f "lib/adb_core.sh" ]; then
    echo -e "[${GREEN}OK${NC}] Core library found."
else
    echo -e "[${RED}FAIL${NC}] lib/adb_core.sh is missing!"
fi

# 6. Check ADB daemon state
ADB_STATE=$(adb devices | wc -l)
if [ "$ADB_STATE" -gt 1 ]; then
    echo -e "[${GREEN}OK${NC}] ADB daemon is running and responding."
else
    echo -e "[${RED}WARN${NC}] ADB daemon is running but no devices are connected."
fi

echo "---------------------------------------"
echo "Check complete."
