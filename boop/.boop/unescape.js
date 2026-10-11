/**
{
  "api": 1,
  "name": "Unescape",
  "description": "turn \\n \\\" \\uXXXX back into real characters",
  "author": "kcwen",
  "icon": "metamorphose",
  "tags": "unescape,json,log"
}
**/
function main(state) {
  const map = { n: "\n", r: "\r", t: "\t", '"': '"', "\\": "\\", "/": "/" };
  state.text = state.text.replace(/\\(u[0-9a-fA-F]{4}|[nrt"\\\/])/g, (m, g) => {
    if (g[0] === "u") return String.fromCharCode(parseInt(g.slice(1), 16));
    return map[g];
  });
}

