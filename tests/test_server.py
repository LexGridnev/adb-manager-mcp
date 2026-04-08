import unittest
import json
import sys
import os
from unittest.mock import patch, MagicMock

# Add the mcp directory to path so we can import server
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'mcp'))
import server

class TestMCPServer(unittest.TestCase):

    @patch('server.subprocess.run')
    def test_run_adb_command(self, mock_run):
        mock_run.return_value = MagicMock(stdout="success", stderr="", returncode=0)
        result = server.run_adb_command(["devices"])
        self.assertEqual(result["stdout"], "success")
        self.assertEqual(result["exit_code"], 0)

    @patch('server.run_adb_command')
    def test_call_tool_adb_devices(self, mock_adb):
        mock_adb.return_value = {"stdout": "List of devices attached\n127.0.0.1:5555\tdevice", "exit_code": 0}
        result = server.call_tool("adb_devices", {})
        self.assertIn("127.0.0.1:5555", result[0]["text"])

    @patch('server.run_adb_command')
    def test_call_tool_adb_connect(self, mock_adb):
        mock_adb.return_value = {"stdout": "connected to localhost:5555", "stderr": "", "exit_code": 0}
        result = server.call_tool("adb_connect", {"target": "localhost:5555"})
        self.assertIn("connected to localhost:5555", result[0]["text"])

    @patch('server.run_adb_command')
    def test_call_tool_adb_list_apps(self, mock_adb):
        mock_adb.return_value = {"stdout": "package:com.user.app", "exit_code": 0}
        result = server.call_tool("adb_list_apps", {"filter": "user"})
        self.assertIn("package:com.user.app", result[0]["text"])

    @patch('server.run_adb_command')
    def test_call_tool_adb_app_info(self, mock_adb):
        mock_adb.return_value = {"stdout": "versionName=1.2.3\nuserId=10123", "exit_code": 0}
        result = server.call_tool("adb_app_info", {"package": "com.test.app"})
        self.assertIn("versionName=1.2.3", result[0]["text"])

    @patch('server.run_adb_command')
    def test_call_tool_adb_shell(self, mock_adb):
        mock_adb.return_value = {"stdout": "root", "exit_code": 0}
        result = server.call_tool("adb_shell", {"command": "whoami"})
        self.assertEqual(result[0]["text"], "root")

    @patch('server.run_adb_command')
    def test_call_tool_adb_device_info(self, mock_adb):
        def side_effect(args):
            if "ro.product.model" in args:
                return {"stdout": "Pixel 6", "exit_code": 0}
            if "ro.build.version.release" in args:
                return {"stdout": "13", "exit_code": 0}
            if "battery" in args:
                return {"stdout": "  level: 85", "exit_code": 0}
            return {"stdout": "", "exit_code": 0}
        
        mock_adb.side_effect = side_effect
        result = server.call_tool("adb_device_info", {})
        self.assertIn("Model: Pixel 6", result[0]["text"])
        self.assertIn("Android Version: 13", result[0]["text"])
        self.assertIn("Battery: 85%", result[0]["text"])

    @patch('server.run_adb_command')
    def test_call_tool_adb_screenshot(self, mock_adb):
        mock_adb.return_value = {"stdout": "", "stderr": "", "exit_code": 0}
        result = server.call_tool("adb_screenshot", {"filename": "test.png"})
        self.assertIn("Screenshot saved to test.png", result[0]["text"])

    @patch('server.run_adb_command')
    def test_call_tool_adb_keyevent(self, mock_adb):
        mock_adb.return_value = {"stdout": "Success", "exit_code": 0}
        result = server.call_tool("adb_keyevent", {"keycode": 3})
        self.assertIn("Sent keyevent 3", result[0]["text"])

    @patch('server.run_adb_command')
    def test_call_tool_adb_push(self, mock_adb):
        mock_adb.return_value = {"stdout": "pushed", "stderr": "", "exit_code": 0}
        result = server.call_tool("adb_push", {"local_path": "test.txt"})
        self.assertIn("pushed", result[0]["text"])

    @patch('server.run_adb_command')
    def test_call_tool_adb_pull(self, mock_adb):
        mock_adb.return_value = {"stdout": "pulled", "stderr": "", "exit_code": 0}
        result = server.call_tool("adb_pull", {"remote_path": "/sdcard/test.txt"})
        self.assertIn("pulled", result[0]["text"])

    @patch('server.run_adb_command')
    def test_call_tool_adb_pair(self, mock_adb):
        mock_adb.return_value = {"stdout": "Successfully paired", "stderr": "", "exit_code": 0}
        result = server.call_tool("adb_pair", {"target": "localhost:1234", "code": "123456"})
        self.assertIn("Successfully paired", result[0]["text"])

    @patch('server.run_adb_command')
    def test_call_tool_adb_install(self, mock_adb):
        mock_adb.return_value = {"stdout": "Success", "stderr": "", "exit_code": 0}
        result = server.call_tool("adb_install", {"local_path": "test.apk"})
        self.assertIn("Success", result[0]["text"])

    @patch('subprocess.run')
    def test_call_tool_adb_auto_connect(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0, stdout="success", stderr="")
        result = server.call_tool("adb_auto_connect", {})
        self.assertIn("Successfully auto-connected", result[0]["text"])

    def test_unknown_tool(self):
        result = server.call_tool("non_existent", {})
        self.assertIn("Unknown tool", result[0]["text"])

    @patch('server.run_adb_command')
    def test_adb_command_failure_handling(self, mock_adb):
        # Simulate a command that fails or times out
        mock_adb.return_value = {"error": "Timeout expired"}
        # Some tools handle return code, others might just crash if result is not as expected
        # Let's see how adb_shell handles it
        result = server.call_tool("adb_shell", {"command": "ls"})
        # Current implementation: res.get("stdout", "") or res.get("stderr", "") or "Command returned no output."
        # If run_adb_command returns {"error": ...}, res.get("stdout") is None.
        self.assertIn("Command returned no output", result[0]["text"])

    @patch('server.run_adb_command')
    def test_adb_connect_refused(self, mock_adb):
        mock_adb.return_value = {"stdout": "", "stderr": "Connection refused", "exit_code": 1}
        result = server.call_tool("adb_connect", {"target": "localhost:5555"})
        self.assertIn("Connection refused", result[0]["text"])

if __name__ == '__main__':
    unittest.main()
