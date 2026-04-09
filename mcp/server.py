import json
import sys
import subprocess
import os
import time

# Base directory for adb-manager
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def run_adb_command(args):
    try:
        result = subprocess.run(["adb"] + args, capture_output=True, text=True, timeout=30)
        return {
            "stdout": result.stdout,
            "stderr": result.stderr,
            "exit_code": result.returncode
        }
    except Exception as e:
        return {"error": str(e)}

def call_tool(name, arguments):
    if name == "adb_connect":
        target = arguments.get("target", "localhost:5555")
        res = run_adb_command(["connect", target])
        return [{"type": "text", "text": f"STDOUT: {res.get('stdout')}\nSTDERR: {res.get('stderr')}"}]
    
    elif name == "adb_devices":
        res = run_adb_command(["devices", "-l"])
        return [{"type": "text", "text": res.get("stdout", "") or "No devices found."}]
    
    elif name == "adb_shell":
        command = arguments.get("command")
        res = run_adb_command(["shell", command])
        return [{"type": "text", "text": res.get("stdout", "") or res.get("stderr", "") or "Command returned no output."}]
    
    elif name == "adb_list_packages":
        res = run_adb_command(["shell", "pm", "list", "packages"])
        return [{"type": "text", "text": res.get("stdout", "") or "No packages found."}]

    elif name == "adb_list_apps":
        filter_type = arguments.get("filter", "all")
        cmd = ["shell", "pm", "list", "packages"]
        if filter_type == "user":
            cmd.append("-3")
        elif filter_type == "system":
            cmd.append("-s")
        elif filter_type == "enabled":
            cmd.append("-e")
        elif filter_type == "disabled":
            cmd.append("-d")
        
        res = run_adb_command(cmd)
        return [{"type": "text", "text": res.get("stdout", "") or f"No {filter_type} packages found."}]

    elif name == "adb_app_info":
        package = arguments.get("package")
        res = run_adb_command(["shell", "dumpsys", "package", package])
        # This output is huge, let's extract some key parts
        stdout = res.get("stdout", "")
        summary = []
        for line in stdout.splitlines():
            line = line.strip()
            if line.startswith("versionName="):
                summary.append(line)
            elif line.startswith("firstInstallTime="):
                summary.append(line)
            elif line.startswith("lastUpdateTime="):
                summary.append(line)
            elif "userId=" in line:
                summary.append(line)
        return [{"type": "text", "text": "\n".join(summary) or "Package not found or no info available."}]

    elif name == "adb_device_info":
        model = run_adb_command(["shell", "getprop", "ro.product.model"]).get("stdout", "").strip()
        version = run_adb_command(["shell", "getprop", "ro.build.version.release"]).get("stdout", "").strip()
        battery = run_adb_command(["shell", "dumpsys", "battery"]).get("stdout", "")
        level = "Unknown"
        for line in battery.splitlines():
            if "level:" in line:
                level = line.split(":")[1].strip()
        return [{"type": "text", "text": f"Model: {model}\nAndroid Version: {version}\nBattery: {level}%"}]

    elif name == "adb_screenshot":
        filename = arguments.get("filename", f"screenshot_{int(time.time())}.png")
        remote_path = f"/sdcard/{filename}"
        run_adb_command(["shell", "screencap", "-p", remote_path])
        res = run_adb_command(["pull", remote_path, filename])
        run_adb_command(["shell", "rm", remote_path])
        if res.get("exit_code") == 0:
            return [{"type": "text", "text": f"Screenshot saved to {filename}"}]
        else:
            return [{"type": "text", "text": f"Failed to pull screenshot: {res.get('stderr')}"}]

    elif name == "adb_keyevent":
        keycode = arguments.get("keycode")
        res = run_adb_command(["shell", "input", "keyevent", str(keycode)])
        return [{"type": "text", "text": f"Sent keyevent {keycode}. STDOUT: {res.get('stdout')}"}]

    elif name == "adb_push":
        local_path = arguments.get("local_path")
        remote_path = arguments.get("remote_path", "/sdcard/")
        res = run_adb_command(["push", local_path, remote_path])
        return [{"type": "text", "text": f"STDOUT: {res.get('stdout')}\nSTDERR: {res.get('stderr')}"}]

    elif name == "adb_keyevent":
        keycode = arguments.get("keycode")
        res = run_adb_command(["shell", "input", "keyevent", str(keycode)])
        return [{"type": "text", "text": f"Sent keyevent {keycode}. STDOUT: {res.get('stdout')}"}]

    elif name == "adb_pair":
        target = arguments.get("target")
        code = arguments.get("code")
        res = run_adb_command(["pair", target, code])
        return [{"type": "text", "text": f"STDOUT: {res.get('stdout')}\nSTDERR: {res.get('stderr')}"}]

    elif name == "adb_install":
        local_path = arguments.get("local_path")
        res = run_adb_command(["install", local_path])
        return [{"type": "text", "text": f"STDOUT: {res.get('stdout')}\nSTDERR: {res.get('stderr')}"}]

    elif name == "adb_auto_connect":
        # Call the bash auto_connect function via a subshell
        cmd = f"source {BASE_DIR}/lib/adb_core.sh && auto_connect"
        # We need to mock dialog for the script to run without a TTY
        res = subprocess.run(["bash", "-c", f"dialog() {{ return 0; }}; export -f dialog; {cmd}"], capture_output=True, text=True)
        if res.returncode == 0:
            return [{"type": "text", "text": "Successfully auto-connected to the device."}]
        else:
            return [{"type": "text", "text": f"Auto-connect failed. Ensure Wireless Debugging is enabled.\nSTDOUT: {res.stdout}\nSTDERR: {res.stderr}"}]

    elif name == "adb_full_auto_setup":
        # This will attempt auto_connect and then root-based setup if possible.
        # Manual pairing is NOT supported via MCP as it requires interactive TTY for dialog.
        cmd = f"source {BASE_DIR}/lib/adb_core.sh && (auto_connect || (command -v su >/dev/null && enable_adb_wireless_root 5555 && sleep 1 && adb connect localhost:5555))"
        res = subprocess.run(["bash", "-c", f"dialog() {{ return 0; }}; export -f dialog; {cmd}"], capture_output=True, text=True)
        if res.returncode == 0:
            return [{"type": "text", "text": "Automatic setup successful. Device connected."}]
        else:
            return [{"type": "text", "text": "Automatic setup failed (tried auto-connect and root method)."}]

    elif name == "adb_setup_self_connection":
        # This tool attempts the self-connection hack.
        # Since it requires manual pairing, we can't fully automate it here,
        # but we can provide the instructions and port scanning.
        return [{"type": "text", "text": "The 'Self-Connect Hack' requires interactive pairing. Please run the adb-manager TUI directly to use this feature."}]

    elif name == "adb_open_wireless_settings":
        res = subprocess.run(["bash", "-c", f"source {BASE_DIR}/lib/adb_core.sh && open_wireless_debug_settings"], capture_output=True, text=True)
        if res.returncode == 0:
            return [{"type": "text", "text": "Successfully opened Wireless Debugging settings."}]
        else:
            return [{"type": "text", "text": "Failed to open settings."}]

    elif name == "adb_open_hotspot_settings":
        res = subprocess.run(["bash", "-c", f"source {BASE_DIR}/lib/adb_core.sh && open_hotspot_settings"], capture_output=True, text=True)
        if res.returncode == 0:
            return [{"type": "text", "text": "Successfully opened Hotspot settings."}]
        else:
            return [{"type": "text", "text": "Failed to open settings."}]

    elif name == "adb_open_wifi_direct_settings":
        res = subprocess.run(["bash", "-c", f"source {BASE_DIR}/lib/adb_core.sh && open_wifi_direct_settings"], capture_output=True, text=True)
        if res.returncode == 0:
            return [{"type": "text", "text": "Successfully opened WiFi Direct settings."}]
        else:
            return [{"type": "text", "text": "Failed to open settings."}]

    elif name == "adb_pair_and_connect":
        target = arguments.get("target")
        code = arguments.get("code")
        cmd = f"source {BASE_DIR}/lib/adb_core.sh && pair_and_connect {target} {code}"
        res = subprocess.run(["bash", "-c", f"dialog() {{ return 0; }}; export -f dialog; {cmd}"], capture_output=True, text=True)
        return [{"type": "text", "text": f"STDOUT: {res.stdout}\nSTDERR: {res.stderr}"}]

    elif name == "adb_check_wifi_status":
        res = subprocess.run(["bash", "-c", f"source {BASE_DIR}/lib/adb_core.sh && check_wifi_active"], capture_output=True, text=True)
        if res.returncode == 0:
            return [{"type": "text", "text": "WiFi/Hotspot is ACTIVE."}]
        else:
            return [{"type": "text", "text": "WiFi/Hotspot is INACTIVE."}]

    return [{"type": "text", "text": f"Unknown tool: {name}"}]

def main():
    while True:
        line = sys.stdin.readline()
        if not line:
            break
        
        try:
            request = json.loads(line)
            req_id = request.get("id")
            method = request.get("method")
            params = request.get("params", {})

            if method == "initialize":
                response = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "protocolVersion": "2024-11-05",
                        "capabilities": {
                            "tools": {}
                        },
                        "serverInfo": {
                            "name": "adb-manager-mcp",
                            "version": "0.1.0"
                        }
                    }
                }
            elif method == "tools/list":
                response = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "tools": [
                            {
                                "name": "adb_connect",
                                "description": "Connect to a device via ADB Wireless Debugging",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "target": {"type": "string", "description": "IP:Port (default: localhost:5555)"}
                                    }
                                }
                            },
                            {
                                "name": "adb_devices",
                                "description": "List connected ADB devices",
                                "inputSchema": {"type": "object", "properties": {}}
                            },
                            {
                                "name": "adb_shell",
                                "description": "Run a shell command on the connected device",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "command": {"type": "string", "description": "The command to run"}
                                    },
                                    "required": ["command"]
                                }
                            },
                            {
                                "name": "adb_list_packages",
                                "description": "List all installed packages on the device",
                                "inputSchema": {"type": "object", "properties": {}}
                            },
                            {
                                "name": "adb_list_apps",
                                "description": "List installed apps with filtering",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "filter": {"type": "string", "enum": ["all", "user", "system", "enabled", "disabled"], "description": "Filter type (default: all)"}
                                    }
                                }
                            },
                            {
                                "name": "adb_app_info",
                                "description": "Get detailed info about a specific package",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "package": {"type": "string", "description": "Package name (e.g., com.android.chrome)"}
                                    },
                                    "required": ["package"]
                                }
                            },
                            {
                                "name": "adb_device_info",
                                "description": "Get detailed device information (Model, OS, Battery)",
                                "inputSchema": {"type": "object", "properties": {}}
                            },
                            {
                                "name": "adb_screenshot",
                                "description": "Take a screenshot and save it to Termux",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "filename": {"type": "string", "description": "Optional filename (default: screenshot_TIMESTAMP.png)"}
                                    }
                                }
                            },
                            {
                                "name": "adb_keyevent",
                                "description": "Send a key event to the device",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "keycode": {"type": "integer", "description": "Android keycode (e.g., 3 for Home, 4 for Back)"}
                                    },
                                    "required": ["keycode"]
                                }
                            },
                            {
                                "name": "adb_push",
                                "description": "Push a file from Termux to the device",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "local_path": {"type": "string", "description": "Local file path in Termux"},
                                        "remote_path": {"type": "string", "description": "Remote path on device (default: /sdcard/)"}
                                    },
                                    "required": ["local_path"]
                                }
                            },
                            {
                                "name": "adb_pull",
                                "description": "Pull a file from the device to Termux",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "remote_path": {"type": "string", "description": "Remote file path on device"},
                                        "local_path": {"type": "string", "description": "Local destination path in Termux (default: .)"}
                                    },
                                    "required": ["remote_path"]
                                }
                            },
                            {
                                "name": "adb_pair",
                                "description": "Pair with a device using a pairing code",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "target": {"type": "string", "description": "IP:Port for pairing (e.g., localhost:42351)"},
                                        "code": {"type": "string", "description": "6-digit pairing code"}
                                    },
                                    "required": ["target", "code"]
                                }
                            },
                            {
                                "name": "adb_install",
                                "description": "Install an APK file on the device",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "local_path": {"type": "string", "description": "Local path to APK in Termux"}
                                    },
                                    "required": ["local_path"]
                                }
                            },
                            {
                                "name": "adb_auto_connect",
                                "description": "Automatically scan and connect to local ADB Wireless Debugging port",
                                "inputSchema": {"type": "object", "properties": {}}
                            },
                            {
                                "name": "adb_full_auto_setup",
                                "description": "Attempt full automatic setup: reconnect, root-enable, or scan.",
                                "inputSchema": {"type": "object", "properties": {}}
                            },
                            {
                                "name": "adb_setup_self_connection",
                                "description": "Instructions for the 'Self-Connect Hack' to get shell access without root.",
                                "inputSchema": {"type": "object", "properties": {}}
                            },
                            {
                                "name": "adb_open_wireless_settings",
                                "description": "Open Wireless Debugging settings on the device",
                                "inputSchema": {"type": "object", "properties": {}}
                            },
                            {
                                "name": "adb_open_hotspot_settings",
                                "description": "Open Hotspot (Tethering) settings on the device to enable 'Virtual WiFi'",
                                "inputSchema": {"type": "object", "properties": {}}
                            },
                            {
                                "name": "adb_open_wifi_direct_settings",
                                "description": "Open WiFi Direct settings to help unlock Wireless Debugging toggle",
                                "inputSchema": {"type": "object", "properties": {}}
                            },
                            {
                                "name": "adb_pair_and_connect",
                                "description": "Pair with a device AND automatically scan for the connection port to finish setup.",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "target": {"type": "string", "description": "IP:Port for pairing (e.g., localhost:42351)"},
                                        "code": {"type": "string", "description": "6-digit pairing code"}
                                    },
                                    "required": ["target", "code"]
                                }
                            },
                            {
                                "name": "adb_check_wifi_status",
                                "description": "Check if WiFi or Hotspot is active (returns ACTIVE or INACTIVE)",
                                "inputSchema": {"type": "object", "properties": {}}
                            }
                        ]
                    }
                }
            elif method == "tools/call":
                name = params.get("name")
                args = params.get("arguments", {})
                content = call_tool(name, args)
                response = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "content": content
                    }
                }
            else:
                response = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "error": {"code": -32601, "message": f"Method {method} not found"}
                }

            sys.stdout.write(json.dumps(response) + "\n")
            sys.stdout.flush()

        except json.JSONDecodeError:
            continue
        except Exception as e:
            if 'req_id' in locals():
                response = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "error": {"code": -32603, "message": str(e)}
                }
                sys.stdout.write(json.dumps(response) + "\n")
                sys.stdout.flush()

if __name__ == "__main__":
    main()
