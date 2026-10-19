import * as std from "qjs:std";

console.log("=== Testing ADB Manager v2.0 QuickJS MCP Server (mcp/server.js) ===");

let passed = 0;
let failed = 0;

function verify(condition, msg) {
  if (condition) {
    console.log(`✓ PASS: ${msg}`);
    passed++;
  } else {
    console.log(`✗ FAIL: ${msg}`);
    failed++;
  }
}

const home = std.getenv("HOME") || "/data/data/com.termux/files/home";
const repoDir = `${home}/adb-manager-mcp`;
const serverJs = `${repoDir}/mcp/server.js`;

verify(std.loadFile(serverJs) !== null, "mcp/server.js exists");

function sendJsonRpc(requests) {
  const tmpIn = `/data/data/com.termux/files/usr/tmp/adb_mcp_in_${Date.now()}.jsonl`;
  const f = std.open(tmpIn, "w");
  for (const r of requests) {
    f.puts(JSON.stringify(r) + "\n");
  }
  f.close();

  const p = std.popen(`qjs -m "${serverJs}" < "${tmpIn}" 2>/dev/null`, "r");
  const out = p ? p.readAsString() : "";
  if (p) p.close();
  std.popen(`rm -f "${tmpIn}"`, "r").close();

  return out
    .trim()
    .split("\n")
    .filter(Boolean)
    .map((line) => {
      try {
        return JSON.parse(line);
      } catch (_) {
        return null;
      }
    })
    .filter(Boolean);
}

const responses = sendJsonRpc([
  { jsonrpc: "2.0", id: 1, method: "initialize", params: {} },
  { jsonrpc: "2.0", id: 2, method: "tools/list", params: {} },
  { jsonrpc: "2.0", id: 3, method: "tools/call", params: { name: "adb_get_potential_ips", arguments: {} } },
  { jsonrpc: "2.0", id: 4, method: "tools/call", params: { name: "adb_health_check", arguments: {} } }
]);

verify(responses.length === 4, `Received 4 JSON-RPC responses (got ${responses.length})`);

const initRes = responses.find((r) => r.id === 1);
verify(
  Boolean(initRes && initRes.result && initRes.result.serverInfo && initRes.result.serverInfo.name === "adb-manager-mcp"),
  "initialize returns serverInfo.name = adb-manager-mcp"
);

const listRes = responses.find((r) => r.id === 2);
const tools = listRes?.result?.tools || [];
verify(tools.length >= 23, `tools/list exposes at least 23 ADB tools (got ${tools.length})`);
verify(
  tools.some((t) => t.name === "adb_unlock_phantom_limit"),
  "tools/list includes adb_unlock_phantom_limit (Android 12-15 Phantom Killer disabler)"
);
verify(
  tools.some((t) => t.name === "adb_mdns_discover"),
  "tools/list includes adb_mdns_discover (Wireless Debugging mDNS auto-discovery)"
);

const ipsRes = responses.find((r) => r.id === 3);
const ipsText = ipsRes?.result?.content?.[0]?.text || "";
verify(ipsText.includes("127.0.0.1"), "adb_get_potential_ips returns 127.0.0.1");

const healthRes = responses.find((r) => r.id === 4);
const healthText = healthRes?.result?.content?.[0]?.text || "";
verify(healthText.includes("ADB Binary:"), "adb_health_check reports ADB Binary status");

console.log("------------------------------------------------------------");
console.log(`ADB Manager QuickJS MCP Tests: Passed: ${passed} | Failed: ${failed}`);
console.log("------------------------------------------------------------");

if (failed > 0) std.exit(1);
std.exit(0);
