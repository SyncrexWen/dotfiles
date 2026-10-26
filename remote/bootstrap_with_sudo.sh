#!/usr/bin/env bash
# bootstrap_with_sudo.sh — 兼容 shim：保留旧入口 URL，内部转调 bootstrap.sh
#
# 旧用法继续有效:
#   bash <(curl -fsSL https://raw.githubusercontent.com/SyncrexWen/dotfiles/main/remote/bootstrap_with_sudo.sh)
# 新代码请直接用 bootstrap.sh。真正的逻辑在 install.sh 与 modules/ 里。
#
# 环境变量 DOTFILES_REF（默认 main）同时决定从哪个 ref 取 bootstrap.sh 和仓库 tarball。

set -uo pipefail

main() {
  local ref="${DOTFILES_REF:-main}"
  local self="${BASH_SOURCE[0]:-}" url script

  # 在本地检出的仓库里直接运行时，优先用同目录的 bootstrap.sh。
  # 进程替换（/dev/fd/N）不是普通文件，curl|bash 时 self 为空，都会走下面的下载分支。
  if [ -n "$self" ] && [ -f "$self" ] && [ -f "$(dirname "$self")/bootstrap.sh" ]; then
    exec bash "$(dirname "$self")/bootstrap.sh" "$@"
  fi

  url="https://raw.githubusercontent.com/SyncrexWen/dotfiles/$ref/remote/bootstrap.sh"
  # 先完整下载到变量，成功后才执行（curl 失败 / 被截断时 -f 与返回码会拦住）
  script=$(curl -fsSL --retry 3 --connect-timeout 15 "$url") || {
    printf '\033[1;31m[x]\033[0m 下载 bootstrap.sh 失败: %s\n' "$url" >&2
    exit 1
  }
  [ -n "$script" ] || { printf '\033[1;31m[x]\033[0m bootstrap.sh 内容为空\n' >&2; exit 1; }
  # bash -c 不动 stdin，sudo 密码提示照常工作
  exec bash -c "$script" bootstrap.sh "$@"
}

main "$@"
