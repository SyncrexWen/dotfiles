/**
{
  "api": 1,
  "name": "Join Command",
  "description": "join backslash-continued lines",
  "author": "kcwen",
  "icon": "link",
  "tags": "join,command"
}
**/
function main(state) {
  state.text = state.text.replace(/\s*\\\n\s*/g, " ").trim();
}

