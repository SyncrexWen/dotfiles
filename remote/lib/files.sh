# shellcheck shell=bash
# lib/files.sh — 写配置文件 / 维护 ~/.bashrc 受管片段。依赖 lib/common.sh。

# write_cfg <源文件> <目标路径>
# 把源文件原样复制到目标，并在第一行加上受管标记。
# 目标已存在且不带标记（不是本脚本生成的）时，先备份为 <目标>.bak.<时间戳>。
write_cfg() {
  local src=$1 dst=$2 tmp
  [ -f "$src" ] || { warn "找不到配置源文件: $src"; return 1; }
  tmp=$(mktemp)
  { echo "$MARK_CFG"; cat "$src"; } > "$tmp"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ] && ! grep -qF "$MARK_CFG" "$dst"; then
    mv "$dst" "$dst.bak.$(date +%s)"; warn "已备份原文件: $dst"
  fi
  install -m 644 "$tmp" "$dst"; rm -f "$tmp"
}

# write_confd <文件名>
# 把 $MOD_DIR/<文件名> 装到 ~/.config/shell/conf.d/<文件名>（例如 10-fzf.bash）。
# 文件名里的数字前缀决定 shell 启动时的加载顺序。
write_confd() {
  write_cfg "$MOD_DIR/$1" "$CONFD/$1"
}

# set_rc_block <源文件>
# 维护 ~/.bashrc 里的受管片段：先删旧的再追加。
set_rc_block() {
  local src=$1
  [ -f "$src" ] || { warn "找不到 bashrc 片段源文件: $src"; return 1; }
  touch "$RC"
  sed -i "\|$BEGIN_MARK|,\|$END_MARK|d" "$RC"
  { echo "$BEGIN_MARK"; cat "$src"; echo "$END_MARK"; } >> "$RC"
}
