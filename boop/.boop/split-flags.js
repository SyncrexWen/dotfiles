/**
{
  "api": 1,
  "name": "Split Flags",
  "description": "put each flag on its own line",
  "author": "kcwen",
  "icon": "scissors",
  "tags": "split,flags"
}
**/
function main(state) {
  state.text = state.text.replace(/\s+(--?[A-Za-z])/g, " \\\n  $1");
}

