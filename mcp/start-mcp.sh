#!/data/data/com.termux/files/usr/bin/bash
# Universal Zero-Bloat MCP Launcher for ADB Manager v2.0
# Automatically prefers QuickJS (qjs -m, 3MB RAM) and falls back to Python 3 if needed.
set -e

SCRIPT_PATH="$(readlink -f "$0")"
MCP_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

if command -v qjs >/dev/null 2>&1; then
    exec qjs -m "$MCP_DIR/server.js" "$@"
elif command -v python3 >/dev/null 2>&1; then
    exec python3 "$MCP_DIR/server.py" "$@"
else
    echo "Error: Neither QuickJS (qjs) nor Python 3 found in PATH." >&2
    exit 1
fi
