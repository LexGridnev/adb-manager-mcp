# 📱 ADB Manager MCP v2.0 — Autonomous Android Control & Phantom Killer Unlocker for AI Agents

[![Version](https://img.shields.io/badge/release-v2.0.0-00e676?style=flat-square)](https://github.com/LexGridnev/adb-manager-mcp/releases)
[![MCP](https://img.shields.io/badge/MCP-25_Tools_(QuickJS_%2B_Python)-00b0ff?style=flat-square)](https://modelcontextprotocol.io)
[![ZeroG Compatible](https://img.shields.io/badge/ZeroG_(0g)-Compatible-ff9100?style=flat-square)](https://github.com/LexGridnev/zerog-termux)
[![Platform](https://img.shields.io/badge/platform-Android_11--15_%7C_Termux-a4c639?style=flat-square)](#)

**ADB Manager MCP v2.0** is an AI-first Model Context Protocol (MCP) server and Wireless ADB orchestrator that runs directly inside **Android Termux**. It enables AI agents (**Google Antigravity CLI `agy`**, **Claude Code**, **Gemini CLI**) to autonomously pair, connect, inspect, control Android hardware, and **disable Android 12–15's 32 Phantom Process Killer limit without Root**.

> 🔗 **Part of the Mobile AI Engineering Ecosystem:** Pairs natively with [**ZeroG (`0g`) — Zero-Bloat Runtime & PWA Control Center for Google Antigravity CLI**](https://github.com/LexGridnev/zerog-termux).

---

## 🔥 What's New in v2.0

1. **⚡ Zero-Bloat QuickJS MCP Engine (`mcp/server.js`):**
   - Runs in **3 MB RAM** with **3ms cold start** using `qjs -m` (QuickJS-ng) — **no Python or Node.js required**! Includes automatic fallback to `mcp/server.py` if Python 3 is preferred.
2. **👻 No-Root Phantom Process Killer Unlocker (`adb_unlock_phantom_limit`):**
   - Once connected to self via Wireless Debugging, raises Android's `max_phantom_processes` from `32` to `2147483647` via `device_config` without Root!
3. **📡 Instant mDNS Wireless ADB Discovery (`adb_mdns_discover`):**
   - Automatically detects Android 11–15 dynamic `_adb-tls-connect._tcp` and `_adb-tls-pairing._tcp` ports in `0.1s` without slow port brute-forcing.
4. **🛠️ 25 Built-in MCP Tools:**
   - Full device & app lifecycle management, screenshots, keyevents, Wireless Debugging pairing automation, Hotspot/WiFi Direct unlock tricks (for Xiaomi HyperOS / MIUI / OneUI), and health diagnostics.

---

## 🚀 Quick Start in Termux

### 1. Install Dependencies & Clone
```bash
pkg install -y android-tools quickjs-ng
git clone https://github.com/LexGridnev/adb-manager-mcp.git ~/adb-manager-mcp
cd ~/adb-manager-mcp && ./install.sh
```

### 2. One-Click Wireless ADB Activation
```bash
./adb-activate
```

### 3. Disable Android 32 Phantom Process Limit (No Root)
```bash
./adb-activate --unlock-phantom
```

### 4. Connect to Google Antigravity CLI (`agy`) or Claude
```bash
./mcp/config_helper.sh
```
Or point your MCP client directly to `/data/data/com.termux/files/home/adb-manager-mcp/mcp/start-mcp.sh`.

---

## 🧰 Available MCP Tools (25 Tools)

| Category | Tools |
| :--- | :--- |
| **Wireless Discovery & Pairing** | `adb_mdns_discover`, `adb_auto_connect`, `adb_full_auto_setup`, `adb_trigger_pairing_flow`, `adb_pair`, `adb_pair_and_connect`, `adb_connect`, `adb_smart_orchestrator` |
| **Android 12–15 Optimization** | `adb_unlock_phantom_limit`, `adb_health_check`, `adb_doctor`, `adb_get_potential_ips`, `adb_check_wifi_status` |
| **Settings & Tricks (HyperOS/OneUI)** | `adb_open_wireless_settings`, `adb_open_hotspot_settings`, `adb_open_wifi_direct_settings`, `adb_setup_self_connection` |
| **Device & App Control** | `adb_devices`, `adb_device_info`, `adb_shell`, `adb_screenshot`, `adb_keyevent`, `adb_list_packages`, `adb_list_apps`, `adb_app_info`, `adb_install`, `adb_push`, `adb_pull` |

See **[mcp/ai_instructions.md](mcp/ai_instructions.md)** and **[ADB_USER_MANUAL.md](ADB_USER_MANUAL.md)** for detailed workflows.

---

## 🧪 Testing (100% Self-Contained TDD)

```bash
./tests/test_core.sh
qjs -m ./tests/test_mcp_qjs.js
./tests/system_check.sh
```

---

## 📄 License
MIT © [LexGridnev](https://github.com/LexGridnev)
