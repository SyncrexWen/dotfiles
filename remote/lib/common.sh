# shellcheck shell=bash disable=SC2034
# lib/common.sh — 常量与基础函数。由 install.sh source，不要直接执行。
# SC2034：这些常量主要供模块（module.sh）使用，在本文件内看起来"未使用"。

readonly BIN="$HOME/.local/bin"
readonly CFG="$HOME/.config"
readonly SHELL_DIR="$CFG/shell"
readonly CONFD="$SHELL_DIR/conf.d"     # bashrc 受管片段会按文件名顺序 source 这里的 *.bash
readonly RC="$HOME/.bashrc"
# 下面三个标记字符串必须与旧版脚本保持一致：
# 旧版生成的文件/片段靠它们识别"是否由本脚本管理"，改了会导致旧文件被当成用户文件备份、
# bashrc 里出现两份受管片段。
readonly MARK_CFG="# managed by bootstrap_with_sudo.sh"
readonly BEGIN_MARK="# >>> dotfiles-remote >>>"
readonly END_MARK="# <<< dotfiles-remote <<<"

log()  { printf '\033[1;34m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

FAILED=()
step() {  # step <描述> <函数> [参数...]：运行一个步骤，失败只记录不中断
  local desc=$1; shift
  if [ "${DRY_RUN:-0}" = 1 ]; then
    printf '\033[1;36m[dry-run]\033[0m %s\n' "$desc"
    return 0
  fi
  log "$desc"
  "$@" || { warn "失败: $desc"; FAILED+=("$desc"); }
}
