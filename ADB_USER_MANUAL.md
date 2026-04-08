# 📱 Termux ADB Management System - User Manual

Welcome to the **Termux ADB Unified Management System**. This project provides a cohesive and powerful suite of tools to manage ADB (Android Debug Bridge) directly from your Termux environment.

## 📑 Table of Contents
1. [Introduction](#1-introduction)
2. [Project Structure](#2-project-structure)
3. [MCP Server (Integration)](#3-mcp-server-integration)
4. [Prerequisites & Setup](#4-prerequisites--setup)
5. [Using the Manager](#5-using-the-manager)
6. [Detailed Feature Guide](#6-detailed-feature-guide)
7. [Development & Testing](#7-development--testing)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Introduction
This system allows you to control your Android device (or the device Termux is running on) using ADB without needing a computer. It provides a graphical-like interface (via `dialog`) for common tasks, automating the complex parts of wireless debugging and device management.

## 2. Project Structure
The project is organized for reliability and ease of use:
- `adb-manager/bin/`: Contains the main executable `adb-manager`.
- `adb-manager/lib/`: Contains the core logic library `adb_core.sh`.
- `adb-manager/tests/`: Contains automated unit tests.
- `adb-manager/mcp/`: Contains the MCP server implementation (`server.py`).
- `adb-manager/ADB_USER_MANUAL.md`: This manual.

## 3. MCP Server (Integration)
This project includes a built-in **Model Context Protocol (MCP)** server. This allows AI models and other MCP-compatible clients to interact with your device through this management system.

### Features
The MCP server exposes several tools:
- `adb_connect`: Connect to a device.
- `adb_devices`: List connected devices.
- `adb_shell`: Execute shell commands.
- `adb_list_packages`: List installed apps.
- `adb_device_info`: Retrieve model, OS, and battery data.

### Running the MCP Server
The server runs over standard I/O (stdio). You can start it using:
```bash
python3 ~/adb-manager/mcp/server.py
```

### Client Configuration
To connect this server to an MCP client (like Claude Desktop or IDE extensions), use the following configuration:

#### Claude Desktop
Add this to your `config.json`:
```json
{
  "mcpServers": {
    "adb-manager": {
      "command": "python3",
      "args": ["/data/data/com.termux/files/home/adb-manager/mcp/server.py"]
    }
  }
}
```

#### Automatic Helper
You can run the configuration helper to get the exact paths for your system:
```bash
~/adb-manager/mcp/config_helper.sh
```

## 4. Prerequisites & Setup

### Enable Wireless Debugging
To use these tools, you must enable **Wireless Debugging** on your device:
1. Open **Settings** > **About Phone**.
2. Tap **Build Number** 7 times until "Developer mode" is enabled.
3. Go to **Settings** > **System** > **Developer Options**.
4. Enable **Wireless Debugging**.
   - *Note: You must be connected to Wi-Fi or use a workaround like a portable hotspot.*

### Installation & Run
The main script is located in `~/adb-manager/bin/adb-manager`.
Make it executable (if not already):
```bash
chmod +x ~/adb-manager/bin/adb-manager
```
Run it:
```bash
~/adb-manager/bin/adb-manager
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
To run the tests:
```bash
bash ~/adb-manager/tests/test_core.sh
```

---

## 8. Troubleshooting

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
