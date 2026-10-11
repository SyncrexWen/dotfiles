/**
{
  "api": 1,
  "name": "JWT Decode",
  "description": "decode header and payload of a JWT",
  "author": "kcwen",
  "icon": "key",
  "tags": "jwt,decode,token"
}
**/
function b64decode(s) {
  s = s.replace(/-/g, "+").replace(/_/g, "/");
  while (s.length % 4) s += "=";
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  let bytes = [], buffer = 0, bits = 0;
  for (const c of s) {
    if (c === "=") break;
    const v = chars.indexOf(c);
    if (v < 0) throw new Error("invalid base64 char: " + c);
    buffer = (buffer << 6) | v;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      bytes.push((buffer >> bits) & 0xff);
      buffer &= (1 << bits) - 1;
    }
  }
  return decodeURIComponent(bytes.map(b => "%" + ("0" + b.toString(16)).slice(-2)).join(""));
}

function fmt(ts) {
  const d = new Date(ts * 1000);
  const p = n => ("0" + n).slice(-2);
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

function main(state) {
  try {
    const parts = state.text.trim().split(".");
    if (parts.length < 2) throw new Error("not a JWT");
    const header = JSON.parse(b64decode(parts[0]));
    const payload = JSON.parse(b64decode(parts[1]));
    let out = "// header\n" + JSON.stringify(header, null, 2) + "\n\n// payload\n" + JSON.stringify(payload, null, 2);
    const times = ["iat", "nbf", "exp"].filter(k => typeof payload[k] === "number");
    if (times.length) {
      out += "\n\n// times (local)\n" + times.map(k => `${k}: ${fmt(payload[k])}`).join("\n");
    }
    state.text = out;
  } catch (e) {
    state.postError("JWT Decode failed: " + e.message);
  }
}

