# 📱 Termux ADB Manager MCP

A unified project for managing Android devices via ADB directly from Termux, with a built-in Model Context Protocol (MCP) server for AI integration.

## 🚀 Quick Start

1. **Launch the CLI Manager:**
   ```bash
   ./adb-manager-launcher
   ```
   Or directly:
   ```bash
   ~/adb-manager/bin/adb-manager
   ```

2. **Start the MCP Server:**
   ```bash
   python3 ~/adb-manager/mcp/server.py
   ```

## 📂 Project Structure

- `bin/`: The main `adb-manager` CLI tool.
- `lib/`: `adb_core.sh` - Shared ADB logic and connection management.
- `mcp/`: `server.py` - MCP server implementation.
- `tests/`: Automated unit tests for core logic.
- `ADB_USER_MANUAL.md`: Detailed usage guide and setup instructions.

## ✨ Features

- **Automated Connection:** Quick scanning and reconnection to Wireless Debugging.
- **App Management:** List, install, uninstall, start, stop, and clear apps.
- **Interactive Control:** Send text, key events, simulate taps/swipes.
- **System Tools:** View logcat, top processes, device info, and more.
- **File Transfer:** Push and pull files between Termux and device via MCP or CLI.
- **AI Ready:** Built-in MCP server allows AI models (like Claude) to control your device.

## 🛠 Prerequisites

- **Termux** installed on Android.
- **ADB** installed (`pkg install android-tools`).
- **Dialog** installed (`pkg install dialog`).
- **Python 3** for the MCP server.

## 🧪 Testing

Run the automated test suites:

- **System Check:** `bash ~/adb-manager/tests/system_check.sh`
- **Bash Core:** `bash ~/adb-manager/tests/test_core.sh`
- **MCP Server:** `python3 ~/adb-manager/tests/test_server.py`

---
*Created and maintained in Termux.*
