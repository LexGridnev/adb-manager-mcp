import * as std from "qjs:std";

const HOME = std.getenv("HOME") || "/data/data/com.termux/files/home";
const SCRIPT_PATH = scriptArgs[0] || `${HOME}/adb-manager-mcp/mcp/server.js`;
const BASE_DIR = SCRIPT_PATH.replace(/\/mcp\/server\.js$/, "");
const LIB_PATH = `${BASE_DIR}/lib/adb_core.sh`;

function shQuote(s) {
  return "'" + String(s ?? "").replace(/'/g, "'\\''") + "'";
}

function runShell(cmd) {
  const pipe = std.popen(cmd + " 2>&1", "r");
  if (!pipe) return "";
  const out = pipe.readAsString();
  pipe.close();
  return out ? out.trim() : "";
}

function textResult(text) {
  return [{ type: "text", text: String(text || "") }];
}

const TOOLS = [
  {
    name: "adb_connect",
    description: "Connect to a device via ADB Wireless Debugging",
    inputSchema: {
      type: "object",
      properties: {
        target: { type: "string", description: "IP:Port (default: localhost:5555)" }
      }
    }
  },
  {
    name: "adb_devices",
    description: "List connected ADB devices",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_shell",
    description: "Run a shell command on the connected Android device",
    inputSchema: {
      type: "object",
      properties: {
        command: { type: "string", description: "The shell command to run" }
      },
      required: ["command"]
    }
  },
  {
    name: "adb_list_packages",
    description: "List all installed packages on the device",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_list_apps",
    description: "List installed apps with filtering (all, user, system, enabled, disabled)",
    inputSchema: {
      type: "object",
      properties: {
        filter: {
          type: "string",
          enum: ["all", "user", "system", "enabled", "disabled"],
          description: "Filter type (default: all)"
        }
      }
    }
  },
  {
    name: "adb_app_info",
    description: "Get detailed info about a specific package",
    inputSchema: {
      type: "object",
      properties: {
        package: { type: "string", description: "Package name (e.g., com.android.chrome)" }
      },
      required: ["package"]
    }
  },
  {
    name: "adb_device_info",
    description: "Get detailed device information (Model, OS, Battery)",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_screenshot",
    description: "Take a screenshot and save it to Termux",
    inputSchema: {
      type: "object",
      properties: {
        filename: { type: "string", description: "Optional filename (default: screenshot_TIMESTAMP.png)" }
      }
    }
  },
  {
    name: "adb_keyevent",
    description: "Send a key event to the device",
    inputSchema: {
      type: "object",
      properties: {
        keycode: { type: "integer", description: "Android keycode (e.g., 3 for Home, 4 for Back)" }
      },
      required: ["keycode"]
    }
  },
  {
    name: "adb_push",
    description: "Push a file from Termux to the device",
    inputSchema: {
      type: "object",
      properties: {
        local_path: { type: "string", description: "Local file path in Termux" },
        remote_path: { type: "string", description: "Remote path on device (default: /sdcard/)" }
      },
      required: ["local_path"]
    }
  },
  {
    name: "adb_pull",
    description: "Pull a file from the device to Termux",
    inputSchema: {
      type: "object",
      properties: {
        remote_path: { type: "string", description: "Remote file path on device" },
        local_path: { type: "string", description: "Local destination path in Termux (default: .)" }
      },
      required: ["remote_path"]
    }
  },
  {
    name: "adb_pair",
    description: "Pair with a device using a pairing code",
    inputSchema: {
      type: "object",
      properties: {
        target: { type: "string", description: "IP:Port for pairing (e.g., localhost:42351)" },
        code: { type: "string", description: "6-digit pairing code" }
      },
      required: ["target", "code"]
    }
  },
  {
    name: "adb_install",
    description: "Install an APK file on the device",
    inputSchema: {
      type: "object",
      properties: {
        local_path: { type: "string", description: "Local path to APK in Termux" }
      },
      required: ["local_path"]
    }
  },
  {
    name: "adb_auto_connect",
    description: "Automatically discover (mDNS/socket scan) and connect to local ADB Wireless Debugging port",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_full_auto_setup",
    description: "Attempt full automatic setup: mDNS discovery, reconnect, root-enable, or socket scan",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_setup_self_connection",
    description: "Instructions for the 'Self-Connect Hack' to get shell access without root",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_open_wireless_settings",
    description: "Open Wireless Debugging settings on the device",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_trigger_pairing_flow",
    description: "Open settings and provide instructions for Wireless Debugging pairing",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_open_hotspot_settings",
    description: "Open Hotspot (Tethering) settings on the device to enable Virtual WiFi",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_open_wifi_direct_settings",
    description: "Open WiFi Direct settings to help unlock Wireless Debugging toggle",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_pair_and_connect",
    description: "Pair with a device AND automatically discover the connection port to finish setup",
    inputSchema: {
      type: "object",
      properties: {
        target: { type: "string", description: "IP:Port for pairing (e.g., localhost:42351)" },
        code: { type: "string", description: "6-digit pairing code" }
      },
      required: ["target", "code"]
    }
  },
  {
    name: "adb_check_wifi_status",
    description: "Check if WiFi or Hotspot is active (returns ACTIVE or INACTIVE)",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_smart_orchestrator",
    description: "High-level orchestrator for the Smart Agent setup flow",
    inputSchema: {
      type: "object",
      properties: {
        mode: {
          type: "string",
          enum: ["status", "prepare-hotspot", "prepare-wifi-direct", "open-wireless", "connect", "unlock-phantom"],
          description: "The setup step to perform"
        },
        arg1: { type: "string", description: "Optional: IP:Port for pairing" },
        arg2: { type: "string", description: "Optional: Pairing code" }
      },
      required: ["mode"]
    }
  },
  {
    name: "adb_health_check",
    description: "Check the health, mDNS discovery, and connectivity status of the ADB environment",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_doctor",
    description: "Fix common ADB issues (offline devices, connection hangs) and auto-reconnect",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_get_potential_ips",
    description: "Get potential IP addresses for the device (WiFi IP and 127.0.0.1)",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_mdns_discover",
    description: "Discover active Android 11-15 Wireless Debugging connect & pairing ports via ADB mDNS",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "adb_unlock_phantom_limit",
    description: "Disable Android 12-15 Phantom Process Killer (32 child process ceiling) without Root via Wireless ADB",
    inputSchema: { type: "object", properties: {} }
  }
];

function callTool(name, args) {
  args = args || {};
  switch (name) {
    case "adb_connect": {
      const target = args.target || "localhost:5555";
      return textResult(runShell(`adb connect ${shQuote(target)}`));
    }
    case "adb_devices":
      return textResult(runShell("adb devices -l") || "No devices found.");
    case "adb_shell":
      return textResult(runShell(`adb shell ${shQuote(args.command || "echo ok")}`) || "Command returned no output.");
    case "adb_list_packages":
      return textResult(runShell("adb shell pm list packages") || "No packages found.");
    case "adb_list_apps": {
      const f = args.filter || "all";
      let flag = "";
      if (f === "user") flag = "-3";
      else if (f === "system") flag = "-s";
      else if (f === "enabled") flag = "-e";
      else if (f === "disabled") flag = "-d";
      return textResult(runShell(`adb shell pm list packages ${flag}`) || `No ${f} packages found.`);
    }
    case "adb_app_info": {
      const pkg = args.package || "";
      const out = runShell(`adb shell dumpsys package ${shQuote(pkg)} | grep -E 'versionName=|firstInstallTime=|lastUpdateTime=|userId=' | head -n 20`);
      return textResult(out || "Package not found or no info available.");
    }
    case "adb_device_info":
      return textResult(runShell(`bash -c 'source ${shQuote(LIB_PATH)} && get_device_info'`));
    case "adb_screenshot": {
      const filename = args.filename || `screenshot_${Math.floor(Date.now() / 1000)}.png`;
      const remote = `/sdcard/${filename.split("/").pop()}`;
      const out = runShell(`adb shell screencap -p ${shQuote(remote)} && adb pull ${shQuote(remote)} ${shQuote(filename)} && adb shell rm -f ${shQuote(remote)}`);
      return textResult(`Screenshot saved to ${filename}\n${out}`);
    }
    case "adb_keyevent":
      return textResult(runShell(`adb shell input keyevent ${shQuote(args.keycode ?? 3)}`));
    case "adb_push":
      return textResult(runShell(`adb push ${shQuote(args.local_path)} ${shQuote(args.remote_path || "/sdcard/")}`));
    case "adb_pull":
      return textResult(runShell(`adb pull ${shQuote(args.remote_path)} ${shQuote(args.local_path || ".")}`));
    case "adb_pair":
      return textResult(runShell(`adb pair ${shQuote(args.target)} ${shQuote(args.code)}`));
    case "adb_install":
      return textResult(runShell(`adb install ${shQuote(args.local_path)}`));
    case "adb_auto_connect": {
      const out = runShell(`bash -c 'source ${shQuote(LIB_PATH)} && auto_connect && echo "ACTIVE_CONN=$(get_last_conn)"'`);
      return textResult(out.includes("ACTIVE_CONN=") ? `Successfully auto-connected: ${out}` : `Auto-connect failed.\n${out}`);
    }
    case "adb_full_auto_setup": {
      const out = runShell(`bash -c 'source ${shQuote(LIB_PATH)} && full_auto_setup && echo "SETUP_OK"'`);
      return textResult(out.includes("SETUP_OK") ? "Automatic setup successful. Device connected." : `Automatic setup failed.\n${out}`);
    }
    case "adb_setup_self_connection":
      return textResult("Run 'adb-activate' or use 'adb_trigger_pairing_flow' followed by 'adb_pair_and_connect' with your 6-digit Wireless Debugging code.");
    case "adb_open_wireless_settings":
      runShell(`bash -c 'source ${shQuote(LIB_PATH)} && open_wireless_debug_settings'`);
      return textResult("Opened Wireless Debugging settings.");
    case "adb_trigger_pairing_flow": {
      const mdnsPair = runShell(`bash -c 'source ${shQuote(LIB_PATH)} && open_pairing_dialog && discover_adb_mdns_pairing'`);
      return textResult(
        `Wireless Debugging settings opened.\nDiscovered mDNS Pairing Endpoint: ${mdnsPair || "tap 'Pair device with pairing code' on screen"}.\nProvide the IP:Port and 6-digit code to adb_pair_and_connect.`
      );
    }
    case "adb_open_hotspot_settings":
      runShell(`bash -c 'source ${shQuote(LIB_PATH)} && open_hotspot_settings'`);
      return textResult("Opened Hotspot settings.");
    case "adb_open_wifi_direct_settings":
      runShell(`bash -c 'source ${shQuote(LIB_PATH)} && open_wifi_direct_settings'`);
      return textResult("Opened WiFi Direct settings.");
    case "adb_pair_and_connect":
      return textResult(runShell(`bash -c 'source ${shQuote(LIB_PATH)} && pair_and_connect ${shQuote(args.target)} ${shQuote(args.code)}'`));
    case "adb_check_wifi_status": {
      const ok = runShell(`bash -c 'source ${shQuote(LIB_PATH)} && check_wifi_active && echo ACTIVE || echo INACTIVE'`);
      return textResult(`WiFi/Hotspot is ${ok}.`);
    }
    case "adb_smart_orchestrator":
      return textResult(runShell(`${shQuote(BASE_DIR + "/bin/smart-connect.sh")} ${shQuote(args.mode || "status")} ${shQuote(args.arg1 || "")} ${shQuote(args.arg2 || "")}`));
    case "adb_health_check": {
      const adbBin = runShell("command -v adb");
      const devOut = runShell("adb devices");
      const lines = devOut.split("\n").slice(1).map((l) => l.trim()).filter(Boolean);
      const ip = runShell(`bash -c 'source ${shQuote(LIB_PATH)} && get_wifi_ip'`);
      const mdns = runShell(`bash -c 'source ${shQuote(LIB_PATH)} && discover_adb_mdns_target'`);
      return textResult(
        [
          `ADB Binary: ${adbBin ? "OK (" + adbBin + ")" : "MISSING (pkg install android-tools)"}`,
          `Connected Devices: ${lines.length}`,
          `mDNS Wireless Target: ${mdns || "None broadcast"}`,
          `Network IP: ${ip || "127.0.0.1"}`
        ].join("\n")
      );
    }
    case "adb_doctor": {
      const out = runShell(`bash -c 'adb disconnect >/dev/null 2>&1; adb kill-server >/dev/null 2>&1; adb start-server >/dev/null 2>&1; source ${shQuote(LIB_PATH)} && auto_connect && echo RECONNECTED || echo MANUAL_NEEDED'`);
      return textResult(`ADB Server restarted.\nStatus: ${out}`);
    }
    case "adb_get_potential_ips": {
      const ip = runShell(`bash -c 'source ${shQuote(LIB_PATH)} && get_wifi_ip'`);
      const list = ip && ip !== "localhost" ? [ip, "127.0.0.1"] : ["127.0.0.1"];
      return textResult(`Potential IPs for pairing: ${list.join(", ")}`);
    }
    case "adb_mdns_discover": {
      const raw = runShell("adb mdns services");
      return textResult(raw || "No mDNS ADB services currently broadcast.");
    }
    case "adb_unlock_phantom_limit": {
      const out = runShell(`bash -c 'source ${shQuote(LIB_PATH)} && unlock_phantom_processes'`);
      return textResult(out || "Failed to unlock phantom process limit. Ensure ADB device is connected.");
    }
    default:
      return textResult(`Unknown tool: ${name}`);
  }
}

let line;
while ((line = std.in.getline()) !== null) {
  const trimmed = line.trim();
  if (!trimmed) continue;
  let req;
  try {
    req = JSON.parse(trimmed);
  } catch (_) {
    continue;
  }

  const id = req.id;
  const method = req.method;
  const params = req.params || {};

  if (method === "notifications/initialized") continue;

  let response;
  if (method === "initialize") {
    response = {
      jsonrpc: "2.0",
      id,
      result: {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: {
          name: "adb-manager-mcp",
          version: "2.0.0"
        }
      }
    };
  } else if (method === "tools/list") {
    response = {
      jsonrpc: "2.0",
      id,
      result: { tools: TOOLS }
    };
  } else if (method === "tools/call") {
    try {
      const content = callTool(params.name, params.arguments);
      response = {
        jsonrpc: "2.0",
        id,
        result: { content }
      };
    } catch (err) {
      response = {
        jsonrpc: "2.0",
        id,
        error: { code: -32603, message: String(err.message || err) }
      };
    }
  } else if (id !== undefined) {
    response = {
      jsonrpc: "2.0",
      id,
      error: { code: -32601, message: `Method ${method} not found` }
    };
  }

  if (response) {
    std.out.puts(JSON.stringify(response) + "\n");
    std.out.flush();
  }
}
