# 🤖 AI Agent Instructions — ADB Manager MCP v2.0

`adb-manager-mcp` gives AI agents (Google Antigravity CLI `agy`, Claude Code, Gemini CLI) full autonomous control over Android hardware directly from Termux via **Wireless ADB** and **Model Context Protocol (MCP)**.

## ⚡ Recommended Workflow for AI Agents

1. **Check Environment & Connectivity (`adb_health_check` & `adb_mdns_discover`):**
   - Always call `adb_health_check` first to verify `adb` binary availability, active device connections, and mDNS service broadcast (`_adb-tls-connect._tcp`).
2. **Zero-Touch Auto-Connect (`adb_auto_connect`):**
   - If no device is connected, call `adb_auto_connect`. It automatically discovers Android 11–15 Wireless Debugging ports via `adb mdns services`, checks saved connections, and scans local sockets.
3. **Interactive Wireless Pairing (`adb_trigger_pairing_flow` -> `adb_pair_and_connect`):**
   - If the device has never been paired:
     1. Call `adb_trigger_pairing_flow` to open Android's Wireless Debugging settings for the user.
     2. Ask the user for the **Pairing IP:Port** and **6-digit pairing code** (or discover the pairing port automatically via `adb_mdns_discover`).
     3. Call `adb_pair_and_connect` with `target` and `code`.
4. **Disable Android 12–15 Phantom Process Killer (`adb_unlock_phantom_limit`):**
   - Once connected via Wireless ADB, call `adb_unlock_phantom_limit` to raise `max_phantom_processes` from `32` to `2147483647` without Root!
5. **Control Device & Apps:**
   - Use `adb_shell`, `adb_screenshot`, `adb_keyevent`, `adb_list_apps`, `adb_app_info`, `adb_install`, `adb_push`, and `adb_pull`.
