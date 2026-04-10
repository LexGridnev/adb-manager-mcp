# 📱 Standalone ADB Manager AI App (MCP) - User Manual

Welcome to the **Standalone ADB Manager AI App**. This project is a modern, AI-first system designed to allow AI agents to manage Android devices directly from Termux using the Model Context Protocol (MCP).

## 📑 Table of Contents
1. [Introduction](#1-introduction)
2. [AI-First Architecture](#2-ai-first-architecture)
3. [MCP Server (Primary Interface)](#3-mcp-server-primary-interface)
4. [Standalone AI App Launcher](#4-standalone-ai-app-launcher)
5. [Prerequisites & Setup](#5-prerequisites--setup)
6. [AI Agent Instructions](#6-ai-agent-instructions)
7. [Detailed Feature Guide](#7-detailed-feature-guide)
8. [Development & Testing](#8-development--testing)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Introduction
This system transforms your Termux environment into a powerful, AI-controllable ADB station. While it includes a legacy TUI for human use, it is primarily designed to be a "standalone app" powered by an LLM (like Claude) through the MCP server.

## 2. AI-First Architecture
The project is organized to prioritize AI interaction:
- **`adb-manager/start-mcp.sh`**: The main entry point for the standalone app.
- **`adb-manager/mcp/ai_instructions.md`**: Specialized knowledge base for AI models.
- **`adb-manager/mcp/server.py`**: The core MCP server handling JSON-RPC requests.
- **`adb-manager/bin/smart-connect.sh`**: Non-interactive orchestrator for agentic setup.
- **`adb-manager/lib/adb_core.sh`**: Shared logic library.

## 3. MCP Server (Primary Interface)
The MCP server is the heart of the standalone app. It exposes a rich set of tools to AI agents.

### Key Tools
- `adb_health_check`: Real-time diagnosis of the environment.
- `adb_smart_orchestrator`: Programmatic setup management.
- `adb_pair_and_connect`: Automated pairing and discovery.
- `adb_shell`, `adb_list_apps`, `adb_screenshot`, `adb_device_info`, and more.

### 4. Standalone AI App Launcher
You can launch the standalone MCP app using:
```bash
./adb-manager/start-mcp.sh
```
This script ensures the environment is ready and starts the MCP server over stdio.

## 5. Prerequisites & Setup

### Enable Wireless Debugging
To use these tools, you must enable **Wireless Debugging** on your device:
1. Open **Settings** > **About Phone**.
2. Tap **Build Number** 7 times until "Developer mode" is enabled.
3. Go to **Settings** > **System** > **Developer Options**.
4. Enable **Wireless Debugging**.
   - *Note: You must be connected to Wi-Fi or use a workaround like a portable hotspot.*

### ⚡ One-Click Activation
The fastest way to get ADB working is using the new activation script:
```bash
./adb-activate
```
This script will automatically detect the best way to connect (Previous connection -> Root -> Guided Automation).

### 📱 Legacy TUI Manager
The main script is located in `~/adb-manager/bin/adb-manager`.
Run it via the launcher:
```bash
./adb-manager-launcher
```

---

## 5. Using the Manager
The **ADB Unified Manager** is the single entry point for all operations.

### Connection Management
Under the "Connection Management" menu, you can:
- **Auto Connect:** Automatically reconnects to the last used port or scans for active Wireless Debugging ports on localhost.
- **Pair Device:** Guides you through the initial 6-digit pairing process.
- **Connect Manual:** Allows entering a specific IP and Port.
- **Open Developer Options:** Quick shortcut to your device's developer settings.

---

## 6. Detailed Feature Guide

### 📱 Device Management
- **List Devices:** See all connected devices and their status.
- **Device Info:** View model, Android version, and battery level.
- **System Tools:** Access Logcat, Top processes, and Storage/CPU info.
- **Reboot:** Restart the device directly from Termux.

### 📦 App Management
- **List Apps:** Browse all installed packages.
- **Install/Uninstall:** Manage APKs easily.
- **Start/Stop/Clear:** Control app execution and reset app data.

### 📁 File Operations
- **Push File:** Send files from Termux to your device storage (`/sdcard/`).
- **Pull File:** Get files from your device to Termux.

### 📸 Media
- **Screenshot:** Captures the screen and saves it to your Termux home folder.
- **Screen Record:** Records 10 seconds of video.

### 🎮 Interactive Control
- **Send Text:** Type text into any focused field.
- **Keys:** Simulate Home, Back, Recents, Power, Volume, and Media buttons.
- **Navigation:** Use Arrow keys and Enter to navigate.
- **Tap/Swipe/Brightness:** Precise coordinate-based input and system settings.

---

## 7. Development & Testing
Automated tests ensure the core logic remains functional.

### Running Bash Core Tests
These tests verify the core library logic (`adb_core.sh`) using `shunit2`.
```bash
bash ~/adb-manager/tests/test_core.sh
```

### Running MCP Server Tests
These tests verify the MCP server implementation (`server.py`) using Python's `unittest`.
```bash
python3 ~/adb-manager/tests/test_server.py
```

### Running System Check
Verifies environment readiness (dependencies, permissions).
```bash
bash ~/adb-manager/tests/system_check.sh
```

---

## 8. Testing Roadmap
Future testing phases include:
1. **Robustness Testing (Phase 2)**: Expand mocks to cover more Android-specific edge cases (e.g., unauthorized devices, full disk). [Partially Implemented]
2. **Integration Testing (Phase 3)**: Use a mock ADB binary to verify script behavior without a real device but with realistic multi-step interactions.
3. **E2E Manual Checklist**: Standardized verification for UI transitions in the `dialog` menus.
4. **Security Audit**: Ensure input sanitization for all shell-executed commands.

### 8.3 Smart Agent Automation (Experimental)
If you are using an AI agent with the MCP server, it can now guide you through the setup:
1. The agent will check your WiFi/Hotspot status.
2. It can open the necessary settings for you.
3. Once you provide the pairing code and IP:Port from the "Wireless Debugging" screen, the agent will handle the pairing and connection automatically using the `adb_smart_orchestrator` tool.

---

## 9. Troubleshooting

**"Device not found" or "Offline"**
- Ensure **Wireless Debugging** is still ON in Developer Options.
- Use **Auto Connect** in the Connection Management menu.
- If the port changed, you may need to re-pair or re-connect to the new port shown in Settings.

**"Dialog" command not found**
- Install it using: `pkg install dialog`

**Connection Refused**
- Ensure you are on Wi-Fi or have a local network active.
- Check if the IP/Port matches what is currently displayed in the Wireless Debugging settings.

---
*Unified ADB Management System v2.0*
