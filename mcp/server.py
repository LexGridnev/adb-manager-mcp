import json
import sys
import subprocess
import os

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

    elif name == "adb_device_info":
        model = run_adb_command(["shell", "getprop", "ro.product.model"]).get("stdout", "").strip()
        version = run_adb_command(["shell", "getprop", "ro.build.version.release"]).get("stdout", "").strip()
        battery = run_adb_command(["shell", "dumpsys", "battery"]).get("stdout", "")
        level = "Unknown"
        for line in battery.splitlines():
            if "level:" in line:
                level = line.split(":")[1].strip()
        return [{"type": "text", "text": f"Model: {model}\nAndroid Version: {version}\nBattery: {level}%"}]

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
                                "description": "List installed packages on the device",
                                "inputSchema": {"type": "object", "properties": {}}
                            },
                            {
                                "name": "adb_device_info",
                                "description": "Get detailed device information (Model, OS, Battery)",
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
