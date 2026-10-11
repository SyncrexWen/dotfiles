/**
{
  "api": 1,
  "name": "Timestamp",
  "description": "unix timestamp <-> local datetime, per line",
  "author": "kcwen",
  "icon": "clock",
  "tags": "time,timestamp,date"
}
**/
function fmt(d) {
  const p = n => ("0" + n).slice(-2);
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

function main(state) {
  state.text = state.text.split("\n").map(line => {
    const t = line.trim();
    if (/^\d{10}$/.test(t)) return fmt(new Date(Number(t) * 1000));
    if (/^\d{13}$/.test(t)) return fmt(new Date(Number(t)));
    const d = new Date(t.replace(" ", "T"));
    if (t && !isNaN(d.getTime())) return String(Math.floor(d.getTime() / 1000));
    return line;
  }).join("\n");
}

