# 📱 Standalone ADB Manager AI App (MCP)

A modern, AI-first standalone MCP server for managing Android devices via ADB directly from Termux. This project is designed to be powered by AI agents, providing a seamless bridge between your LLM and your Android hardware.

## 🚀 Quick Start

### ⚡ One-Click Activation
To activate ADB on your device instantly:
```bash
./adb-activate
```

### 📱 Legacy TUI Manager
For manual control and advanced features:
```bash
./adb-manager-launcher
```

### 🤖 Standalone MCP App
To connect an AI agent:
```bash
./adb-manager/start-mcp.sh
```

## 📂 Project Structure

- `mcp/`: **Primary Entry Point.** Contains the MCP server and AI-specific instructions.
- `bin/`: Core logic and the smart connection orchestrator.
- `lib/`: `adb_core.sh` - Shared ADB logic and connection management.
- `tests/`: Automated unit tests for core logic and server.

## ✨ AI-Powered Features

- **Agentic Setup:** AI models can automatically navigate Wireless Debugging setup, including "Virtual WiFi" and "Force Unlock" tricks.
- **Health Check:** Real-time diagnosis of the ADB environment.
- **Smart Orchestration:** Programmatic state management for multi-step tasks.
- **App & System Control:** Deep integration for app management, screenshots, and shell commands.

## 🛠 Prerequisites

- **Termux** installed on Android.
- **ADB** installed (`pkg install android-tools`).
- **Python 3** for the MCP server.

## 🤖 For AI Agents
See [AI Instructions](mcp/ai_instructions.md) for detailed tool usage and connection workflows.

## 🧪 Testing

Run the automated test suites:

- **System Check:** `bash ~/adb-manager/tests/system_check.sh`
- **Bash Core:** `bash ~/adb-manager/tests/test_core.sh`
- **MCP Server:** `python3 ~/adb-manager/tests/test_server.py`

---
*Created and maintained in Termux.*
