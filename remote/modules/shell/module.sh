# shellcheck shell=bash disable=SC2034
MOD_DESC="别名/函数 (shortcuts) 与 ~/.bashrc 受管片段 (conf.d 加载器)"

# 受管片段只做 PATH / RIPGREP_CONFIG_PATH，并在交互式 shell 中按文件名顺序 source
#   ~/.config/shell/conf.d/*.bash，最后 source ~/.bashrc.local。
# 其他模块通过 write_confd 往 conf.d 里放带序号的文件。序号约定:
#   00 shortcuts   10 fzf   50 starship   90 zoxide（必须最后）
mod_configure() {
  local rc=0
  mkdir -p "$CONFD" || return 1
  write_cfg "$MOD_DIR/shortcuts.bash" "$SHELL_DIR/shortcuts.bash" || rc=1
  write_confd 00-shortcuts.bash || rc=1
  set_rc_block "$MOD_DIR/bashrc.block" || rc=1
  return $rc
}
