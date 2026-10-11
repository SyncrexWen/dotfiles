/**
{
  "api": 1,
  "name": "Redact",
  "description": "mask emails, IPs, bearer tokens and secrets",
  "author": "kcwen",
  "icon": "shield",
  "tags": "redact,mask,sanitize"
}
**/
function main(state) {
  let t = state.text;
  t = t.replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, "<EMAIL>");
  t = t.replace(/(Bearer\s+)[A-Za-z0-9._~+\/=-]+/gi, "$1<TOKEN>");
  t = t.replace(/\b((?:password|passwd|pwd|secret|token|api[_-]?key|access[_-]?key)\s*[=:]\s*)(['"]?)[^\s'"&]+\2/gi, "$1$2<SECRET>$2");
  t = t.replace(/\b\d{1,3}(?:\.\d{1,3}){3}\b/g, "<IP>");
  t = t.replace(/\b[0-9a-fA-F]{32,}\b/g, "<HEX>");
  state.text = t;
}

