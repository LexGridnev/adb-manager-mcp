#!/data/data/com.termux/files/usr/bin/bash
# Configuration Helper for ADB MCP Server v2.0 (QuickJS + Python Dual Engine)

SCRIPT_PATH="$(readlink -f "$0")"
MCP_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
LAUNCHER_PATH="$MCP_DIR/start-mcp.sh"

echo "### ADB Manager MCP v2.0 Configuration Helper ###"
echo " Engine: Native QuickJS (qjs -m, 3MB RAM) with Python 3 fallback"
echo ""
echo "--- Google Antigravity CLI (agy) / Claude Code / Gemini CLI ---"
cat <<EOF
{
  "mcpServers": {
    "adb-manager": {
      "command": "$LAUNCHER_PATH",
      "args": []
    }
  }
}
EOF
echo ""
