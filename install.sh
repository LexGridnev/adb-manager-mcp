#!/data/data/com.termux/files/usr/bin/bash
# One-Line Installer for ADB Manager MCP v2.0 (Termux + ZeroG Ready)
set -e

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PREFIX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"

chmod +x "$REPO_DIR/adb-activate" \
         "$REPO_DIR/bin/adb-manager" \
         "$REPO_DIR/bin/smart-connect.sh" \
         "$REPO_DIR/lib/adb_core.sh" \
         "$REPO_DIR/mcp/start-mcp.sh" \
         "$REPO_DIR/mcp/config_helper.sh" \
         "$REPO_DIR/tests/test_core.sh" \
         "$REPO_DIR/tests/system_check.sh"

ln -sf "$REPO_DIR/adb-activate" "$PREFIX_BIN/adb-activate"
ln -sf "$REPO_DIR/bin/adb-manager" "$PREFIX_BIN/adb-manager"
ln -sf "$REPO_DIR/mcp/start-mcp.sh" "$PREFIX_BIN/adb-mcp"

echo "✅ ADB Manager MCP v2.0 installed!"
echo "   • CLI / One-Click Activate: adb-activate"
echo "   • Interactive TUI Manager:  adb-manager"
echo "   • Native QuickJS MCP stdio: adb-mcp"
