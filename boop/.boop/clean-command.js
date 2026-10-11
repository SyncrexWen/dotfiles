/**
{
  "api": 1,
  "name": "Clean Command",
  "description": "strip code fences and $ prompts",
  "author": "kcwen",
  "icon": "broom",
  "tags": "clean,command"
}
**/
function main(state) {
  let t = state.text;
  t = t.replace(/^```\w*\n?/gm, "");
  t = t.replace(/^\s*\$\s+/gm, "");
  state.text = t.trim();
}

