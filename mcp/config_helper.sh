#!/bin/bash

# Configuration Helper for ADB MCP Server
# Generates configuration snippets for MCP clients

SERVER_PATH="/data/data/com.termux/files/home/adb-manager/mcp/server.py"
PYTHON_PATH=$(which python3)

echo "### MCP Configuration Helper ###"
echo "To connect the ADB MCP server to your client, use the following settings:"
echo ""

echo "--- Claude Desktop (config.json) ---"
cat <<EOF
{
  "mcpServers": {
    "adb-manager": {
      "command": "$PYTHON_PATH",
      "args": ["$SERVER_PATH"]
    }
  }
}
EOF

echo ""
echo "--- General Stdio Client ---"
echo "Command: $PYTHON_PATH"
echo "Arguments: $SERVER_PATH"
echo ""

echo "Note: Ensure that Termux is running and 'adb' is accessible in the environment where the server starts."
